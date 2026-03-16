from geokernel import FType, Point, Vector3, Line, Face, Shell, Wire, AABB, BVH
from math import sqrt


fn ray_shell_intersection(origin: Point, direction: Vector3, shell: Shell) -> List[Point]:
    """Find all points where a ray intersects a shell's faces.
    Uses BVH acceleration: first finds candidate faces via AABB query,
    then performs exact ray-triangle intersection tests.

    Algorithm:
      1. Build an AABB for each shell face.
      2. Build a BVH over those AABBs.
      3. Use ray_query to get candidate face indices.
      4. For each candidate, do ray-face intersection (plane + point-in-polygon).
    """
    var result = List[Point]()
    var n_faces = len(shell.faces)
    if n_faces == 0:
        return result^

    # Build per-face AABBs
    var face_aabbs = List[AABB]()
    for i in range(n_faces):
        var face = shell.faces[i]
        var pts = List[Point]()
        for j in range(face.num_vertices()):
            pts.append(face.get_vertex(j))
        face_aabbs.append(AABB(pts))

    # Build BVH
    var bvh = BVH(face_aabbs)

    # Get candidate faces via BVH ray query
    var candidates = bvh.ray_query(origin, direction)

    # Exact ray-face intersection for candidates
    var dir_len_sq = direction.x * direction.x + direction.y * direction.y + direction.z * direction.z
    if dir_len_sq < 1e-24:
        return result^

    for k in range(len(candidates)):
        var fi = candidates[k]
        var face = shell.faces[fi]
        var n = face.normal()
        var denom = n.dot(direction)

        if abs(denom) < 1e-12:
            continue  # ray parallel to face plane

        var diff = Vector3.from_points(origin, face.points[0])
        var t = n.dot(diff) / denom

        if t < 0.0:
            continue  # intersection behind ray origin

        var hit = Point(
            origin.x + direction.x * t,
            origin.y + direction.y * t,
            origin.z + direction.z * t,
        )

        if face.contains_point_2d(hit):
            result.append(hit)

    return result^


fn segment_segment_intersection(p1: Point, p2: Point, p3: Point, p4: Point) -> Optional[Point]:
    """3D segment-segment closest point / intersection.
    Returns the intersection Point if the two segments intersect (or nearly
    intersect within tolerance), otherwise returns None.

    Algorithm:
      Parametric minimization of ||P(s)-Q(t)||² over s,t ∈ [0,1].
      P(s) = p1 + s*(p2-p1), Q(t) = p3 + t*(p4-p3).
      Solve the 2×2 linear system for the unconstrained minimum,
      clamp to [0,1], and check if the resulting closest points coincide
      within a small tolerance.
    """
    var d1 = Vector3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z)
    var d2 = Vector3(p4.x - p3.x, p4.y - p3.y, p4.z - p3.z)
    var r  = Vector3(p1.x - p3.x, p1.y - p3.y, p1.z - p3.z)

    var a = d1.dot(d1)
    var e = d2.dot(d2)
    var f = d2.dot(r)

    var s: FType
    var t: FType

    if a <= 1e-15 and e <= 1e-15:
        # Both degenerate to points
        s = 0.0
        t = 0.0
    elif a <= 1e-15:
        s = 0.0
        t = f / e
        t = max(0.0, min(1.0, t))
    else:
        var c = d1.dot(r)
        if e <= 1e-15:
            t = 0.0
            s = -c / a
            s = max(0.0, min(1.0, s))
        else:
            var b = d1.dot(d2)
            var denom = a * e - b * b
            if denom > 1e-15:
                s = (b * f - c * e) / denom
                s = max(0.0, min(1.0, s))
            else:
                s = 0.0  # parallel
            t = (b * s + f) / e
            if t < 0.0:
                t = 0.0
                s = -c / a
                s = max(0.0, min(1.0, s))
            elif t > 1.0:
                t = 1.0
                s = (b - c) / a
                s = max(0.0, min(1.0, s))

    var cp = Point(p1.x + d1.x * s, p1.y + d1.y * s, p1.z + d1.z * s)
    var cq = Point(p3.x + d2.x * t, p3.y + d2.y * t, p3.z + d2.z * t)

    var dx = cp.x - cq.x
    var dy = cp.y - cq.y
    var dz = cp.z - cq.z
    var dist = sqrt(dx * dx + dy * dy + dz * dz)

    if dist < 1e-9:
        # Return midpoint as the intersection
        return Optional[Point](Point(
            (cp.x + cq.x) * 0.5,
            (cp.y + cq.y) * 0.5,
            (cp.z + cq.z) * 0.5,
        ))
    return Optional[Point](None)


fn shell_shell_intersection(s1: Shell, s2: Shell) -> List[Wire]:
    """Find intersection curves between two shells.
    Iterates all face pairs between s1 and s2 and collects intersection
    segments. Segments are assembled into wires.

    This is a stub implementation: it iterates face pairs using BVH
    acceleration for coarse culling, then tests each face pair for
    edge intersections. A production implementation would use a proper
    face-face intersection kernel and curve assembly.
    """
    var result = List[Wire]()
    var n1 = len(s1.faces)
    var n2 = len(s2.faces)
    if n1 == 0 or n2 == 0:
        return result^

    # Build BVH for s2
    var aabbs2 = List[AABB]()
    for i in range(n2):
        var face = s2.faces[i]
        var pts = List[Point]()
        for j in range(face.num_vertices()):
            pts.append(face.get_vertex(j))
        aabbs2.append(AABB(pts))
    var bvh2 = BVH(aabbs2)

    # Collect intersection segments as point pairs
    var seg_pts = List[Point]()

    for i in range(n1):
        var f1 = s1.faces[i]

        # Compute AABB of f1 for BVH query
        var pts1 = List[Point]()
        for j in range(f1.num_vertices()):
            pts1.append(f1.get_vertex(j))
        var aabb1 = AABB(pts1)

        var candidates = bvh2.query_aabb(aabb1)

        for k in range(len(candidates)):
            var f2 = s2.faces[candidates[k]]

            # Test each edge of f1 against f2
            for ei in range(f1.num_edges()):
                var edge = f1.get_edge(ei)
                var hit_opt = f2.intersect_line(edge)
                if hit_opt is not None:
                    seg_pts.append(hit_opt.value())

            # Test each edge of f2 against f1
            for ei in range(f2.num_edges()):
                var edge = f2.get_edge(ei)
                var hit_opt = f1.intersect_line(edge)
                if hit_opt is not None:
                    seg_pts.append(hit_opt.value())

    # Assemble collected intersection points into a wire (simple ordering)
    if len(seg_pts) > 0:
        result.append(Wire(seg_pts))

    return result^
