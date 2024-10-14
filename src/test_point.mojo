from testing import assert_equal, assert_true, assert_false
from geokernel import FType, Point


def test_isclose1():
    # if Ftype.element_type == Float64:
    p1 = Point(0, 0, 2)
    p2 = Point(0, 0, 2.00000000000001)
    assert_false(p1 == p2)


def test_isclose2():
    p1 = Point(0, 0, 2)
    p3 = Point(0, 0, 2.000000000000001)
    assert_true(p1 == p3)


def test_move():
    p4 = Point(0, 1, 2)
    assert_true(p4 == p4.move(0, -1, -2))


def test_moved():
    p4 = Point(0, 1, 2)
    assert_false(p4 == p4.moved(0, -1, -2))
