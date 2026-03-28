"""Loft operation: create surfaces by interpolating between profile cross-sections."""

from geokernel import FType, Point, Vector3, Face, Shell, Wire


def loft(profiles: List[Wire], closed: Bool = False) -> Shell:
    """Create a lofted surface connecting multiple profile wires.

    Each pair of adjacent profiles generates a surface strip by connecting
    corresponding vertices. Profiles should have the same number of vertices
    for best results; if they differ, vertices are interpolated by parameter.

    Args:
        profiles: List of Wire profiles to interpolate between.
        closed: If True, also cap the first and last profiles to create a solid.

    Returns:
        Shell with quad faces connecting the profiles, plus optional caps.
    """
    var n_profiles = len(profiles)
    if n_profiles < 2:
        if n_profiles == 1:
            return Shell(List[Face]())
        return Shell(List[Face]())

    var faces = List[Face]()

    # Extract point lists from each profile
    var profile_pts = List[List[Point]]()
    for i in range(n_profiles):
        var pts = List[Point]()
        var w = profiles[i]
        var n = w.num_points()
        for j in range(n):
            pts.append(w.get_point(j))
        profile_pts.append(pts^)

    # For each pair of adjacent profiles, create connecting faces
    for i in range(n_profiles - 1):
        var pts_a = profile_pts[i]
        var pts_b = profile_pts[i + 1]
        var na = len(pts_a)
        var nb = len(pts_b)

        if na == 0 or nb == 0:
            continue

        if na == nb:
            # Same vertex count — direct quad connection
            for j in range(na):
                var j_next = (j + 1) % na
                var quad = List[Point]()
                quad.append(pts_a[j])
                quad.append(pts_a[j_next])
                quad.append(pts_b[j_next])
                quad.append(pts_b[j])
                faces.append(Face(quad))
        else:
            # Different vertex counts — use parameter-based correspondence
            var max_n = na if na > nb else nb
            for j in range(max_n):
                var t0 = FType(j) / FType(max_n)
                var t1 = FType(j + 1) / FType(max_n)
                # Sample from each profile at these parameters
                var ia0 = Int(t0 * FType(na - 1))
                var ia1 = Int(t1 * FType(na - 1))
                if ia0 >= na:
                    ia0 = na - 1
                if ia1 >= na:
                    ia1 = na - 1
                var ib0 = Int(t0 * FType(nb - 1))
                var ib1 = Int(t1 * FType(nb - 1))
                if ib0 >= nb:
                    ib0 = nb - 1
                if ib1 >= nb:
                    ib1 = nb - 1
                var quad = List[Point]()
                quad.append(pts_a[ia0])
                quad.append(pts_a[ia1])
                quad.append(pts_b[ib1])
                quad.append(pts_b[ib0])
                faces.append(Face(quad))

    # Optional caps
    if closed:
        # Cap at first profile
        if len(profile_pts[0]) >= 3:
            faces.append(Face(profile_pts[0].copy()))
        # Cap at last profile (reversed for outward normal)
        var last = profile_pts[n_profiles - 1]
        if len(last) >= 3:
            var rev = List[Point]()
            for j in range(len(last) - 1, -1, -1):
                rev.append(last[j])
            faces.append(Face(rev))

    return Shell(faces)


def ruled_surface(wire1: Wire, wire2: Wire, segments: Int = 1) -> Shell:
    """Create a ruled surface between two wires.

    A ruled surface connects corresponding points of two wires with straight
    lines. With segments > 1, intermediate profile lines are added for
    smoother tessellation.
    """
    var pts1 = List[Point]()
    var pts2 = List[Point]()
    var n1 = wire1.num_points()
    var n2 = wire2.num_points()
    for i in range(n1):
        pts1.append(wire1.get_point(i))
    for i in range(n2):
        pts2.append(wire2.get_point(i))

    var faces = List[Face]()
    var n = n1 if n1 <= n2 else n2

    for s in range(segments):
        var t0 = FType(s) / FType(segments)
        var t1 = FType(s + 1) / FType(segments)
        for j in range(n - 1):
            var a0 = _lerp_point(pts1[j], pts2[j], t0)
            var a1 = _lerp_point(pts1[j + 1], pts2[j + 1], t0)
            var b0 = _lerp_point(pts1[j], pts2[j], t1)
            var b1 = _lerp_point(pts1[j + 1], pts2[j + 1], t1)
            var quad = List[Point]()
            quad.append(a0); quad.append(a1); quad.append(b1); quad.append(b0)
            faces.append(Face(quad))

    return Shell(faces)


def _lerp_point(a: Point, b: Point, t: FType) -> Point:
    return Point(
        a.x + t * (b.x - a.x),
        a.y + t * (b.y - a.y),
        a.z + t * (b.z - a.z),
    )
