from geokernel import FType, Point, Face, Shell, Vector3


# ---------------------------------------------------------------------------
# Shape Healing utilities
# ---------------------------------------------------------------------------


fn _dist_sq(a: Point, b: Point) -> FType:
    var dx = a.x - b.x
    var dy = a.y - b.y
    var dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz


# ---------------------------------------------------------------------------
# 1. Merge coincident vertices
# ---------------------------------------------------------------------------

fn merge_coincident_vertices(shell: Shell, tol: Float64 = 1e-6) -> Shell:
    """Find all vertices in the shell that are within *tol* distance of each
    other and unify them to a single canonical position.

    Algorithm
    ---------
    1. Collect every unique vertex from all faces.
    2. Union-Find: group vertices within tol distance into clusters.
    3. For each cluster, pick the average position as the canonical point.
    4. Rebuild each face by remapping its vertices through the canonical map.
    """
    # --- collect all unique vertices ---
    var all_pts = List[Point]()
    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        for vi in range(face.num_vertices()):
            var p = face.get_vertex(vi)
            # Only add if not a duplicate of an already-collected vertex
            var found = False
            for k in range(len(all_pts)):
                if _dist_sq(p, all_pts[k]) < tol * tol:
                    found = True
                    break
            if not found:
                all_pts.append(p)

    var n = len(all_pts)

    # --- Union-Find ---
    var parent = List[Int]()
    for i in range(n):
        parent.append(i)

    fn find(mut parent: List[Int], i: Int) -> Int:
        var root = i
        while parent[root] != root:
            root = parent[root]
        # Path compression
        var cur = i
        while cur != root:
            var nxt = parent[cur]
            parent[cur] = root
            cur = nxt
        return root

    var tol_sq = tol * tol
    for i in range(n):
        for j in range(i + 1, n):
            if _dist_sq(all_pts[i], all_pts[j]) <= tol_sq:
                var ri = find(parent, i)
                var rj = find(parent, j)
                if ri != rj:
                    parent[ri] = rj

    # --- Compute canonical positions (average within each cluster) ---
    # Map from root → List[point_index]
    var cluster_sums_x = List[FType]()
    var cluster_sums_y = List[FType]()
    var cluster_sums_z = List[FType]()
    var cluster_counts  = List[Int]()
    var cluster_roots   = List[Int]()

    # First pass: find all unique roots
    for i in range(n):
        var root = find(parent, i)
        var root_found = False
        for k in range(len(cluster_roots)):
            if cluster_roots[k] == root:
                root_found = True
                break
        if not root_found:
            cluster_roots.append(root)
            cluster_sums_x.append(0.0)
            cluster_sums_y.append(0.0)
            cluster_sums_z.append(0.0)
            cluster_counts.append(0)

    # Accumulate sums
    for i in range(n):
        var root = find(parent, i)
        for k in range(len(cluster_roots)):
            if cluster_roots[k] == root:
                cluster_sums_x[k] += all_pts[i].x
                cluster_sums_y[k] += all_pts[i].y
                cluster_sums_z[k] += all_pts[i].z
                cluster_counts[k] += 1
                break

    # Build canonical_point[i] = average position for the cluster containing vertex i
    var canonical = List[Point]()
    for _ in range(n):
        canonical.append(Point(0.0, 0.0, 0.0))

    for i in range(n):
        var root = find(parent, i)
        for k in range(len(cluster_roots)):
            if cluster_roots[k] == root:
                var cnt = FType(cluster_counts[k])
                canonical[i] = Point(
                    cluster_sums_x[k] / cnt,
                    cluster_sums_y[k] / cnt,
                    cluster_sums_z[k] / cnt,
                )
                break

    # --- Rebuild faces ---
    var new_faces = List[Face]()
    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        var new_pts = List[Point]()
        for vi in range(face.num_vertices()):
            var p = face.get_vertex(vi)
            # Find canonical position for this vertex
            var best_idx = 0
            var best_d   = _dist_sq(p, all_pts[0])
            for k in range(1, len(all_pts)):
                var d = _dist_sq(p, all_pts[k])
                if d < best_d:
                    best_d = d
                    best_idx = k
            new_pts.append(canonical[best_idx])
        new_faces.append(Face(new_pts))

    return Shell(new_faces)


# ---------------------------------------------------------------------------
# 2. Remove degenerate edges
# ---------------------------------------------------------------------------

fn remove_degenerate_edges(shell: Shell, tol: Float64 = 1e-9) -> Shell:
    """Remove faces that have any edge shorter than *tol* (degenerate faces).

    For a simple repair pass, a face with a zero-length edge is collapsed; the
    face is discarded rather than partially fixed.  More sophisticated handling
    (collapsing the edge while keeping the polygon) requires mesh connectivity
    reconstruction and is beyond this scope.
    """
    var tol_sq = tol * tol
    var new_faces = List[Face]()
    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        var degenerate = False
        for ei in range(face.num_edges()):
            var edge = face.get_edge(ei)
            var dx = edge.p2.x - edge.p1.x
            var dy = edge.p2.y - edge.p1.y
            var dz = edge.p2.z - edge.p1.z
            var len_sq = dx * dx + dy * dy + dz * dz
            if len_sq < tol_sq:
                degenerate = True
                break
        if not degenerate:
            new_faces.append(face)
    return Shell(new_faces)


# ---------------------------------------------------------------------------
# 3. Fix face normals
# ---------------------------------------------------------------------------

fn fix_face_normals(shell: Shell) -> Shell:
    """Ensure all face normals point consistently outward for a closed shell.

    Algorithm
    ---------
    1. Compute the shell's approximate centroid (average of all face centroids).
    2. For each face, if its normal points *toward* the centroid (i.e. the dot
       product of (face_centroid - shell_centroid) with the face normal is
       negative), reverse the face winding.

    This is a simple heuristic that works well for convex or mildly convex
    shells.  For strongly concave or self-intersecting shells a full BVH-based
    ray casting approach would be needed.
    """
    var num_faces = len(shell.faces)
    if num_faces == 0:
        return shell

    # Compute shell centroid
    var cx: FType = 0.0
    var cy: FType = 0.0
    var cz: FType = 0.0
    for fi in range(num_faces):
        var fc = shell.faces[fi].centroid()
        cx += fc.x
        cy += fc.y
        cz += fc.z
    var shell_centroid = Point(cx / FType(num_faces), cy / FType(num_faces), cz / FType(num_faces))

    var new_faces = List[Face]()
    for fi in range(num_faces):
        var face = shell.faces[fi]
        var fc = face.centroid()
        var outward = Vector3(fc.x - shell_centroid.x, fc.y - shell_centroid.y, fc.z - shell_centroid.z)
        var n = face.normal()
        if outward.dot(n) < 0.0:
            # Normal points inward — reverse winding
            new_faces.append(face.reverse())
        else:
            new_faces.append(face)

    return Shell(new_faces)
