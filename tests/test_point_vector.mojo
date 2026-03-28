"""Tests for Point and Vector3 types."""
from geokernel import FType, Point, Vector3
from std.testing import assert_true
import std.math as math

fn approx(a: FType, b: FType, tol: FType = 1e-9) -> Bool:
    if a > b: return (a - b) < tol
    return (b - a) < tol

def test_point_arithmetic() raises:
    var p1 = Point(1.0, 2.0, 3.0)
    var p2 = Point(4.0, 5.0, 6.0)
    var s = p1 + p2
    assert_true(approx(s.x, 5.0) and approx(s.y, 7.0) and approx(s.z, 9.0), "add")
    var d = p2 - p1
    assert_true(approx(d.x, 3.0) and approx(d.y, 3.0) and approx(d.z, 3.0), "sub")
    var m = p1 * 2.0
    assert_true(approx(m.x, 2.0) and approx(m.y, 4.0), "mul")
    var dv = p2 / 2.0
    assert_true(approx(dv.x, 2.0) and approx(dv.y, 2.5), "div")
    print("  point_arithmetic: PASS")

def test_point_ordering() raises:
    # Lexicographic: (1,5,0) < (2,0,0) because x=1 < x=2
    assert_true(Point(1.0, 5.0, 0.0) < Point(2.0, 0.0, 0.0), "lex x")
    # Same x, compare y: (1,2,0) < (1,3,0)
    assert_true(Point(1.0, 2.0, 0.0) < Point(1.0, 3.0, 0.0), "lex y")
    # Same x,y, compare z
    assert_true(Point(1.0, 2.0, 3.0) < Point(1.0, 2.0, 4.0), "lex z")
    # Not less
    assert_true(not (Point(2.0, 0.0, 0.0) < Point(1.0, 5.0, 0.0)), "not lt")
    print("  point_ordering: PASS")

def test_point_equality() raises:
    assert_true(Point(1.0, 2.0, 3.0) == Point(1.0, 2.0, 3.0), "eq")
    assert_true(Point(1.0, 2.0, 3.0) != Point(1.0, 2.0, 3.1), "ne")
    print("  point_equality: PASS")

def test_point_transform() raises:
    from geokernel import Transform, Quaternion
    var p = Point(1.0, 0.0, 0.0)
    var q = Quaternion.from_axis_angle(Vector3(0.0, 0.0, 1.0), math.pi / 2.0)
    var t = Transform(Vector3(10.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0), q)
    var result = p.transform(t)
    # Rotate (1,0,0) by 90° around Z → (0,1,0), then translate +10 in x
    assert_true(approx(result.x, 10.0, 1e-6), "transform x: " + String(result.x))
    assert_true(approx(result.y, 1.0, 1e-6), "transform y: " + String(result.y))
    print("  point_transform: PASS")

def test_vector_basics() raises:
    var v = Vector3(3.0, 4.0, 0.0)
    assert_true(approx(v.length(), 5.0), "length")
    var n = v.normalize()
    assert_true(approx(n.length(), 1.0), "normalized length")
    # Zero vector normalize should return zero
    var z = Vector3(0.0, 0.0, 0.0).normalize()
    assert_true(approx(z.length(), 0.0), "zero normalize")
    print("  vector_basics: PASS")

def test_vector_dot_cross() raises:
    var a = Vector3(1.0, 0.0, 0.0)
    var b = Vector3(0.0, 1.0, 0.0)
    assert_true(approx(a.dot(b), 0.0), "perpendicular dot = 0")
    var c = a.cross(b)
    assert_true(approx(c.x, 0.0) and approx(c.y, 0.0) and approx(c.z, 1.0), "X cross Y = Z")
    # Angle
    var angle = a.angle(b)
    assert_true(approx(angle, math.pi / 2.0, 1e-6), "angle = pi/2")
    print("  vector_dot_cross: PASS")

def test_vector_lerp() raises:
    var a = Vector3(0.0, 0.0, 0.0)
    var b = Vector3(10.0, 0.0, 0.0)
    var mid = a.lerp(b, 0.5)
    assert_true(approx(mid.x, 5.0), "lerp midpoint")
    print("  vector_lerp: PASS")

def test_vector_inverse_safe() raises:
    var v = Vector3(2.0, 0.0, 4.0)
    var inv = v.inverse()
    assert_true(approx(inv.x, 0.5), "inverse x")
    assert_true(approx(inv.y, 0.0), "inverse y (zero safe)")
    assert_true(approx(inv.z, 0.25), "inverse z")
    print("  vector_inverse_safe: PASS")

def main() raises:
    print("=== Point/Vector3 Tests ===")
    test_point_arithmetic()
    test_point_ordering()
    test_point_equality()
    test_point_transform()
    test_vector_basics()
    test_vector_dot_cross()
    test_vector_lerp()
    test_vector_inverse_safe()
    print("=== ALL PASSED ===")
