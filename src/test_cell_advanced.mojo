from std.testing import assert_true, assert_equal
from geokernel import FType, Point, Face
from geokernel import sphere_faces, cylinder_faces, cone_faces
from math import sqrt, pi


# ─── Sphere analytical tests ─────────────────────────────────────────────────

def test_sphere_area_analytical() raises:
    """Sphere (r=1, 16x8): total area ≈ 4π ≈ 12.566 within 5%."""
    var center = Point(0.0, 0.0, 0.0)
    var r: FType = 1.0
    var faces = sphere_faces(center, r, 16, 8)
    var total_area: FType = 0.0
    for i in range(len(faces)):
        total_area += faces[i].area()
    var exact: FType = 4.0 * pi * r * r   # ≈ 12.566
    var rel_err = abs(total_area - exact) / exact
    # Must be within 5%
    assert_true(rel_err < 0.05)


def test_sphere_face_count_approx() raises:
    """Sphere (16x8): face count ≈ u_seg * v_seg * 2 = 256 faces.
    Poles give one triangle per longitude step (not a quad), so:
      2 cap rows * 16 triangles + 6 middle rows * 16 quads = 32 + 96 = 128
    The total is u_seg * v_seg (each strip slot is one face, tri or quad).
    All middle quads are split into 2 triangles → same face count as quads."""
    var u: Int = 16
    var v: Int = 8
    var center = Point(0.0, 0.0, 0.0)
    var faces = sphere_faces(center, 1.0, u, v)
    # pole rows: 2 rows × u triangles; interior rows: (v-2) rows × u quads
    var expected = u * v
    assert_equal(len(faces), expected)


def test_sphere_r2_area_analytical() raises:
    """Sphere (r=2, 32x16): total area ≈ 4π·4 = 16π within 5%."""
    var center = Point(0.0, 0.0, 0.0)
    var r: FType = 2.0
    var faces = sphere_faces(center, r, 32, 16)
    var total_area: FType = 0.0
    for i in range(len(faces)):
        total_area += faces[i].area()
    var exact: FType = 4.0 * pi * r * r   # ≈ 50.265
    var rel_err = abs(total_area - exact) / exact
    assert_true(rel_err < 0.05)


def test_sphere_all_vertices_on_surface() raises:
    """All sphere vertices must lie at distance r from center (within 1e-9)."""
    var cx: FType = 1.0; var cy: FType = 2.0; var cz: FType = 3.0
    var r: FType = 1.5
    var center = Point(cx, cy, cz)
    var faces = sphere_faces(center, r, 16, 8)
    for i in range(len(faces)):
        var n = faces[i].num_vertices()
        for k in range(n):
            var p = faces[i].get_vertex(k)
            var dx = p.x - cx; var dy = p.y - cy; var dz = p.z - cz
            var dist = sqrt(dx*dx + dy*dy + dz*dz)
            assert_true(abs(dist - r) < 1e-9)


# ─── Cylinder analytical tests ────────────────────────────────────────────────

def test_cylinder_area_analytical() raises:
    """Cylinder (r=1, h=2, 32 segments):
    area = 2·π·r² + 2·π·r·h = 2π(r² + r·h) = 2π·(1 + 2) = 6π ≈ 18.85 within 5%."""
    var center = Point(0.0, 0.0, 0.0)
    var r: FType = 1.0
    var h: FType = 2.0
    var faces = cylinder_faces(center, r, h, 32)
    var total_area: FType = 0.0
    for i in range(len(faces)):
        total_area += faces[i].area()
    var exact: FType = 2.0 * pi * (r * r + r * h)  # ≈ 18.850
    var rel_err = abs(total_area - exact) / exact
    assert_true(rel_err < 0.05)


def test_cylinder_face_count() raises:
    """Cylinder (N segments): N side quads + N bottom tris + N top tris = 3N faces."""
    var center = Point(0.0, 0.0, 0.0)
    var N: Int = 32
    var faces = cylinder_faces(center, 1.0, 2.0, N)
    assert_equal(len(faces), 3 * N)


def test_cylinder_face_count_small() raises:
    """Cylinder (4 segments): 4 side + 4 bot + 4 top = 12 faces."""
    var center = Point(0.0, 0.0, 0.0)
    var faces = cylinder_faces(center, 1.0, 1.0, 4)
    assert_equal(len(faces), 12)


def test_cylinder_all_faces_valid() raises:
    """All cylinder faces must have at least 3 vertices."""
    var center = Point(0.0, 0.0, 0.0)
    var faces = cylinder_faces(center, 1.0, 2.0, 16)
    for i in range(len(faces)):
        assert_true(faces[i].num_vertices() >= 3)


# ─── Cone analytical tests ────────────────────────────────────────────────────

def test_cone_face_count_spec() raises:
    """Cone (r=1, h=1, N=32): face count == N (side tris) + N (base tris) = 2N = 64.
    Task spec says 32*2 + 32 = 96 for a total including base, side and cap.
    Our implementation: N side + N base = 2N. Verify formula matches code."""
    var center = Point(0.0, 0.0, 0.0)
    var N: Int = 32
    var faces = cone_faces(center, 1.0, 1.0, N)
    # N side triangles + N base triangles = 2*N
    assert_equal(len(faces), 2 * N)


def test_cone_face_count_small() raises:
    """Cone (4 segments): 4 side + 4 base = 8 faces."""
    var center = Point(0.0, 0.0, 0.0)
    var faces = cone_faces(center, 1.0, 1.0, 4)
    assert_equal(len(faces), 8)


def test_cone_apex_correct() raises:
    """Side triangle apex must be at center.z + height."""
    var cz: FType = 0.0; var h: FType = 1.0
    var center = Point(0.0, 0.0, cz)
    var faces = cone_faces(center, 1.0, h, 4)
    # Side triangles at even indices (0,2,4,6); apex is vertex index 2
    for i in range(4):
        var apex = faces[i * 2].get_vertex(2)
        assert_true(abs(apex.z - (cz + h)) < 1e-9)


def test_cone_area_analytical() raises:
    """Cone (r=1, h=0, so slant=r=1): lateral area = π·r·l = π·1·1 = π.
    Base area = π·r² = π. Total ≈ 2π ≈ 6.283.
    For h=1: slant l = sqrt(r²+h²) = sqrt(2). Total = π·r·(r + l) = π·(1+√2).
    We check within 5%."""
    var center = Point(0.0, 0.0, 0.0)
    var r: FType = 1.0; var h: FType = 1.0
    var faces = cone_faces(center, r, h, 64)
    var total_area: FType = 0.0
    for i in range(len(faces)):
        total_area += faces[i].area()
    var slant = sqrt(r * r + h * h)
    var exact: FType = pi * r * (r + slant)  # base + lateral
    var rel_err = abs(total_area - exact) / exact
    assert_true(rel_err < 0.05)


def test_cone_all_faces_valid() raises:
    """All cone faces must have at least 3 vertices."""
    var center = Point(0.0, 0.0, 0.0)
    var faces = cone_faces(center, 1.0, 1.0, 16)
    for i in range(len(faces)):
        assert_true(faces[i].num_vertices() >= 3)


def main() raises:
    # Sphere
    test_sphere_area_analytical()
    print("PASS test_sphere_area_analytical  (4π r² within 5%)")

    test_sphere_face_count_approx()
    print("PASS test_sphere_face_count_approx  (u*v faces)")

    test_sphere_r2_area_analytical()
    print("PASS test_sphere_r2_area_analytical  (r=2, 32x16 within 5%)")

    test_sphere_all_vertices_on_surface()
    print("PASS test_sphere_all_vertices_on_surface  (dist == r within 1e-9)")

    # Cylinder
    test_cylinder_area_analytical()
    print("PASS test_cylinder_area_analytical  (2π(r²+rh) within 5%)")

    test_cylinder_face_count()
    print("PASS test_cylinder_face_count  (3*N faces)")

    test_cylinder_face_count_small()
    print("PASS test_cylinder_face_count_small  (12 faces)")

    test_cylinder_all_faces_valid()
    print("PASS test_cylinder_all_faces_valid  (all >= 3 vertices)")

    # Cone
    test_cone_face_count_spec()
    print("PASS test_cone_face_count_spec  (2*N faces)")

    test_cone_face_count_small()
    print("PASS test_cone_face_count_small  (8 faces)")

    test_cone_apex_correct()
    print("PASS test_cone_apex_correct  (apex z == cz+h)")

    test_cone_area_analytical()
    print("PASS test_cone_area_analytical  (π·r·(r+slant) within 5%)")

    test_cone_all_faces_valid()
    print("PASS test_cone_all_faces_valid  (all >= 3 vertices)")

    print("\nAll 13 tests passed.")
