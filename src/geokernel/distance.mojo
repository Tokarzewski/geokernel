from geokernel import FType, Point, Vector3, Line, Face, Shell
from std.math import sqrt


fn point_to_point(p1: Point, p2: Point) -> FType:
    """Euclidean distance between two points."""
    var dx = p2.x - p1.x
    var dy = p2.y - p1.y
    var dz = p2.z - p1.z
    return sqrt(dx * dx + dy * dy + dz * dz)


fn point_to_line(p: Point, line: Line) -> FType:
    """Perpendicular distance from point to infinite line.

    Math: project (p - line.p1) onto direction d, then compute
    distance from p to the projected point (no clamping).
    """
    var d = line.direction()
    var len_sq = d.x * d.x + d.y * d.y + d.z * d.z
    if len_sq == 0.0:
        return point_to_point(p, line.p1)
    var w = Vector3(p.x - line.p1.x, p.y - line.p1.y, p.z - line.p1.z)
    var t = w.dot(d) / len_sq
    var closest = line.point_at(t)
    return point_to_point(p, closest)


fn point_to_segment(p: Point, line: Line) -> FType:
    """Distance from point to line SEGMENT (clamped to endpoints).

    Math: same projection as point_to_line but t is clamped to [0, 1].
    t < 0  → closest to p1; t > 1 → closest to p2; else perpendicular.
    """
    var d = line.direction()
    var len_sq = d.x * d.x + d.y * d.y + d.z * d.z
    if len_sq == 0.0:
        return point_to_point(p, line.p1)
    var w = Vector3(p.x - line.p1.x, p.y - line.p1.y, p.z - line.p1.z)
    var t = w.dot(d) / len_sq
    if t < 0.0:
        t = 0.0
    elif t > 1.0:
        t = 1.0
    var closest = line.point_at(t)
    return point_to_point(p, closest)


fn point_to_plane(p: Point, plane_pt: Point, plane_normal: Vector3) -> FType:
    """Signed distance from point to plane. Positive = same side as normal.

    Math: signed_dist = dot(p - plane_pt, n_hat)
    """
    var n = plane_normal.normalize()
    var w = Vector3(p.x - plane_pt.x, p.y - plane_pt.y, p.z - plane_pt.z)
    return w.dot(n)


fn point_to_face(p: Point, face: Face) -> FType:
    """Distance from point to face.

    If perpendicular projection lies inside the polygon → distance to plane.
    Otherwise → minimum distance to the nearest edge segment.
    """
    var proj = face.project_point(p)
    if face.contains_point_2d(proj):
        return point_to_point(p, proj)
    # Nearest edge
    var min_dist = FType(1.0e18)
    for i in range(face.num_edges()):
        var edge = face.get_edge(i)
        var d = point_to_segment(p, edge)
        if d < min_dist:
            min_dist = d
    return min_dist


fn segment_to_segment(l1: Line, l2: Line) -> FType:
    """Minimum distance between two line segments.

    Math: parametric minimization of ||P(s) - Q(t)||^2 over s,t in [0,1].
    Solve the unconstrained minimum, then clamp and re-solve the boundary cases.
    Algorithm: Ericson, Real-Time Collision Detection, §5.1.9.
    """
    var d1 = l1.direction()   # l1.p2 - l1.p1
    var d2 = l2.direction()   # l2.p2 - l2.p1
    var r = Vector3(
        l1.p1.x - l2.p1.x,
        l1.p1.y - l2.p1.y,
        l1.p1.z - l2.p1.z,
    )

    var a = d1.dot(d1)  # squared length of l1
    var e = d2.dot(d2)  # squared length of l2
    var f = d2.dot(r)

    var s: FType
    var t: FType

    if a <= 1.0e-15 and e <= 1.0e-15:
        # Both segments degenerate to points
        return point_to_point(l1.p1, l2.p1)

    if a <= 1.0e-15:
        # l1 is a point
        s = 0.0
        t = f / e
        if t < 0.0:
            t = 0.0
        elif t > 1.0:
            t = 1.0
    else:
        var c = d1.dot(r)
        if e <= 1.0e-15:
            # l2 is a point
            t = 0.0
            s = -c / a
            if s < 0.0:
                s = 0.0
            elif s > 1.0:
                s = 1.0
        else:
            # General non-degenerate case
            var b = d1.dot(d2)
            var denom = a * e - b * b  # always >= 0

            if denom > 1.0e-15:
                # Lines not parallel: compute closest point on infinite lines
                s = (b * f - c * e) / denom
                if s < 0.0:
                    s = 0.0
                elif s > 1.0:
                    s = 1.0
            else:
                # Parallel segments: fix s = 0, find best t
                s = 0.0

            # Compute t for the clamped s
            t = (b * s + f) / e
            if t < 0.0:
                t = 0.0
                s = -c / a
                if s < 0.0:
                    s = 0.0
                elif s > 1.0:
                    s = 1.0
            elif t > 1.0:
                t = 1.0
                s = (b - c) / a
                if s < 0.0:
                    s = 0.0
                elif s > 1.0:
                    s = 1.0

    var p_closest = l1.point_at(s)
    var q_closest = l2.point_at(t)
    return point_to_point(p_closest, q_closest)


fn face_to_face(f1: Face, f2: Face) -> FType:
    """Minimum distance between two faces.
    If they intersect, returns 0.0.
    Otherwise, minimum of distances from each vertex of f1 to f2, and vice versa."""
    # Check edge-edge distances (catches intersection and near-miss cases)
    var min_dist = FType(1.0e18)
    for i in range(f1.num_edges()):
        for j in range(f2.num_edges()):
            var d = segment_to_segment(f1.get_edge(i), f2.get_edge(j))
            if d < min_dist:
                min_dist = d
    # Also check vertex-to-face distances (handles one face inside another)
    for i in range(f1.num_vertices()):
        var d = point_to_face(f1.get_vertex(i), f2)
        if d < min_dist:
            min_dist = d
    for i in range(f2.num_vertices()):
        var d = point_to_face(f2.get_vertex(i), f1)
        if d < min_dist:
            min_dist = d
    return min_dist


fn face_to_point(f: Face, p: Point) -> FType:
    """Alias for point_to_face(p, f) — for symmetry."""
    return point_to_face(p, f)


fn shell_to_point(shell: Shell, p: Point) -> FType:
    """Minimum distance from point to nearest face in shell."""
    var min_dist = FType(1.0e18)
    for i in range(len(shell.faces)):
        var d = point_to_face(p, shell.faces[i])
        if d < min_dist:
            min_dist = d
    return min_dist


fn shell_to_shell(s1: Shell, s2: Shell) -> FType:
    """Minimum distance between two shells.
    Iterate face pairs, return minimum face_to_face distance."""
    var min_dist = FType(1.0e18)
    for i in range(len(s1.faces)):
        for j in range(len(s2.faces)):
            var d = face_to_face(s1.faces[i], s2.faces[j])
            if d < min_dist:
                min_dist = d
    return min_dist
