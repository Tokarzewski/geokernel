from std.testing import assert_true, assert_equal
from geokernel import FType, Point, Face, Plane, Vector3
from geokernel.slice import FacePair, classify_point, slice_face_by_plane, slice_faces_by_plane
from math import abs


def unit_cube_faces() -> List[Face]:
    """Build a unit cube [0,1]^3 as 6 faces.
    Replicates Cell.from_two_points(Point(0,0,0), Point(1,1,1)) inline
    because Cell.from_two_points has a Mojo version issue.
    """
    var p1 = Point(0.0, 0.0, 0.0)
    var p2 = Point(0.0, 1.0, 0.0)
    var p3 = Point(1.0, 1.0, 0.0)
    var p4 = Point(1.0, 0.0, 0.0)
    var p5 = Point(0.0, 0.0, 1.0)
    var p6 = Point(0.0, 1.0, 1.0)
    var p7 = Point(1.0, 1.0, 1.0)
    var p8 = Point(1.0, 0.0, 1.0)

    var faces = List[Face]()

    var r = List[Point]()
    r.append(p3); r.append(p7); r.append(p8); r.append(p4)
    faces.append(Face(r))   # Right (+X)

    var l = List[Point]()
    l.append(p1); l.append(p5); l.append(p6); l.append(p2)
    faces.append(Face(l))   # Left (-X)

    var bk = List[Point]()
    bk.append(p2); bk.append(p6); bk.append(p7); bk.append(p3)
    faces.append(Face(bk))  # Back (+Y)

    var fr = List[Point]()
    fr.append(p1); fr.append(p4); fr.append(p8); fr.append(p5)
    faces.append(Face(fr))  # Front (-Y)

    var bot = List[Point]()
    bot.append(p1); bot.append(p2); bot.append(p3); bot.append(p4)
    faces.append(Face(bot)) # Bottom (-Z)

    var top = List[Point]()
    top.append(p5); top.append(p8); top.append(p7); top.append(p6)
    faces.append(Face(top)) # Top (+Z)

    return faces^


# ─── Test 1: classify_point ──────────────────────────────────────────────────

def test_classify_above() raises:
    """Point above z=0 plane → +1."""
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var p = Point(0.0, 0.0, 1.0)
    assert_equal(classify_point(p, plane), 1)

def test_classify_below() raises:
    """Point below z=0 plane → -1."""
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var p = Point(0.0, 0.0, -1.0)
    assert_equal(classify_point(p, plane), -1)

def test_classify_on_plane() raises:
    """Point exactly on z=0 plane → 0."""
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var p = Point(1.0, 2.0, 0.0)
    assert_equal(classify_point(p, plane), 0)

def test_classify_y_plane_above() raises:
    """Point above y=0.5 plane → +1."""
    var plane = Plane(Point(0.0, 0.5, 0.0), Vector3(0.0, 1.0, 0.0))
    var p = Point(0.0, 1.0, 0.0)
    assert_equal(classify_point(p, plane), 1)

def test_classify_y_plane_below() raises:
    """Point below y=0.5 plane → -1."""
    var plane = Plane(Point(0.0, 0.5, 0.0), Vector3(0.0, 1.0, 0.0))
    var p = Point(0.0, 0.0, 0.0)
    assert_equal(classify_point(p, plane), -1)


# ─── Test 2: all-above face stays above ──────────────────────────────────────

def test_all_above_face() raises:
    """Face entirely above z=0 plane → above list only, below empty."""
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 1.0))
    pts.append(Point(1.0, 0.0, 1.0))
    pts.append(Point(1.0, 1.0, 1.0))
    pts.append(Point(0.0, 1.0, 1.0))
    var face = Face(pts)
    var result = slice_face_by_plane(face, plane)
    assert_equal(len(result.above), 1)
    assert_equal(len(result.below), 0)


# ─── Test 3: all-below face stays below ──────────────────────────────────────

def test_all_below_face() raises:
    """Face entirely below z=0 plane → below list only, above empty."""
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, -1.0))
    pts.append(Point(1.0, 0.0, -1.0))
    pts.append(Point(1.0, 1.0, -1.0))
    pts.append(Point(0.0, 1.0, -1.0))
    var face = Face(pts)
    var result = slice_face_by_plane(face, plane)
    assert_equal(len(result.above), 0)
    assert_equal(len(result.below), 1)


# ─── Test 4: unit square sliced at y=0.5 ─────────────────────────────────────

def test_square_sliced_at_midplane() raises:
    """Unit square (z=0, y in [0,1]) sliced by y=0.5 plane.
    Analytical: each half area = 0.5.
    Above half: y in [0.5, 1.0], area = 1.0 * 0.5 = 0.5.
    Below half: y in [0.0, 0.5], area = 1.0 * 0.5 = 0.5.
    """
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(1.0, 1.0, 0.0))
    pts.append(Point(0.0, 1.0, 0.0))
    var face = Face(pts)

    var plane = Plane(Point(0.0, 0.5, 0.0), Vector3(0.0, 1.0, 0.0))

    var result = slice_face_by_plane(face, plane)

    assert_equal(len(result.above), 1)
    assert_equal(len(result.below), 1)

    var area_above = result.above[0].area()
    var area_below = result.below[0].area()

    # Analytical check: each half should be 0.5 within 1e-10
    assert_true(abs(area_above - 0.5) < 1e-10)
    assert_true(abs(area_below - 0.5) < 1e-10)


# ─── Test 5: unit cube sliced at z=0.5 ───────────────────────────────────────

def test_unit_cube_sliced_at_z05() raises:
    """Unit cube (6 faces) sliced by z=0.5 plane.
    Above: top face (1) + 4 upper half-side-faces (0.5 each) = area 3.0.
    Below: bottom face (1) + 4 lower half-side-faces (0.5 each) = area 3.0.
    Each side has at least 5 faces.
    """
    var cube_faces = unit_cube_faces()
    var plane = Plane(Point(0.0, 0.0, 0.5), Vector3(0.0, 0.0, 1.0))

    var result = slice_faces_by_plane(cube_faces, plane)

    assert_true(len(result.above) >= 5)
    assert_true(len(result.below) >= 5)

    var area_above: FType = 0.0
    for i in range(len(result.above)):
        area_above += result.above[i].area()
    var area_below: FType = 0.0
    for i in range(len(result.below)):
        area_below += result.below[i].area()

    # 4 side half-faces (0.5 each) + 1 top/bottom face (1.0) = 3.0
    assert_true(abs(area_above - 3.0) < 1e-9)
    assert_true(abs(area_below - 3.0) < 1e-9)


# ─── Test 6: slice_faces_by_plane with separated faces ───────────────────────

def test_slice_faces_mixed() raises:
    """Two faces: one above plane, one below. Each stays on its side."""
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))

    var pts_above = List[Point]()
    pts_above.append(Point(0.0, 0.0, 1.0))
    pts_above.append(Point(1.0, 0.0, 1.0))
    pts_above.append(Point(1.0, 1.0, 1.0))
    var f_above = Face(pts_above)

    var pts_below = List[Point]()
    pts_below.append(Point(0.0, 0.0, -1.0))
    pts_below.append(Point(1.0, 0.0, -1.0))
    pts_below.append(Point(1.0, 1.0, -1.0))
    var f_below = Face(pts_below)

    var faces = List[Face]()
    faces.append(f_above)
    faces.append(f_below)

    var result = slice_faces_by_plane(faces, plane)
    assert_equal(len(result.above), 1)
    assert_equal(len(result.below), 1)


# ─── Test 7: triangle sliced diagonally ──────────────────────────────────────

def test_triangle_sliced_at_midpoint() raises:
    """Triangle (0,0,0)-(2,0,0)-(1,2,0) sliced by y=1 plane.
    Analytical area of original triangle = 0.5 * base * height = 0.5 * 2 * 2 = 2.0.
    The slice at y=1 cuts the triangle at two edge midpoints.
    Above piece: smaller triangle with base=1, height=1 → area=0.5.
    Below piece: trapezoid with area = 2.0 - 0.5 = 1.5.
    """
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(2.0, 0.0, 0.0))
    pts.append(Point(1.0, 2.0, 0.0))
    var face = Face(pts)

    var plane = Plane(Point(0.0, 1.0, 0.0), Vector3(0.0, 1.0, 0.0))
    var result = slice_face_by_plane(face, plane)

    assert_equal(len(result.above), 1)
    assert_equal(len(result.below), 1)

    # Analytical checks
    assert_true(abs(result.above[0].area() - 0.5) < 1e-9)
    assert_true(abs(result.below[0].area() - 1.5) < 1e-9)


# ─── Test 8: face on the plane itself ────────────────────────────────────────

def test_face_on_plane() raises:
    """Face that lies exactly on the plane → goes to above (or on-plane) bucket."""
    var plane = Plane(Point(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(1.0, 1.0, 0.0))
    pts.append(Point(0.0, 1.0, 0.0))
    var face = Face(pts)
    var result = slice_face_by_plane(face, plane)
    # All-on-plane: classify=0 → not has_above, not has_below → goes to above list
    assert_equal(len(result.above), 1)
    assert_equal(len(result.below), 0)


def main() raises:
    test_classify_above()
    print("PASS: classify_point above -> +1")

    test_classify_below()
    print("PASS: classify_point below -> -1")

    test_classify_on_plane()
    print("PASS: classify_point on plane -> 0")

    test_classify_y_plane_above()
    print("PASS: classify_point y-plane above -> +1")

    test_classify_y_plane_below()
    print("PASS: classify_point y-plane below -> -1")

    test_all_above_face()
    print("PASS: all-above face -> above only")

    test_all_below_face()
    print("PASS: all-below face -> below only")

    test_square_sliced_at_midplane()
    print("PASS: unit square sliced at y=0.5 — area_above=0.5, area_below=0.5")

    test_unit_cube_sliced_at_z05()
    print("PASS: unit cube sliced at z=0.5 — 5+ faces each side, area=3.0 each")

    test_slice_faces_mixed()
    print("PASS: slice_faces_by_plane mixed -> 1 above, 1 below")

    test_triangle_sliced_at_midpoint()
    print("PASS: triangle sliced at y=1 — above area=0.5, below area=1.5")

    test_face_on_plane()
    print("PASS: face on plane -> above only (0 side)")

    print("\nAll 12 tests passed.")
