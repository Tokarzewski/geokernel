from geokernel import FType, Point, Vector3, Face
from geokernel import Triangulation, PointInPolygon
from math import abs, sqrt


def make_triangle() -> Face:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(0.0, 1.0, 0.0))
    return Face(pts)


def make_square() -> Face:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(1.0, 1.0, 0.0))
    pts.append(Point(0.0, 1.0, 0.0))
    return Face(pts)


def make_pentagon() -> Face:
    var pts = List[Point]()
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(0.309, 0.951, 0.0))
    pts.append(Point(-0.809, 0.588, 0.0))
    pts.append(Point(-0.809, -0.588, 0.0))
    pts.append(Point(0.309, -0.951, 0.0))
    return Face(pts)


def test_face_normal() raises:
    var tri = make_triangle()
    var n = tri.normal()
    var ok = abs(abs(n.z) - 1.0) < 1e-6 and abs(n.x) < 1e-6 and abs(n.y) < 1e-6
    if ok:
        print("PASS: triangle normal")
    else:
        print("FAIL: triangle normal =", n.__repr__())


def test_face_centroid() raises:
    var sq = make_square()
    var c = sq.centroid()
    var ok = abs(c.x - 0.5) < 1e-10 and abs(c.y - 0.5) < 1e-10 and abs(c.z) < 1e-10
    if ok:
        print("PASS: square centroid")
    else:
        print("FAIL: centroid =", c.__repr__())


def test_face_is_planar() raises:
    var sq = make_square()
    if sq.is_planar():
        print("PASS: square is planar")
    else:
        print("FAIL: square should be planar")


def test_face_triangulate() raises:
    var pent = make_pentagon()
    var tris = pent.triangulate()
    # Pentagon (5 verts) should give 3 triangles
    if len(tris) == 3:
        print("PASS: pentagon triangulates to 3 triangles")
    else:
        print("FAIL: expected 3 triangles, got", String(len(tris)))


def test_point_in_polygon() raises:
    var sq = make_square()
    var inside = Point(0.5, 0.5, 0.0)
    var outside = Point(2.0, 2.0, 0.0)
    var n = sq.normal()
    if PointInPolygon.classify(inside, sq.points, n):
        print("PASS: point inside square")
    else:
        print("FAIL: point should be inside")
    if not PointInPolygon.classify(outside, sq.points, n):
        print("PASS: point outside square")
    else:
        print("FAIL: point should be outside")


def test_triangulation_direct() raises:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(1.0, 1.0, 0.0))
    pts.append(Point(0.0, 1.0, 0.0))
    var tris = Triangulation.triangulate(pts)
    # Square = 2 triangles
    if len(tris) == 2:
        print("PASS: square triangulates to 2 triangles")
    else:
        print("FAIL: expected 2, got", String(len(tris)))


def main() raises:
    print("=== Face Operations Tests ===")
    test_face_normal()
    test_face_centroid()
    test_face_is_planar()
    test_face_triangulate()
    test_point_in_polygon()
    test_triangulation_direct()
    print("=== Done ===")
