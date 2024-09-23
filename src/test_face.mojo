from testing import assert_equal, assert_true, assert_false
from geokernel import Point, Face


def test_area_for_concave():
    var p1 = Point(0, 0, 0)
    var p2 = Point(1, 2, 0)
    var p3 = Point(1, 1, 0)
    var p4 = Point(2, 1, 0)

    var arrow = Face(List[Point](p1, p2, p3, p4))

    assert_equal(arrow.area(), 1)


def test_square():
    var p1 = Point(0, 0, 0)
    var p2 = Point(1, 0, 0)
    var p3 = Point(1, 1, 0)
    var p4 = Point(0, 1, 0)

    var square = Face(List[Point](p1, p2, p3, p4))

    var b1 = square.num_vertices() == 4
    var b2 = square.num_edges() == 4
    var b3 = square.perimeter() == 4.0
    var b4 = square.area() == 1.0

    assert_true(b1 & b2 & b3 & b4)


def test_triangle():
    var p1 = Point(0, 0, 0)
    var p2 = Point(1, 0, 0)
    var p3 = Point(1, 1, 0)
    var triangle = Face(List[Point](p1, p2, p3))

    var b1 = triangle.num_vertices()
    var b2 = triangle.num_edges() == 3
    var b3 = 3.414 < triangle.perimeter() < 3.415
    var b4 = triangle.area() == 0.5

    assert_true(b1 & b2 & b3 & b4)


def test_normal_for_collinear_edges():
    var p1 = Point(0, 0, 0)
    var p2 = Point(0.5, 0, 0)
    var p3 = Point(1, 0, 0)
    var p4 = Point(0, 1, 0)

    var square = Face(List[Point](p1, p2, p3, p4))
    assert_true(square.normal().length() > 0)
