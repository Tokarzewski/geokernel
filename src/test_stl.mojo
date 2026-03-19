from std.testing import assert_true, assert_equal
from geokernel import FType, Point, Face
from geokernel.stl import export_stl_ascii, import_stl_ascii


def test_export_contains_keywords() raises:
    """Export triangle → ASCII STL contains solid, facet normal, vertex, endsolid."""
    var pts = List[Point]()
    pts.append(Point(0, 0, 0))
    pts.append(Point(1, 0, 0))
    pts.append(Point(0, 1, 0))
    var faces = List[Face]()
    faces.append(Face(pts))

    var stl = export_stl_ascii(faces)
    assert_true(stl.find("solid") >= 0)
    assert_true(stl.find("facet normal") >= 0)
    assert_true(stl.find("vertex") >= 0)
    assert_true(stl.find("endsolid") >= 0)


def test_roundtrip_triangle() raises:
    """Round-trip: triangle → STL → import → 1 face, 3 vertices."""
    var pts = List[Point]()
    pts.append(Point(0, 0, 0))
    pts.append(Point(1, 0, 0))
    pts.append(Point(0, 1, 0))
    var faces = List[Face]()
    faces.append(Face(pts))

    var stl = export_stl_ascii(faces)
    var imported = import_stl_ascii(stl)

    assert_equal(len(imported), 1)
    assert_equal(imported[0].num_vertices(), 3)


def test_export_square_fan_triangulation() raises:
    """Export square (4 vertices) → 2 triangles in output."""
    var pts = List[Point]()
    pts.append(Point(0, 0, 0))
    pts.append(Point(1, 0, 0))
    pts.append(Point(1, 1, 0))
    pts.append(Point(0, 1, 0))
    var faces = List[Face]()
    faces.append(Face(pts))

    var stl = export_stl_ascii(faces)
    # Count "facet normal" occurrences = number of triangles
    var count = 0
    var pos = 0
    while True:
        var found = stl.find("facet normal", pos)
        if found < 0:
            break
        count += 1
        pos = found + 1
    assert_equal(count, 2)


def test_import_known_stl() raises:
    """Import known STL string → correct face count."""
    var stl = String(
        "solid test\n"
        "  facet normal 0.0 0.0 1.0\n"
        "    outer loop\n"
        "      vertex 0.0 0.0 0.0\n"
        "      vertex 1.0 0.0 0.0\n"
        "      vertex 0.0 1.0 0.0\n"
        "    endloop\n"
        "  endfacet\n"
        "  facet normal 0.0 0.0 1.0\n"
        "    outer loop\n"
        "      vertex 1.0 0.0 0.0\n"
        "      vertex 1.0 1.0 0.0\n"
        "      vertex 0.0 1.0 0.0\n"
        "    endloop\n"
        "  endfacet\n"
        "endsolid test\n"
    )
    var faces = import_stl_ascii(stl)
    assert_equal(len(faces), 2)


def test_normal_nonzero() raises:
    """Normal in exported STL is non-zero for non-degenerate triangle."""
    var pts = List[Point]()
    pts.append(Point(0, 0, 0))
    pts.append(Point(1, 0, 0))
    pts.append(Point(0, 1, 0))
    var faces = List[Face]()
    faces.append(Face(pts))

    var stl = export_stl_ascii(faces)
    # The normal line should not be "facet normal 0.0 0.0 0.0"
    var has_zero_normal = stl.find("facet normal 0.0 0.0 0.0") >= 0
    assert_true(not has_zero_normal)


def main() raises:
    test_export_contains_keywords()
    print("PASS test_export_contains_keywords")

    test_roundtrip_triangle()
    print("PASS test_roundtrip_triangle")

    test_export_square_fan_triangulation()
    print("PASS test_export_square_fan_triangulation")

    test_import_known_stl()
    print("PASS test_import_known_stl")

    test_normal_nonzero()
    print("PASS test_normal_nonzero")

    print("All 5 tests passed!")
