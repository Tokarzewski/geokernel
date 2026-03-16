from testing import assert_true
from geokernel import FType, Point, Vector3, Line, Face
from geokernel.distance import (
    point_to_point,
    point_to_line,
    point_to_segment,
    point_to_plane,
    point_to_face,
    segment_to_segment,
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
    print("=== ALL 13 DISTANCE TESTS PASSED ✓ ===")
