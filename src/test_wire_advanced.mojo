"""test_wire_advanced.mojo — analytical validation of Wire improvements.

Tests (Euclid-style: value checks, not just "it ran"):
  1. is_planar: planar wire (z=0) → True
  2. is_planar: non-planar wire (one point off-plane) → False
  3. bounding_box: unit square → min=(0,0,0), max=(1,1,0)
  4. length: 3-4-5 triangle → 12.0 exactly (within 1e-10)
  5. is_closed: closed square → True; open line → False
  6. remove_collinear_points: 3 collinear pts → 2 pts remain
  7. All numerical results within 1e-10 tolerance
"""
from geokernel import Point, Wire, Vector3
from math import sqrt, abs


fn assert_true(cond: Bool, name: String):
    if cond:
        print("  PASS:", name)
    else:
        print("  FAIL:", name)


fn assert_close(val: Float64, expected: Float64, atol: Float64, name: String):
    if abs(val - expected) <= atol:
        print("  PASS:", name, "=", val)
    else:
        print("  FAIL:", name, "expected", expected, "got", val, "diff", abs(val - expected))


fn assert_equal(val: Int, expected: Int, name: String):
    if val == expected:
        print("  PASS:", name, "=", val)
    else:
        print("  FAIL:", name, "expected", expected, "got", val)


fn main():
    print("=== test_wire_advanced ===")
    var atol: Float64 = 1e-10

    # ── Test 1: is_planar — all z=0 → True ──────────────────────────────────
    print("\n[1] is_planar: planar wire (z=0)")
    var planar_pts = List[Point]()
    planar_pts.append(Point(0.0, 0.0, 0.0))
    planar_pts.append(Point(1.0, 0.0, 0.0))
    planar_pts.append(Point(1.0, 1.0, 0.0))
    planar_pts.append(Point(0.0, 1.0, 0.0))
    var planar_wire = Wire(planar_pts)
    assert_true(planar_wire.is_planar(), "planar_wire.is_planar() == True")

    # ── Test 2: is_planar — one point off-plane → False ─────────────────────
    print("\n[2] is_planar: non-planar wire")
    var nonplanar_pts = List[Point]()
    nonplanar_pts.append(Point(0.0, 0.0, 0.0))
    nonplanar_pts.append(Point(1.0, 0.0, 0.0))
    nonplanar_pts.append(Point(1.0, 1.0, 0.0))
    nonplanar_pts.append(Point(0.5, 0.5, 1.0))   # off-plane: z=1
    var nonplanar_wire = Wire(nonplanar_pts)
    assert_true(not nonplanar_wire.is_planar(), "nonplanar_wire.is_planar() == False")

    # ── Test 3: bounding_box — unit square ───────────────────────────────────
    print("\n[3] bounding_box: unit square")
    # planar_wire already is the unit square
    var bb = planar_wire.bounding_box()
    assert_close(bb.p_min.x, 0.0, atol, "bb.p_min.x")
    assert_close(bb.p_min.y, 0.0, atol, "bb.p_min.y")
    assert_close(bb.p_min.z, 0.0, atol, "bb.p_min.z")
    assert_close(bb.p_max.x, 1.0, atol, "bb.p_max.x")
    assert_close(bb.p_max.y, 1.0, atol, "bb.p_max.y")
    assert_close(bb.p_max.z, 0.0, atol, "bb.p_max.z")

    # ── Test 4: length — 3-4-5 triangle: total = 12.0 ────────────────────────
    # Analytical: 3 + 4 + 5 = 12
    print("\n[4] length: 3-4-5 triangle")
    var tri_pts = List[Point]()
    tri_pts.append(Point(0.0, 0.0, 0.0))
    tri_pts.append(Point(3.0, 0.0, 0.0))   # side = 3
    tri_pts.append(Point(3.0, 4.0, 0.0))   # side = 4
    tri_pts.append(Point(0.0, 0.0, 0.0))   # hypotenuse = 5, closes back
    var tri_wire = Wire(tri_pts)
    assert_close(tri_wire.length(), 12.0, atol, "tri_wire.length()")

    # ── Test 5: is_closed ─────────────────────────────────────────────────────
    print("\n[5] is_closed")
    # Closed square: first == last
    var sq_pts = List[Point]()
    sq_pts.append(Point(0.0, 0.0, 0.0))
    sq_pts.append(Point(1.0, 0.0, 0.0))
    sq_pts.append(Point(1.0, 1.0, 0.0))
    sq_pts.append(Point(0.0, 0.0, 0.0))   # back to start
    var closed_wire = Wire(sq_pts)
    assert_true(closed_wire.is_closed(), "closed_wire.is_closed() == True")

    # Open line: different endpoints
    var open_pts = List[Point]()
    open_pts.append(Point(0.0, 0.0, 0.0))
    open_pts.append(Point(1.0, 0.0, 0.0))
    open_pts.append(Point(2.0, 0.0, 0.0))
    var open_wire = Wire(open_pts)
    assert_true(not open_wire.is_closed(), "open_wire.is_closed() == False")

    # ── Test 6: remove_collinear_points — 3 collinear → 2 remain ─────────────
    # Points A, B, C all on x-axis; B is intermediate and collinear → removed
    # Result: just A and C (2 points)
    print("\n[6] remove_collinear_points")
    var col_pts = List[Point]()
    col_pts.append(Point(0.0, 0.0, 0.0))
    col_pts.append(Point(1.0, 0.0, 0.0))   # collinear intermediate
    col_pts.append(Point(2.0, 0.0, 0.0))
    var col_wire = Wire(col_pts)
    var simplified = col_wire.remove_collinear_points()
    assert_equal(simplified.num_points(), 2, "simplified.num_points()")
    # Endpoints should be preserved
    assert_close(simplified.get_point(0).x, 0.0, atol, "simplified[0].x")
    assert_close(simplified.get_point(1).x, 2.0, atol, "simplified[1].x")

    # ── Test 7: edge case — is_planar with < 3 points ─────────────────────────
    print("\n[7] is_planar edge cases")
    var two_pts = List[Point]()
    two_pts.append(Point(0.0, 0.0, 0.0))
    two_pts.append(Point(1.0, 0.0, 0.0))
    var two_wire = Wire(two_pts)
    assert_true(two_wire.is_planar(), "2-point wire.is_planar() == True (trivial)")

    print("\n=== done ===")
