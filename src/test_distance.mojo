from testing import assert_true
from geokernel import FType, Point, Vector3, Line, Face, Shell
from geokernel.distance import (
    point_to_point,
    point_to_line,
    point_to_segment,
    point_to_plane,
    point_to_face,
    segment_to_segment,
    face_to_face,
    face_to_point,
    shell_to_point,
    shell_to_shell,
)
from std.math import sqrt, abs


fn near(got: FType, expected: FType, tol: FType = 1.0e-9) -> Bool:
    var diff = got - expected
    if diff < 0.0:
        diff = -diff
    return diff <= tol


# 1. point_to_point: 3-4-5 triangle → 5.0
def test_point_to_point() raises:
    assert_true(near(point_to_point(Point(0.0, 0.0, 0.0), Point(3.0, 4.0, 0.0)), 5.0))


# 2. point_to_line: point (1,1,0), line along x-axis → 1.0
def test_point_to_line_perpendicular() raises:
    var ax = Line(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0))
    assert_true(near(point_to_line(Point(1.0, 1.0, 0.0), ax), 1.0))


# 3. point_to_line: point on the line → 0.0
def test_point_to_line_on_line() raises:
    var ax = Line(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0))
    assert_true(near(point_to_line(Point(5.0, 0.0, 0.0), ax), 0.0))


# 4. point_to_segment: point beyond endpoint → distance to p2
def test_point_to_segment_beyond() raises:
    var seg = Line(Point(0.0, 0.0, 0.0), Point(2.0, 0.0, 0.0))
    assert_true(near(point_to_segment(Point(5.0, 0.0, 0.0), seg), 3.0))


# 5. point_to_segment: point projects onto segment → perpendicular distance
def test_point_to_segment_projects() raises:
    var seg = Line(Point(0.0, 0.0, 0.0), Point(2.0, 0.0, 0.0))
    assert_true(near(point_to_segment(Point(1.0, 2.0, 0.0), seg), 2.0))


# 6. point_to_segment: point before start → distance to p1
def test_point_to_segment_before() raises:
    var seg = Line(Point(0.0, 0.0, 0.0), Point(2.0, 0.0, 0.0))
    assert_true(near(point_to_segment(Point(-3.0, 0.0, 0.0), seg), 3.0))


# 7. point_to_plane: point above z=0 → +1.0
def test_point_to_plane_above() raises:
    assert_true(near(
        point_to_plane(Point(0.0, 0.0, 1.0), Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0)),
        1.0,
    ))


# 8. point_to_plane: point below z=0 → -2.0
def test_point_to_plane_below() raises:
    assert_true(near(
        point_to_plane(Point(0.0, 0.0, -2.0), Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0)),
        -2.0,
    ))


# 9. point_to_face: above center of unit square → dist = height
def test_point_to_face_inside() raises:
    var sq_pts = List[Point]()
    sq_pts.append(Point(0.0, 0.0, 0.0))
    sq_pts.append(Point(1.0, 0.0, 0.0))
    sq_pts.append(Point(1.0, 1.0, 0.0))
    sq_pts.append(Point(0.0, 1.0, 0.0))
    var sq = Face(sq_pts)
    assert_true(near(point_to_face(Point(0.5, 0.5, 3.0), sq), 3.0))


# 10. point_to_face: outside face → nearest edge distance
def test_point_to_face_outside() raises:
    var sq_pts = List[Point]()
    sq_pts.append(Point(0.0, 0.0, 0.0))
    sq_pts.append(Point(1.0, 0.0, 0.0))
    sq_pts.append(Point(1.0, 1.0, 0.0))
    sq_pts.append(Point(0.0, 1.0, 0.0))
    var sq = Face(sq_pts)
    assert_true(near(point_to_face(Point(2.0, 0.5, 0.0), sq), 1.0))


# 11. segment_to_segment: parallel segments → dist = 1.0
def test_segment_to_segment_parallel() raises:
    var s1 = Line(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0))
    var s2 = Line(Point(0.0, 1.0, 0.0), Point(1.0, 1.0, 0.0))
    assert_true(near(segment_to_segment(s1, s2), 1.0))


# 12. segment_to_segment: crossing → 0.0
def test_segment_to_segment_crossing() raises:
    var s1 = Line(Point(0.0, 0.0, 0.0), Point(2.0, 0.0, 0.0))
    var s2 = Line(Point(1.0, -1.0, 0.0), Point(1.0, 1.0, 0.0))
    assert_true(near(segment_to_segment(s1, s2), 0.0))


# 13. segment_to_segment: skew → sqrt(2)
def test_segment_to_segment_skew() raises:
    var s1 = Line(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0))
    var s2 = Line(Point(0.0, 1.0, 1.0), Point(1.0, 1.0, 1.0))
    assert_true(near(segment_to_segment(s1, s2), sqrt(FType(2.0))))


fn make_square(ox: FType, oy: FType, oz: FType) -> Face:
    """Unit square face at offset (ox, oy, oz) in the XY plane."""
    var pts = List[Point]()
    pts.append(Point(ox, oy, oz))
    pts.append(Point(ox + 1.0, oy, oz))
    pts.append(Point(ox + 1.0, oy + 1.0, oz))
    pts.append(Point(ox, oy + 1.0, oz))
    return Face(pts)


# 14. face_to_face: separated faces → dist = 2.0
def test_face_to_face_separated() raises:
    var f1 = make_square(0.0, 0.0, 0.0)
    var f2 = make_square(0.0, 0.0, 2.0)
    assert_true(near(face_to_face(f1, f2), 2.0))


# 15. face_to_face: coplanar touching → 0.0
def test_face_to_face_touching() raises:
    var f1 = make_square(0.0, 0.0, 0.0)
    var f2 = make_square(1.0, 0.0, 0.0)
    assert_true(near(face_to_face(f1, f2), 0.0))


# 16. face_to_face: overlapping → 0.0
def test_face_to_face_overlapping() raises:
    var f1 = make_square(0.0, 0.0, 0.0)
    var f2 = make_square(0.5, 0.5, 0.0)
    assert_true(near(face_to_face(f1, f2), 0.0))


# 17. face_to_point: symmetry with point_to_face
def test_face_to_point() raises:
    var sq = make_square(0.0, 0.0, 0.0)
    var p = Point(0.5, 0.5, 3.0)
    assert_true(near(face_to_point(sq, p), point_to_face(p, sq)))


# 18. shell_to_point: nearest face of a two-face shell
def test_shell_to_point() raises:
    var faces = List[Face]()
    faces.append(make_square(0.0, 0.0, 0.0))
    faces.append(make_square(0.0, 0.0, 10.0))
    var s = Shell(faces)
    assert_true(near(shell_to_point(s, Point(0.5, 0.5, 1.0)), 1.0))


# 19. shell_to_shell: separated shells
def test_shell_to_shell_separated() raises:
    var fa = List[Face]()
    fa.append(make_square(0.0, 0.0, 0.0))
    var fb = List[Face]()
    fb.append(make_square(0.0, 0.0, 5.0))
    assert_true(near(shell_to_shell(Shell(fa), Shell(fb)), 5.0))


# 20. shell_to_shell: overlapping → 0.0
def test_shell_to_shell_touching() raises:
    var fa = List[Face]()
    fa.append(make_square(0.0, 0.0, 0.0))
    var fb = List[Face]()
    fb.append(make_square(0.5, 0.5, 0.0))
    assert_true(near(shell_to_shell(Shell(fa), Shell(fb)), 0.0))


fn main() raises:
    print("=== test_distance.mojo ===")
    test_point_to_point()
    test_point_to_line_perpendicular()
    test_point_to_line_on_line()
    test_point_to_segment_beyond()
    test_point_to_segment_projects()
    test_point_to_segment_before()
    test_point_to_plane_above()
    test_point_to_plane_below()
    test_point_to_face_inside()
    test_point_to_face_outside()
    test_segment_to_segment_parallel()
    test_segment_to_segment_crossing()
    test_segment_to_segment_skew()
    test_face_to_face_separated()
    test_face_to_face_touching()
    test_face_to_face_overlapping()
    test_face_to_point()
    test_shell_to_point()
    test_shell_to_shell_separated()
    test_shell_to_shell_touching()
    print("=== ALL 20 DISTANCE TESTS PASSED ✓ ===")
