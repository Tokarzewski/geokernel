"""Tests for STEP, OBJ, and STL export/import."""
from geokernel import FType, Point, Face, Shell
from geokernel.primitives import box_faces
from geokernel.step import export_step
from geokernel.obj import export_obj, import_obj
from geokernel.stl import export_stl_ascii, import_stl_ascii
from std.testing import assert_true

def test_step_export() raises:
    var faces = box_faces(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    var shell = Shell(faces)
    var step = export_step(shell, "test")
    assert_true("ISO-10303-21" in step, "STEP header")
    assert_true("CARTESIAN_POINT" in step, "has points")
    assert_true("ADVANCED_FACE" in step, "has faces")
    assert_true("CLOSED_SHELL" in step, "has shell")
    assert_true("MANIFOLD_SOLID_BREP" in step, "has brep")
    assert_true("END-ISO-10303-21" in step, "STEP footer")
    print("  step_export: PASS")

def test_obj_roundtrip() raises:
    var faces = box_faces(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    var obj = export_obj(faces)
    assert_true("v " in obj, "OBJ has vertices")
    assert_true("f " in obj, "OBJ has faces")
    var imported = import_obj(obj)
    assert_true(len(imported) == 6, "imported 6 faces, got " + String(len(imported)))
    print("  obj_roundtrip: PASS")

def test_stl_roundtrip() raises:
    var faces = box_faces(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    var stl = export_stl_ascii(faces)
    assert_true("solid" in stl, "STL has solid")
    assert_true("facet normal" in stl, "STL has normals")
    var imported = import_stl_ascii(stl)
    assert_true(len(imported) > 0, "imported STL faces")
    print("  stl_roundtrip: PASS")

def main() raises:
    print("=== Export/Import Tests ===")
    test_step_export()
    test_obj_roundtrip()
    test_stl_roundtrip()
    print("=== ALL PASSED ===")
