from std.testing import assert_equal, assert_true, assert_false
from geokernel import FType, Point, Vector3, Plane
from geokernel import PlanarSurface, NurbsSurface
import math


fn test_planar_surface_area() raises:
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var surf = PlanarSurface(plane, 4.0, 3.0)
    var a = surf.area()
    assert_true(math.isclose(a, 12.0, atol=1e-10, rtol=0.0))


fn test_planar_surface_normal() raises:
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var surf = PlanarSurface(plane, 4.0, 3.0)
    var n = surf.normal_at(0.5, 0.5)
    assert_true(math.isclose(n.x, 0.0, atol=1e-10, rtol=0.0))
    assert_true(math.isclose(n.y, 0.0, atol=1e-10, rtol=0.0))
    assert_true(math.isclose(n.z, 1.0, atol=1e-10, rtol=0.0))


fn test_planar_surface_point_at_center() raises:
    var origin = Point(0.0, 0.0, 5.0)
    var plane = Plane(origin, Vector3(0.0, 0.0, 1.0))
    var surf = PlanarSurface(plane, 2.0, 2.0)
    # u=0.5, v=0.5 should return the plane origin
    var p = surf.point_at(0.5, 0.5)
    assert_true(math.isclose(p.x, 0.0, atol=1e-10, rtol=0.0))
    assert_true(math.isclose(p.y, 0.0, atol=1e-10, rtol=0.0))
    assert_true(math.isclose(p.z, 5.0, atol=1e-10, rtol=0.0))


fn test_planar_surface_is_planar() raises:
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var surf = PlanarSurface(plane, 1.0, 1.0)
    assert_true(surf.is_planar())


fn test_planar_surface_project_point() raises:
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var surf = PlanarSurface(plane, 10.0, 10.0)
    var p = Point(1.0, 2.0, 5.0)
    var proj = surf.project_point(p)
    assert_true(math.isclose(proj.x, 1.0, atol=1e-10, rtol=0.0))
    assert_true(math.isclose(proj.y, 2.0, atol=1e-10, rtol=0.0))
    assert_true(math.isclose(proj.z, 0.0, atol=1e-10, rtol=0.0))


fn test_planar_surface_contains_point() raises:
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var surf = PlanarSurface(plane, 4.0, 4.0)
    var inside = Point(0.5, 0.5, 0.0)
    var outside = Point(5.0, 5.0, 0.0)
    assert_true(surf.contains_point(inside, 1e-8))
    assert_false(surf.contains_point(outside, 1e-8))


fn _make_bilinear_nurbs() -> NurbsSurface:
    """Create a simple 2x2 bilinear patch (unit square in XY plane)."""
    var cp = List[List[Point]]()
    var row0 = List[Point]()
    row0.append(Point(0.0, 0.0, 0.0))
    row0.append(Point(0.0, 1.0, 0.0))
    var row1 = List[Point]()
    row1.append(Point(1.0, 0.0, 0.0))
    row1.append(Point(1.0, 1.0, 0.0))
    cp.append(row0^)
    cp.append(row1^)

    var knots_u = List[FType]()
    knots_u.append(0.0)
    knots_u.append(0.0)
    knots_u.append(1.0)
    knots_u.append(1.0)

    var knots_v = List[FType]()
    knots_v.append(0.0)
    knots_v.append(0.0)
    knots_v.append(1.0)
    knots_v.append(1.0)

    var weights = List[List[FType]]()
    var w0 = List[FType]()
    w0.append(1.0)
    w0.append(1.0)
    var w1 = List[FType]()
    w1.append(1.0)
    w1.append(1.0)
    weights.append(w0^)
    weights.append(w1^)

    return NurbsSurface(cp, knots_u, knots_v, 1, 1, weights)


fn test_nurbs_construction() raises:
    var surf = _make_bilinear_nurbs()
    assert_equal(surf.num_control_points_u(), 2)
    assert_equal(surf.num_control_points_v(), 2)
    assert_equal(surf.degree_u(), 1)
    assert_equal(surf.degree_v(), 1)


fn test_nurbs_point_at_corner() raises:
    var surf = _make_bilinear_nurbs()
    var p = surf.point_at(0.0, 0.0)
    assert_true(math.isclose(p.x, 0.0, atol=1e-8, rtol=0.0))
    assert_true(math.isclose(p.y, 0.0, atol=1e-8, rtol=0.0))
    assert_true(math.isclose(p.z, 0.0, atol=1e-8, rtol=0.0))


fn test_nurbs_point_at_center() raises:
    var surf = _make_bilinear_nurbs()
    var p = surf.point_at(0.5, 0.5)
    assert_true(math.isclose(p.x, 0.5, atol=1e-8, rtol=0.0))
    assert_true(math.isclose(p.y, 0.5, atol=1e-8, rtol=0.0))
    assert_true(math.isclose(p.z, 0.0, atol=1e-8, rtol=0.0))


fn test_nurbs_is_planar() raises:
    var surf = _make_bilinear_nurbs()
    assert_true(surf.is_planar())


fn test_nurbs_area() raises:
    var surf = _make_bilinear_nurbs()
    var a = surf.area()
    # Unit square has area 1.0
    assert_true(math.isclose(a, 1.0, atol=1e-3, rtol=0.0))


fn test_nurbs_normal() raises:
    var surf = _make_bilinear_nurbs()
    var n = surf.normal_at(0.5, 0.5)
    # Normal of XY plane is Z
    assert_true(math.isclose(math.abs(n.z), 1.0, atol=1e-6, rtol=0.0))


fn test_nurbs_repr() raises:
    var surf = _make_bilinear_nurbs()
    var r = surf.__repr__()
    assert_true(len(r) > 0)

fn main() raises:
    test_planar_surface_area()
    test_planar_surface_normal()
    test_planar_surface_point_at_center()
    test_planar_surface_is_planar()
    test_planar_surface_project_point()
    test_planar_surface_contains_point()
    test_nurbs_construction()
    test_nurbs_point_at_corner()
    test_nurbs_point_at_center()
    test_nurbs_is_planar()
    test_nurbs_area()
    test_nurbs_normal()
    test_nurbs_repr()
    print("All surface tests passed!")
