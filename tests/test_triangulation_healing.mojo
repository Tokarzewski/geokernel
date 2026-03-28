"""Tests for triangulation and healing functions."""
from geokernel import FType, Point, Vector3, Face, Shell
from geokernel.triangulation import triangulate_face_ear_clipping, triangulate_shell, Triangulation
from geokernel.healing import merge_coincident_vertices, remove_degenerate_edges, fix_face_normals
from geokernel.primitives import box_faces
from std.testing import assert_true
import std.math as math

fn approx(a: FType, b: FType, tol: FType = 1e-6) -> Bool:
    if a > b: return (a - b) < tol
    return (b - a) < tol

def test_triangulate_triangle() raises:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(1.0, 0.0, 0.0)); pts.append(Point(0.0, 1.0, 0.0))
    var f = Face(pts)
    var tris = Triangulation.triangulate_face(f)
    assert_true(len(tris) == 1, "triangle → 1 tri")
    print("  triangulate_triangle: PASS")

def test_triangulate_quad() raises:
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(1.0, 1.0, 0.0)); pts.append(Point(0.0, 1.0, 0.0))
    var f = Face(pts)
    var tris = Triangulation.triangulate_face(f)
    assert_true(len(tris) == 2, "quad → 2 tris")
    # Total area should equal original
    var total: FType = 0.0
    for i in range(len(tris)): total += tris[i].area()
    assert_true(approx(total, 1.0, 0.01), "tri area sum = quad area")
    print("  triangulate_quad: PASS")

def test_triangulate_concave_l() raises:
    # L-shape (concave)
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(2.0, 0.0, 0.0))
    pts.append(Point(2.0, 1.0, 0.0)); pts.append(Point(1.0, 1.0, 0.0))
    pts.append(Point(1.0, 2.0, 0.0)); pts.append(Point(0.0, 2.0, 0.0))
    var f = Face(pts)
    var tris = triangulate_face_ear_clipping(f)
    assert_true(len(tris) == 4, "L-shape → 4 tris, got " + String(len(tris)))
    var total: FType = 0.0
    for i in range(len(tris)): total += tris[i].area()
    assert_true(approx(total, 3.0, 0.1), "L area = 3.0, got " + String(total))
    print("  triangulate_concave_l: PASS")

def test_triangulate_shell() raises:
    var faces = box_faces(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    var shell = Shell(faces)
    var tri_shell = triangulate_shell(shell)
    # Each quad face → 2 triangles; 6 faces → 12 triangles
    assert_true(len(tri_shell.faces) == 12, "box shell → 12 tris, got " + String(len(tri_shell.faces)))
    print("  triangulate_shell: PASS")

def test_merge_coincident() raises:
    # Two faces sharing an edge but with slightly offset vertices
    var f1_pts = List[Point]()
    f1_pts.append(Point(0.0, 0.0, 0.0)); f1_pts.append(Point(1.0, 0.0, 0.0))
    f1_pts.append(Point(1.0, 1.0, 0.0)); f1_pts.append(Point(0.0, 1.0, 0.0))
    var f2_pts = List[Point]()
    f2_pts.append(Point(1.0001, 0.0, 0.0)); f2_pts.append(Point(2.0, 0.0, 0.0))
    f2_pts.append(Point(2.0, 1.0, 0.0)); f2_pts.append(Point(1.0001, 1.0, 0.0))
    var faces = List[Face]()
    faces.append(Face(f1_pts)); faces.append(Face(f2_pts))
    var shell = Shell(faces)
    var healed = merge_coincident_vertices(shell, tol=0.001)
    assert_true(len(healed.faces) == 2, "still 2 faces after merge")
    print("  merge_coincident: PASS")

def test_remove_degenerate() raises:
    # Face with a zero-length edge
    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0)); pts.append(Point(0.0, 0.0, 0.0))  # degenerate
    pts.append(Point(1.0, 0.0, 0.0)); pts.append(Point(0.0, 1.0, 0.0))
    var faces = List[Face]()
    faces.append(Face(pts))
    var shell = Shell(faces)
    var healed = remove_degenerate_edges(shell, tol=1e-6)
    assert_true(len(healed.faces) == 0, "degenerate face removed")
    print("  remove_degenerate: PASS")

def test_fix_normals() raises:
    var faces = box_faces(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    # Reverse one face's winding
    var modified_faces = List[Face]()
    for i in range(len(faces)):
        if i == 0:
            modified_faces.append(faces[i].reverse())
        else:
            modified_faces.append(faces[i])
    var shell = Shell(modified_faces)
    var fixed = fix_face_normals(shell)
    assert_true(len(fixed.faces) == 6, "still 6 faces")
    print("  fix_normals: PASS")

def main() raises:
    print("=== Triangulation + Healing Tests ===")
    test_triangulate_triangle()
    test_triangulate_quad()
    test_triangulate_concave_l()
    test_triangulate_shell()
    test_merge_coincident()
    test_remove_degenerate()
    test_fix_normals()
    print("=== ALL PASSED ===")
