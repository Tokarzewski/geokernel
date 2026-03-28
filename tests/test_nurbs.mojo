"""Tests for NurbsCurve and NurbsSurface."""
from geokernel import FType, Point, Vector3, NurbsCurve, NurbsSurface
from std.testing import assert_true
import std.math as math

fn approx(a: FType, b: FType, tol: FType = 1e-6) -> Bool:
    if a > b: return (a - b) < tol
    return (b - a) < tol

def test_nurbs_curve_linear() raises:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(10.0, 0.0, 0.0))
    var knots = List[FType](); knots.append(0.0); knots.append(0.0); knots.append(1.0); knots.append(1.0)
    var weights = List[FType](); weights.append(1.0); weights.append(1.0)
    var c = NurbsCurve(pts, knots, 1, weights)
    var p0 = c.point_at(0.0)
    var p1 = c.point_at(1.0)
    var mid = c.point_at(0.5)
    assert_true(approx(p0.x, 0.0), "start x")
    assert_true(approx(p1.x, 10.0), "end x")
    assert_true(approx(mid.x, 5.0), "mid x")
    assert_true(approx(c.length(), 10.0, 0.1), "length ~10")
    print("  nurbs_curve_linear: PASS")

def test_nurbs_curve_quadratic() raises:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(1.0, 2.0, 0.0)); pts.append(Point(2.0, 0.0, 0.0))
    var knots = List[FType]()
    for _ in range(3): knots.append(0.0)
    for _ in range(3): knots.append(1.0)
    var weights = List[FType]()
    for _ in range(3): weights.append(1.0)
    var c = NurbsCurve(pts, knots, 2, weights)
    var start = c.point_at(0.0)
    var end = c.point_at(1.0)
    assert_true(approx(start.x, 0.0) and approx(start.y, 0.0), "start")
    assert_true(approx(end.x, 2.0) and approx(end.y, 0.0), "end")
    # Midpoint should be above y=0
    var mid = c.point_at(0.5)
    assert_true(mid.y > 0.5, "midpoint above baseline: y=" + String(mid.y))
    print("  nurbs_curve_quadratic: PASS")

def test_nurbs_curve_derivative() raises:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(10.0, 0.0, 0.0))
    var knots = List[FType](); knots.append(0.0); knots.append(0.0); knots.append(1.0); knots.append(1.0)
    var weights = List[FType](); weights.append(1.0); weights.append(1.0)
    var c = NurbsCurve(pts, knots, 1, weights)
    var d = c.derivative_at(0.5)
    assert_true(approx(d.x, 10.0, 0.5), "linear derivative ~10 in x")
    assert_true(approx(d.y, 0.0, 0.5), "linear derivative ~0 in y")
    print("  nurbs_curve_derivative: PASS")

def test_nurbs_curve_project() raises:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(10.0, 0.0, 0.0))
    var knots = List[FType](); knots.append(0.0); knots.append(0.0); knots.append(1.0); knots.append(1.0)
    var weights = List[FType](); weights.append(1.0); weights.append(1.0)
    var c = NurbsCurve(pts, knots, 1, weights)
    var closest = c.project_point(Point(5.0, 3.0, 0.0))
    assert_true(approx(closest.x, 5.0, 0.1), "projection x ~5")
    assert_true(approx(closest.y, 0.0, 0.1), "projection y ~0")
    print("  nurbs_curve_project: PASS")

def test_nurbs_surface() raises:
    # Flat 2x2 control grid
    var cp = List[List[Point]]()
    var row0 = List[Point](); row0.append(Point(0.0, 0.0, 0.0)); row0.append(Point(1.0, 0.0, 0.0))
    var row1 = List[Point](); row1.append(Point(0.0, 1.0, 0.0)); row1.append(Point(1.0, 1.0, 0.0))
    cp.append(row0^); cp.append(row1^)
    var ku = List[FType](); ku.append(0.0); ku.append(0.0); ku.append(1.0); ku.append(1.0)
    var kv = List[FType](); kv.append(0.0); kv.append(0.0); kv.append(1.0); kv.append(1.0)
    var w = List[List[FType]]()
    var w0 = List[FType](); w0.append(1.0); w0.append(1.0)
    var w1 = List[FType](); w1.append(1.0); w1.append(1.0)
    w.append(w0^); w.append(w1^)
    var s = NurbsSurface(cp, ku, kv, 1, 1, w)
    var p = s.point_at(0.5, 0.5)
    assert_true(approx(p.x, 0.5) and approx(p.y, 0.5) and approx(p.z, 0.0), "center of flat surface")
    assert_true(s.is_planar(), "flat surface is planar")
    var n = s.normal_at(0.5, 0.5)
    assert_true(approx(math.abs(n.z), 1.0, 0.1), "normal should be ±Z")
    print("  nurbs_surface: PASS")

def main() raises:
    print("=== NURBS Tests ===")
    test_nurbs_curve_linear()
    test_nurbs_curve_quadratic()
    test_nurbs_curve_derivative()
    test_nurbs_curve_project()
    test_nurbs_surface()
    print("=== ALL PASSED ===")
