from testing import assert_equal, assert_true, assert_false
from geokernel import Point, Face


def test_area_for_concave():
    p1 = Point(0, 0, 0)
    p2 = Point(1, 2, 0)
    p3 = Point(1, 1, 0)
    p4 = Point(2, 1, 0)

    arrow = Face(List[Point](p1, p2, p3, p4))

    assert_equal(arrow.area(), 1)


def test_square():
    p1 = Point(0, 0, 0)
    p2 = Point(1, 0, 0)
    p3 = Point(1, 1, 0)
    p4 = Point(0, 1, 0)

    square = Face(List[Point](p1, p2, p3, p4))

    b1 = square.num_vertices() == 4
    b2 = square.num_edges() == 4
    b3 = square.perimeter() == 4.0
    b4 = square.area() == 1.0

    assert_true(b1 & b2 & b3 & b4)


def test_triangle():
    p1 = Point(0, 0, 0)
    p2 = Point(1, 0, 0)
    p3 = Point(1, 1, 0)
    triangle = Face(List[Point](p1, p2, p3))

    b1 = triangle.num_vertices() == 3
    b2 = triangle.num_edges() == 3
    b3 = 3.414 < triangle.perimeter() < 3.415
    b4 = triangle.area() == 0.5

    assert_true(b1 & b2 & b3 & b4)


def test_normal_for_collinear_edges():
    p1 = Point(0, 0, 0)
    p2 = Point(0.5, 0, 0)
    p3 = Point(1, 0, 0)
    p4 = Point(0, 1, 0)

    square = Face(List[Point](p1, p2, p3, p4))
    assert_true(square.normal().length() > 0)
