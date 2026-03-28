"""Tests for boolean operations and distance functions."""
from geokernel import FType, Point, Vector3, Face, Shell, Line
from geokernel.boolean import clip_polygon, intersect_faces, union_faces, difference_faces
from geokernel.distance import point_to_point, point_to_line, point_to_segment, point_to_face, face_to_face, segment_to_segment
from std.testing import assert_true
import std.math as math

fn approx(a: FType, b: FType, tol: FType = 1e-6) -> Bool:
    if a > b: return (a - b) < tol
    return (b - a) < tol

fn make_unit_square() -> Face:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(1.0, 1.0, 0.0))
    pts.append(Point(0.0, 1.0, 0.0))
    return Face(pts)

def test_clip_polygon() raises:
    # Clip unit square by shifted square [0.5, 1.5] x [0, 1]
    var subject = List[Point]()
    subject.append(Point(0.0, 0.0, 0.0)); subject.append(Point(1.0, 0.0, 0.0))
    subject.append(Point(1.0, 1.0, 0.0)); subject.append(Point(0.0, 1.0, 0.0))
    var clip = List[Point]()
    clip.append(Point(0.5, 0.0, 0.0)); clip.append(Point(1.5, 0.0, 0.0))
    clip.append(Point(1.5, 1.0, 0.0)); clip.append(Point(0.5, 1.0, 0.0))
    var result = clip_polygon(subject, clip)
    assert_true(len(result) >= 3, "clipped polygon has vertices")
    # Should be approximately 0.5 x 1.0 = 0.5 area
    var area = Face(result).area()
    assert_true(approx(area, 0.5, 0.1), "clip area ~0.5, got " + String(area))
    print("  clip_polygon: PASS")

def test_intersect_faces() raises:
    var a = make_unit_square()
    var b_pts = List[Point]()
    b_pts.append(Point(0.5, 0.5, 0.0)); b_pts.append(Point(1.5, 0.5, 0.0))
    b_pts.append(Point(1.5, 1.5, 0.0)); b_pts.append(Point(0.5, 1.5, 0.0))
    var b = Face(b_pts)
    var inter = intersect_faces(a, b)
    assert_true(inter.num_vertices() >= 3, "intersection has vertices")
    assert_true(approx(inter.area(), 0.25, 0.1), "intersection area ~0.25")
    print("  intersect_faces: PASS")

def test_union_faces() raises:
    var a = make_unit_square()
    var b_pts = List[Point]()
    b_pts.append(Point(5.0, 5.0, 0.0)); b_pts.append(Point(6.0, 5.0, 0.0))
    b_pts.append(Point(6.0, 6.0, 0.0)); b_pts.append(Point(5.0, 6.0, 0.0))
    var b = Face(b_pts)
    var result = union_faces(a, b)
    assert_true(len(result) == 2, "disjoint union gives 2 faces")
    print("  union_faces: PASS")

def test_difference_faces() raises:
    var a = make_unit_square()
    var b_pts = List[Point]()
    b_pts.append(Point(5.0, 5.0, 0.0)); b_pts.append(Point(6.0, 5.0, 0.0))
    b_pts.append(Point(6.0, 6.0, 0.0)); b_pts.append(Point(5.0, 6.0, 0.0))
    var b = Face(b_pts)
    var result = difference_faces(a, b)
    assert_true(len(result) == 1, "disjoint diff gives 1 face (a)")
    assert_true(approx(result[0].area(), 1.0, 0.1), "diff area = original")
    print("  difference_faces: PASS")

def test_point_to_point_dist() raises:
    var d = point_to_point(Point(0.0, 0.0, 0.0), Point(3.0, 4.0, 0.0))
    assert_true(approx(d, 5.0), "p2p dist = 5")
    print("  point_to_point: PASS")

def test_point_to_line_dist() raises:
    # Point (0,1,0) to line from (0,0,0) to (10,0,0) → distance = 1
    var line = Line(Point(0.0, 0.0, 0.0), Point(10.0, 0.0, 0.0))
    var d = point_to_line(Point(0.0, 1.0, 0.0), line)
    assert_true(approx(d, 1.0), "point to line = 1")
    print("  point_to_line: PASS")

def test_point_to_segment_dist() raises:
    # Point beyond segment endpoint
    var line = Line(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0))
    var d = point_to_segment(Point(5.0, 0.0, 0.0), line)
    assert_true(approx(d, 4.0), "beyond endpoint = 4")
    # Point perpendicular to segment
    var d2 = point_to_segment(Point(0.5, 3.0, 0.0), line)
    assert_true(approx(d2, 3.0), "perpendicular = 3")
    print("  point_to_segment: PASS")

def test_segment_to_segment_dist() raises:
    # Parallel segments offset by 2 in Y
    var l1 = Line(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0))
    var l2 = Line(Point(0.0, 2.0, 0.0), Point(1.0, 2.0, 0.0))
    var d = segment_to_segment(l1, l2)
    assert_true(approx(d, 2.0), "parallel segments dist = 2")
    print("  segment_to_segment: PASS")

def test_point_to_face_dist() raises:
    var face = make_unit_square()
    # Point directly above center
    var d = point_to_face(Point(0.5, 0.5, 5.0), face)
    assert_true(approx(d, 5.0), "above center = 5")
    print("  point_to_face: PASS")

def test_face_to_face_dist() raises:
    var f1 = make_unit_square()
    var f2_pts = List[Point]()
    f2_pts.append(Point(0.0, 0.0, 3.0)); f2_pts.append(Point(1.0, 0.0, 3.0))
    f2_pts.append(Point(1.0, 1.0, 3.0)); f2_pts.append(Point(0.0, 1.0, 3.0))
    var f2 = Face(f2_pts)
    var d = face_to_face(f1, f2)
    assert_true(approx(d, 3.0), "parallel faces dist = 3")
    print("  face_to_face: PASS")

def main() raises:
    print("=== Boolean + Distance Tests ===")
    test_clip_polygon()
    test_intersect_faces()
    test_union_faces()
    test_difference_faces()
    test_point_to_point_dist()
    test_point_to_line_dist()
    test_point_to_segment_dist()
    test_segment_to_segment_dist()
    test_point_to_face_dist()
    test_face_to_face_dist()
    print("=== ALL PASSED ===")
