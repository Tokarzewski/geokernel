from geokernel import FType, Point, Vector3
from geokernel import Circle, NurbsCurve
from math import pi, abs


def main():
    # --- Circle tests ---
    var center = Point(0.0, 0.0, 0.0)
    var normal = Vector3(0.0, 0.0, 1.0)
    var radius: FType = 5.0
    var c = Circle(center, normal, radius)

    # Circumference
    var expected_circ = 2.0 * pi * radius
    var actual_circ = c.length()
    print("Circle circumference:", actual_circ, " expected:", expected_circ)
    if abs(actual_circ - expected_circ) < 1e-10:
        print("PASS: Circle circumference")
    else:
        print("FAIL: Circle circumference")

    # point_at(0) should be on the circle
    var p0 = c.point_at(0.0)
    print("Circle point_at(0):", p0.__repr__())
    var dx = p0.x - center.x
    var dy = p0.y - center.y
    var dz = p0.z - center.z
    var dist = (dx * dx + dy * dy + dz * dz) ** 0.5
    if abs(dist - radius) < 1e-10:
        print("PASS: point_at(0) on circle")
    else:
        print("FAIL: point_at(0) on circle, dist =", dist)

    # point_at(0.5) - half way around
    var p_half = c.point_at(0.5)
    print("Circle point_at(0.5):", p_half.__repr__())
    var dx2 = p_half.x - center.x
    var dy2 = p_half.y - center.y
    var dz2 = p_half.z - center.z
    var dist2 = (dx2 * dx2 + dy2 * dy2 + dz2 * dz2) ** 0.5
    if abs(dist2 - radius) < 1e-10:
        print("PASS: point_at(0.5) on circle")
    else:
        print("FAIL: point_at(0.5) on circle, dist =", dist2)

    # is_closed
    if c.is_closed():
        print("PASS: Circle is_closed")
    else:
        print("FAIL: Circle is_closed")

    # contains_point
    var on_circle = c.point_at(0.25)
    if c.contains_point(on_circle, 1e-8):
        print("PASS: Circle contains_point")
    else:
        print("FAIL: Circle contains_point")

    print("Circle repr:", c.__repr__())

    # --- NurbsCurve tests ---
    # Simple degree-1 polyline (two control points)
    var cps = List[Point]()
    cps.append(Point(0.0, 0.0, 0.0))
    cps.append(Point(1.0, 0.0, 0.0))
    cps.append(Point(2.0, 0.0, 0.0))

    var knots = List[FType]()
    knots.append(0.0)
    knots.append(0.0)
    knots.append(0.5)
    knots.append(1.0)
    knots.append(1.0)

    var weights = List[FType]()
    weights.append(1.0)
    weights.append(1.0)
    weights.append(1.0)

    var nc = NurbsCurve(cps, knots, 1, weights)
    print("NurbsCurve:", nc.__repr__())
    print("NurbsCurve num_control_points:", nc.num_control_points())

    if nc.num_control_points() == 3:
        print("PASS: NurbsCurve num_control_points")
    else:
        print("FAIL: NurbsCurve num_control_points")

    # point_at(0) should be first control point
    var np0 = nc.point_at(0.0)
    print("NurbsCurve point_at(0):", np0.__repr__())
    if abs(np0.x - 0.0) < 1e-8 and abs(np0.y) < 1e-8:
        print("PASS: NurbsCurve point_at(0)")
    else:
        print("FAIL: NurbsCurve point_at(0)")

    # point_at(1) should be last control point
    var np1 = nc.point_at(1.0)
    print("NurbsCurve point_at(1):", np1.__repr__())
    if abs(np1.x - 2.0) < 1e-8 and abs(np1.y) < 1e-8:
        print("PASS: NurbsCurve point_at(1)")
    else:
        print("FAIL: NurbsCurve point_at(1)")

    # length ~ 2.0 for line from (0,0,0) to (2,0,0)
    var nc_len = nc.length()
    print("NurbsCurve length:", nc_len, " expected ~2.0")
    if abs(nc_len - 2.0) < 0.01:
        print("PASS: NurbsCurve length")
    else:
        print("FAIL: NurbsCurve length")

    # is_closed = False for this curve
    if not nc.is_closed():
        print("PASS: NurbsCurve is_closed=False")
    else:
        print("FAIL: NurbsCurve is_closed=False")

    print("All tests done.")
