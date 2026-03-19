from std.testing import assert_true, assert_equal
from geokernel import FType, Point, Face
from geokernel import sphere_faces, cylinder_faces, cone_faces
from math import sqrt, pi


def test_sphere_face_count() raises:
    # u_segments=8, v_segments=6:
    # top cap: 8 triangles, bottom cap: 8 triangles, middle: 4 rows * 8 quads = 32 → total 48
    var center = Point(0.0, 0.0, 0.0)
    var faces = sphere_faces(center, 1.0, 8, 6)
    assert_true(len(faces) > 30)


def test_sphere_all_faces_min_3_vertices() raises:
    var center = Point(0.0, 0.0, 0.0)
    var faces = sphere_faces(center, 1.0, 8, 6)
    for i in range(len(faces)):
        assert_true(faces[i].num_vertices() >= 3)


def test_sphere_vertices_on_surface() raises:
    # All vertices of a unit sphere centered at (1,2,3) must lie exactly r from center.
    var cx: FType = 1.0
    var cy: FType = 2.0
    var cz: FType = 3.0
    var r: FType = 2.5
    var center = Point(cx, cy, cz)
    var faces = sphere_faces(center, r, 8, 6)
    var tol: FType = 1e-9
    for i in range(len(faces)):
        var n = faces[i].num_vertices()
        for k in range(n):
            var p = faces[i].get_vertex(k)
            var dx = p.x - cx
            var dy = p.y - cy
            var dz = p.z - cz
            var dist = sqrt(dx*dx + dy*dy + dz*dz)
            assert_true(abs(dist - r) < tol)


def test_cylinder_face_count() raises:
    # segments=4: 4 side quads + 4 bottom tris + 4 top tris = 12
    var center = Point(0.0, 0.0, 0.0)
    var faces = cylinder_faces(center, 1.0, 2.0, 4)
    assert_equal(len(faces), 12)


def test_cylinder_all_faces_min_3_vertices() raises:
    var center = Point(0.0, 0.0, 0.0)
    var faces = cylinder_faces(center, 1.0, 2.0, 8)
    for i in range(len(faces)):
        assert_true(faces[i].num_vertices() >= 3)


def test_cylinder_top_z() raises:
    # Top ring vertices must have z = center.z + height
    var cz: FType = 5.0
    var h: FType = 3.0
    var center = Point(0.0, 0.0, cz)
    var faces = cylinder_faces(center, 1.0, h, 4)
    # Each group of 3 faces per segment: [side_quad, bottom_tri, top_tri]
    # Side quad vertices: [bot[i], bot[j], top[j], top[i]] → indices 2,3 are top
    for i in range(4):
        var top_v = faces[i * 3].get_vertex(2)
        assert_true(abs(top_v.z - (cz + h)) < 1e-9)


def test_cone_face_count() raises:
    # segments=4: 4 side tris + 4 base tris = 8
    var center = Point(0.0, 0.0, 0.0)
    var faces = cone_faces(center, 1.0, 1.0, 4)
    assert_equal(len(faces), 8)


def test_cone_all_faces_min_3_vertices() raises:
    var center = Point(0.0, 0.0, 0.0)
    var faces = cone_faces(center, 1.0, 1.0, 8)
    for i in range(len(faces)):
        assert_true(faces[i].num_vertices() >= 3)


def test_cone_apex_on_axis() raises:
    # Apex (3rd vertex of side triangles) must be at (cx, cy, cz + height)
    var cx: FType = 0.0; var cy: FType = 0.0; var cz: FType = 0.0
    var h: FType = 3.0
    var center = Point(cx, cy, cz)
    var faces = cone_faces(center, 1.0, h, 4)
    # Side triangles are at even indices: 0, 2, 4, 6
    for i in range(4):
        var apex = faces[i * 2].get_vertex(2)
        assert_true(abs(apex.x - cx) < 1e-9)
        assert_true(abs(apex.y - cy) < 1e-9)
        assert_true(abs(apex.z - (cz + h)) < 1e-9)


def main() raises:
    test_sphere_face_count()
    print("PASS test_sphere_face_count")

    test_sphere_all_faces_min_3_vertices()
    print("PASS test_sphere_all_faces_min_3_vertices")

    test_sphere_vertices_on_surface()
    print("PASS test_sphere_vertices_on_surface")

    test_cylinder_face_count()
    print("PASS test_cylinder_face_count")

    test_cylinder_all_faces_min_3_vertices()
    print("PASS test_cylinder_all_faces_min_3_vertices")

    test_cylinder_top_z()
    print("PASS test_cylinder_top_z")

    test_cone_face_count()
    print("PASS test_cone_face_count")

    test_cone_all_faces_min_3_vertices()
    print("PASS test_cone_all_faces_min_3_vertices")

    test_cone_apex_on_axis()
    print("PASS test_cone_apex_on_axis")

    print("\nAll 9 tests passed.")
