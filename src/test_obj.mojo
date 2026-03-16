from std.testing import assert_true, assert_equal
from geokernel import FType, Point, Face
from geokernel import export_obj, import_obj
from geokernel.primitives import box_faces


fn make_triangle() -> List[Face]:
    var p1 = Point(0.0, 0.0, 0.0)
    var p2 = Point(1.0, 0.0, 0.0)
    var p3 = Point(0.0, 1.0, 0.0)
    var pts = List[Point]()
    pts.append(p1)
    pts.append(p2)
    pts.append(p3)
    var faces = List[Face]()
    faces.append(Face(pts))
    return faces^


fn make_square() -> List[Face]:
    var p1 = Point(0.0, 0.0, 0.0)
    var p2 = Point(1.0, 0.0, 0.0)
    var p3 = Point(1.0, 1.0, 0.0)
    var p4 = Point(0.0, 1.0, 0.0)
    var pts = List[Point]()
    pts.append(p1)
    pts.append(p2)
    pts.append(p3)
    pts.append(p4)
    var faces = List[Face]()
    faces.append(Face(pts))
    return faces^


# Test 1: export triangle produces v and f lines
def test_export_contains_v_and_f() raises:
    var faces = make_triangle()
    var obj = export_obj(faces)
    assert_true(obj.find("v ") >= 0)
    assert_true(obj.find("\nf ") >= 0)


# Test 2: round-trip triangle — vertex count preserved
def test_roundtrip_triangle_vertices() raises:
    var faces = make_triangle()
    var obj = export_obj(faces)
    var imported = import_obj(obj)
    assert_equal(len(imported), 1)
    assert_equal(imported[0].num_vertices(), 3)


# Test 3: export unit square has 4 unique vertices
def test_export_square_4_vertices() raises:
    var faces = make_square()
    var obj = export_obj(faces)
    # Count "v " lines
    var v_count = 0
    var lines = obj.splitlines()
    for i in range(len(lines)):
        var line = String(lines[i])
        if line.startswith("v "):
            v_count += 1
    assert_equal(v_count, 4)


# Test 4: import known OBJ string gives correct face count
def test_import_known_obj() raises:
    var known = String(
        "# test\n"
        "v 0.0 0.0 0.0\n"
        "v 1.0 0.0 0.0\n"
        "v 1.0 1.0 0.0\n"
        "v 0.0 1.0 0.0\n"
        "f 1 2 3\n"
        "f 1 3 4\n"
    )
    var imported = import_obj(known)
    assert_equal(len(imported), 2)


# Test 5: round-trip cube (6 faces) preserves face count
def test_roundtrip_cube_6_faces() raises:
    var cube = box_faces(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    var obj = export_obj(cube)
    var imported = import_obj(obj)
    assert_equal(len(imported), 6)


def main() raises:
    test_export_contains_v_and_f()
    print("PASS test_export_contains_v_and_f")

    test_roundtrip_triangle_vertices()
    print("PASS test_roundtrip_triangle_vertices")

    test_export_square_4_vertices()
    print("PASS test_export_square_4_vertices")

    test_import_known_obj()
    print("PASS test_import_known_obj")

    test_roundtrip_cube_6_faces()
    print("PASS test_roundtrip_cube_6_faces")

    print("\nAll 5 tests passed.")
