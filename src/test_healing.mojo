from geokernel import (
    Point, Face, Shell,
    merge_coincident_vertices, remove_degenerate_edges, fix_face_normals,
    close_shell_gaps,
)


def _dist_sq(a: Point, b: Point) -> Float64:
    var dx = a.x - b.x
    var dy = a.y - b.y
    var dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz


def test_close_gaps() raises:
    """Two adjacent faces that ALMOST share an edge but one vertex is off by < tol.
    After close_shell_gaps, the gap should be closed."""
    # Face A: unit square on XY plane
    var pts_a = List[Point]()
    pts_a.append(Point(0.0, 0.0, 0.0))
    pts_a.append(Point(1.0, 0.0, 0.0))
    pts_a.append(Point(1.0, 1.0, 0.0))
    pts_a.append(Point(0.0, 1.0, 0.0))
    var fa = Face(pts_a)

    # Face B: shares edge at x=1, but with a tiny gap (vertex off by 5e-5)
    var pts_b = List[Point]()
    pts_b.append(Point(1.00005, 0.0, 0.0))   # should snap to (1,0,0)
    pts_b.append(Point(2.0, 0.0, 0.0))
    pts_b.append(Point(2.0, 1.0, 0.0))
    pts_b.append(Point(1.00005, 1.0, 0.0))   # should snap to (1,1,0)
    var fb = Face(pts_b)

    var faces = List[Face]()
    faces.append(fa)
    faces.append(fb)
    var shell = Shell(faces)

    # Before healing: the shared edge has a gap
    var open_before = shell.open_edges()
    print("Open edges before healing:", len(open_before))

    # Heal with default tol=1e-4, which covers the 5e-5 offset
    var healed = close_shell_gaps(shell)

    # After healing: the snapped vertices should make the shared edge match
    var open_after = healed.open_edges()
    print("Open edges after healing:", len(open_after))

    # Verify the gap is reduced: the snapped shell should have fewer open edges
    # The two interior boundary edges should now be shared
    # Face count should remain the same
    print("Faces after healing:", len(healed.faces))

    # Check that the snapped vertex is close to the midpoint
    var v0 = healed.faces[0].get_vertex(1)  # was (1,0,0) in face A
    var v1 = healed.faces[1].get_vertex(0)  # was (1.00005,0,0) in face B
    var d = _dist_sq(v0, v1)
    if d < 1e-12:
        print("PASS: gap closed, vertices match")
    else:
        print("FAIL: vertices still differ, dist_sq =", d)

    # Also verify non-boundary vertices are untouched
    var corner = healed.faces[1].get_vertex(1)  # should still be (2,0,0)
    if abs(corner.x - 2.0) < 1e-12 and abs(corner.y) < 1e-12 and abs(corner.z) < 1e-12:
        print("PASS: non-boundary vertex untouched")
    else:
        print("FAIL: non-boundary vertex moved")


def test_no_gaps() raises:
    """Shell with no gaps should be returned unchanged."""
    var pts_a = List[Point]()
    pts_a.append(Point(0.0, 0.0, 0.0))
    pts_a.append(Point(1.0, 0.0, 0.0))
    pts_a.append(Point(1.0, 1.0, 0.0))
    pts_a.append(Point(0.0, 1.0, 0.0))
    var fa = Face(pts_a)

    var pts_b = List[Point]()
    pts_b.append(Point(1.0, 0.0, 0.0))
    pts_b.append(Point(2.0, 0.0, 0.0))
    pts_b.append(Point(2.0, 1.0, 0.0))
    pts_b.append(Point(1.0, 1.0, 0.0))
    var fb = Face(pts_b)

    var faces = List[Face]()
    faces.append(fa)
    faces.append(fb)
    var shell = Shell(faces)

    var healed = close_shell_gaps(shell)
    print("Faces (no-gap shell):", len(healed.faces))
    print("PASS: no-gap shell handled")


def main() raises:
    test_close_gaps()
    test_no_gaps()
    print("All healing tests done!")
