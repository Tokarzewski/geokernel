from geokernel import FType, Point, Vector3, Line, Face
from geokernel import line_face_intersection, point_in_solid_ray_cast


def assert_true(val: Bool, msg: String) raises:
    if not val:
        raise Error("FAIL: " + msg)
    print("PASS:", msg)


def assert_false(val: Bool, msg: String) raises:
    if val:
        raise Error("FAIL: " + msg)
    print("PASS:", msg)


def assert_close(a: FType, b: FType, msg: String, tol: FType = 1e-9) raises:
    if abs(a - b) > tol:
        raise Error("FAIL: " + msg + " got " + String(a) + " expected " + String(b))
    print("PASS:", msg)


def make_cube_faces() -> List[Face]:
    """Build all 6 faces of the unit cube [0,1]^3 with outward normals."""
    var faces = List[Face]()

    # Bottom face z=0 (normal pointing -Z, vertices CCW from below = CW from above)
    var bottom = List[Point]()
    bottom.append(Point(0, 0, 0))
    bottom.append(Point(1, 0, 0))
    bottom.append(Point(1, 1, 0))
    bottom.append(Point(0, 1, 0))
    faces.append(Face(bottom))

    # Top face z=1 (normal pointing +Z, reversed winding)
    var top = List[Point]()
    top.append(Point(0, 0, 1))
    top.append(Point(0, 1, 1))
    top.append(Point(1, 1, 1))
    top.append(Point(1, 0, 1))
    faces.append(Face(top))

    # Front face y=0 (normal pointing -Y)
    var front = List[Point]()
    front.append(Point(0, 0, 0))
    front.append(Point(0, 0, 1))
    front.append(Point(1, 0, 1))
    front.append(Point(1, 0, 0))
    faces.append(Face(front))

    # Back face y=1 (normal pointing +Y)
    var back = List[Point]()
    back.append(Point(0, 1, 0))
    back.append(Point(1, 1, 0))
    back.append(Point(1, 1, 1))
    back.append(Point(0, 1, 1))
    faces.append(Face(back))

    # Left face x=0 (normal pointing -X)
    var left = List[Point]()
    left.append(Point(0, 0, 0))
    left.append(Point(0, 1, 0))
    left.append(Point(0, 1, 1))
    left.append(Point(0, 0, 1))
    faces.append(Face(left))

    # Right face x=1 (normal pointing +X)
    var right = List[Point]()
    right.append(Point(1, 0, 0))
    right.append(Point(1, 0, 1))
    right.append(Point(1, 1, 1))
    right.append(Point(1, 1, 0))
    faces.append(Face(right))

    return faces.copy()


def main() raises:
    print("=== test_intersection.mojo ===")

    # ------------------------------------------------------------------
    # Build a simple horizontal face: unit square at z=0
    # ------------------------------------------------------------------
    var sq_pts = List[Point]()
    sq_pts.append(Point(0, 0, 0))
    sq_pts.append(Point(1, 0, 0))
    sq_pts.append(Point(1, 1, 0))
    sq_pts.append(Point(0, 1, 0))
    var square_z0 = Face(sq_pts)

    # Test 1: line perpendicular to face, hits center → intersects=True, point correct
    # Line from (0.5, 0.5, -1) to (0.5, 0.5, 1), center of face at z=0
    var line1 = Line(Point(0.5, 0.5, -1.0), Point(0.5, 0.5, 1.0))
    var result1 = line_face_intersection(line1, square_z0)
    assert_true(result1[0], "T1: perpendicular line hits face center — intersects=True")
    assert_close(result1[1].x, 0.5, "T1: hit.x == 0.5")
    assert_close(result1[1].y, 0.5, "T1: hit.y == 0.5")
    assert_close(result1[1].z, 0.0, "T1: hit.z == 0.0")

    # Test 2: line parallel to face (same z = -1) → intersects=False
    var line2 = Line(Point(0.0, 0.0, -1.0), Point(1.0, 1.0, -1.0))
    var result2 = line_face_intersection(line2, square_z0)
    assert_false(result2[0], "T2: parallel line — intersects=False")

    # Test 3: line pointing away from face (both endpoints above z=0) → intersects=False
    # Line from (0.5, 0.5, 0.5) to (0.5, 0.5, 2.0) — goes away from z=0 face
    var line3 = Line(Point(0.5, 0.5, 0.5), Point(0.5, 0.5, 2.0))
    var result3 = line_face_intersection(line3, square_z0)
    assert_false(result3[0], "T3: line pointing away from face — intersects=False")

    # Test 4: line hits face plane but outside polygon → intersects=False
    # Line from (5.0, 5.0, -1.0) to (5.0, 5.0, 1.0) — outside [0,1]^2
    var line4 = Line(Point(5.0, 5.0, -1.0), Point(5.0, 5.0, 1.0))
    var result4 = line_face_intersection(line4, square_z0)
    assert_false(result4[0], "T4: line hits plane but outside face polygon — intersects=False")

    # Test 5: analytical check — line from (0.5,0.5,-2) to (0.5,0.5,4), t=2/6=0.333...
    # intersection at z=0: p = (0.5, 0.5, -2) + 0.333 * (0,0,6) = (0.5, 0.5, 0)
    var line5 = Line(Point(0.5, 0.5, -2.0), Point(0.5, 0.5, 4.0))
    var result5 = line_face_intersection(line5, square_z0)
    assert_true(result5[0], "T5: analytical — long line hits center — intersects=True")
    assert_close(result5[1].z, 0.0, "T5: analytical hit.z == 0.0")

    # ------------------------------------------------------------------
    # point_in_solid_ray_cast tests with unit cube
    # ------------------------------------------------------------------
    var cube_faces = make_cube_faces()

    # Test 6: point inside unit cube → True
    var p_inside = Point(0.5, 0.5, 0.5)
    assert_true(point_in_solid_ray_cast(p_inside, cube_faces), "T6: point (0.5,0.5,0.5) inside cube → True")

    # Test 7: point outside cube (x>1) → False
    var p_outside = Point(2.0, 0.5, 0.5)
    assert_false(point_in_solid_ray_cast(p_outside, cube_faces), "T7: point (2,0.5,0.5) outside cube → False")

    # Test 8: point far above cube → False
    var p_above = Point(0.5, 0.5, 5.0)
    assert_false(point_in_solid_ray_cast(p_above, cube_faces), "T8: point (0.5,0.5,5) above cube → False")

    # Test 9: point below cube → True (ray goes +Z, passes through top and bottom? No — below means it hits both faces)
    # Below z=0: ray from (0.5,0.5,-0.5) in +Z crosses bottom at z=0, then top at z=1 → 2 crossings → outside
    var p_below = Point(0.5, 0.5, -0.5)
    assert_false(point_in_solid_ray_cast(p_below, cube_faces), "T9: point (0.5,0.5,-0.5) below cube → False")

    # Test 10: near cube center but displaced → still inside
    var p_near_center = Point(0.1, 0.1, 0.1)
    assert_true(point_in_solid_ray_cast(p_near_center, cube_faces), "T10: point (0.1,0.1,0.1) near corner still inside → True")

    print("")
    print("All tests passed!")
