from geokernel import FType, Point, Face, Shell, Vector3


def triangulate_face_ear_clipping(face: Face) -> List[Face]:
    """Ear clipping triangulation for simple (possibly concave) polygons.
    Projects to local 2D coordinates, finds ear vertices (convex with no
    other polygon vertices inside), clips them one by one until 3 remain.

    Algorithm:
      1. Project all vertices to a local 2D plane using face normal.
      2. Determine polygon winding direction (signed area).
      3. For each vertex, check if it is convex and if its triangle ear
         contains no other polygon vertices.
      4. Clip the ear: emit triangle, remove vertex, repeat.
    """
    var result = List[Face]()
    var n = face.num_vertices()
    if n < 3:
        return result^
    if n == 3:
        result.append(face)
        return result^

    # Build local 2D coordinate system from face normal
    var normal = face.normal()
    var ref_v = Vector3(0.0, 0.0, 1.0)
    if abs(normal.dot(ref_v)) > 0.9:
        ref_v = Vector3(1.0, 0.0, 0.0)
    var u_axis = normal.cross(ref_v).normalize()
    var v_axis = normal.cross(u_axis).normalize()
    var origin = face.get_vertex(0)

    # Project vertices to 2D
    var px = List[FType]()
    var py = List[FType]()
    for i in range(n):
        var d = Vector3.from_points(origin, face.get_vertex(i))
        px.append(d.dot(u_axis))
        py.append(d.dot(v_axis))

    # Determine signed area (positive = CCW in 2D projection)
    var signed_area: FType = 0.0
    for i in range(n):
        var j = (i + 1) % n
        signed_area += px[i] * py[j] - px[j] * py[i]

    # Working index list
    var indices = List[Int]()
    for i in range(n):
        indices.append(i)

    var max_iters = n * n + 10
    var iter_count = 0

    while len(indices) > 3 and iter_count < max_iters:
        iter_count += 1
        var m = len(indices)
        var ear_found = False
        var ear_pos = -1

        for i in range(m):
            var prev = indices[(i - 1 + m) % m]
            var curr = indices[i]
            var next = indices[(i + 1) % m]

            var ax = px[prev]; var ay = py[prev]
            var bx = px[curr]; var by = py[curr]
            var cx = px[next]; var cy = py[next]

            # Cross product z-component: (b-a) x (c-a)
            # Positive = CCW turn, meaning convex vertex in CCW polygon
            var cross = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

            if signed_area >= 0.0:
                if cross <= 0.0:
                    continue  # reflex vertex in CCW polygon
            else:
                if cross >= 0.0:
                    continue  # reflex vertex in CW polygon

            # Check no other polygon vertex is strictly inside this ear triangle
            var any_inside = False
            for j in range(m):
                var vidx = indices[j]
                if vidx == prev or vidx == curr or vidx == next:
                    continue
                var qx = px[vidx]; var qy = py[vidx]
                # Barycentric sign test
                var d1 = (qx - ax) * (by - ay) - (qy - ay) * (bx - ax)
                var d2 = (qx - bx) * (cy - by) - (qy - by) * (cx - bx)
                var d3 = (qx - cx) * (ay - cy) - (qy - cy) * (ax - cx)
                var has_neg = (d1 < -1e-12) or (d2 < -1e-12) or (d3 < -1e-12)
                var has_pos = (d1 > 1e-12) or (d2 > 1e-12) or (d3 > 1e-12)
                if not (has_neg and has_pos):
                    any_inside = True
                    break

            if not any_inside:
                ear_pos = i
                ear_found = True
                break

        if not ear_found:
            # Fallback: force-clip the first available vertex to avoid infinite loop
            ear_pos = 0
            ear_found = True

        if ear_found and ear_pos >= 0:
            var m2 = len(indices)
            var prev_idx = indices[(ear_pos - 1 + m2) % m2]
            var curr_idx = indices[ear_pos]
            var next_idx = indices[(ear_pos + 1) % m2]

            var tri_pts = List[Point]()
            tri_pts.append(face.get_vertex(prev_idx))
            tri_pts.append(face.get_vertex(curr_idx))
            tri_pts.append(face.get_vertex(next_idx))
            result.append(Face(tri_pts))

            # Remove ear vertex from working list
            var new_indices = List[Int]()
            for k in range(m2):
                if k != ear_pos:
                    new_indices.append(indices[k])
            indices = new_indices^

    # Emit the final triangle
    if len(indices) == 3:
        var tri_pts = List[Point]()
        tri_pts.append(face.get_vertex(indices[0]))
        tri_pts.append(face.get_vertex(indices[1]))
        tri_pts.append(face.get_vertex(indices[2]))
        result.append(Face(tri_pts))

    return result^


def triangulate_shell(shell: Shell) -> Shell:
    """Triangulate all faces of a shell using ear-clipping.
    Returns a new shell made entirely of triangular faces."""
    var all_faces = List[Face]()
    for i in range(len(shell.faces)):
        var tris = triangulate_face_ear_clipping(shell.faces[i])
        for j in range(len(tris)):
            all_faces.append(tris[j])
    return Shell(all_faces)


struct Triangulation:
    @staticmethod
    def triangulate(points: List[Point]) -> List[List[Int]]:
        """Fan triangulation for convex polygons.
        Returns list of triangles as index triples."""
        var result = List[List[Int]]()
        var n = len(points)
        if n < 3:
            return result.copy()
        for i in range(1, n - 1):
            var tri = List[Int]()
            tri.append(0)
            tri.append(i)
            tri.append(i + 1)
            result.append(tri.copy())
        return result.copy()

    @staticmethod
    def triangulate_to_points(points: List[Point]) -> List[List[Point]]:
        """Returns triangles as point lists."""
        var result = List[List[Point]]()
        var n = len(points)
        if n < 3:
            return result.copy()
        for i in range(1, n - 1):
            var tri = List[Point]()
            tri.append(points[0])
            tri.append(points[i])
            tri.append(points[i + 1])
            result.append(tri.copy())
        return result.copy()

    @staticmethod
    def triangulate_face(face: Face) -> List[Face]:
        """Triangulate a face using ear-clipping (handles concave polygons).
        Falls back to fan triangulation for triangles."""
        return triangulate_face_ear_clipping(face)

    @staticmethod
    def triangulate_face_fan(face: Face) -> List[Face]:
        """Fan triangulation from first vertex (convex polygons only)."""
        var result = List[Face]()
        var n = face.num_vertices()
        if n < 3:
            return result^
        for i in range(1, n - 1):
            var tri_pts = List[Point]()
            tri_pts.append(face.get_vertex(0))
            tri_pts.append(face.get_vertex(i))
            tri_pts.append(face.get_vertex(i + 1))
            result.append(Face(tri_pts))
        return result^
