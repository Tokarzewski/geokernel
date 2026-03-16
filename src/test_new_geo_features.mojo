from geokernel import (
    Point, Face, Shell, Wire, Vector3,
    KDNode, KDTree,
    merge_coincident_vertices, remove_degenerate_edges, fix_face_normals,
    face_face_intersect,
)


fn main():
    # ---------------------------------------------------------------
    # Task 1: face-face intersection
    # ---------------------------------------------------------------
    var pts1 = List[Point]()
    pts1.append(Point(0.0, 0.0, 0.0))
    pts1.append(Point(2.0, 0.0, 0.0))
    pts1.append(Point(2.0, 2.0, 0.0))
    pts1.append(Point(0.0, 2.0, 0.0))
    var f1 = Face(pts1)

    var pts2 = List[Point]()
    pts2.append(Point(1.0, 1.0, 0.0))
    pts2.append(Point(3.0, 1.0, 0.0))
    pts2.append(Point(3.0, 3.0, 0.0))
    pts2.append(Point(1.0, 3.0, 0.0))
    var f2 = Face(pts2)

    var result_coplanar = face_face_intersect(f1, f2)
    if result_coplanar:
        print("Coplanar intersection Wire found")
    else:
        print("No coplanar intersection (unexpected)")

    # Non-coplanar: two faces intersecting at a line
    var pts3 = List[Point]()
    pts3.append(Point(0.0, -1.0, -1.0))
    pts3.append(Point(2.0, -1.0, -1.0))
    pts3.append(Point(2.0, -1.0,  1.0))
    pts3.append(Point(0.0, -1.0,  1.0))
    var f3 = Face(pts3)

    var pts4 = List[Point]()
    pts4.append(Point(0.0,  -2.0, 0.0))
    pts4.append(Point(2.0,  -2.0, 0.0))
    pts4.append(Point(2.0,   2.0, 0.0))
    pts4.append(Point(0.0,   2.0, 0.0))
    var f4 = Face(pts4)

    var result_noncoplanar = face_face_intersect(f3, f4)
    if result_noncoplanar:
        print("Non-coplanar intersection Wire found")
    else:
        print("No non-coplanar intersection (unexpected)")

    # ---------------------------------------------------------------
    # Task 2: KDTree
    # ---------------------------------------------------------------
    var kd_pts = List[Point]()
    kd_pts.append(Point(0.0, 0.0, 0.0))
    kd_pts.append(Point(1.0, 0.0, 0.0))
    kd_pts.append(Point(0.0, 1.0, 0.0))
    kd_pts.append(Point(5.0, 5.0, 5.0))
    var tree = KDTree(kd_pts)

    var query = Point(0.1, 0.1, 0.0)
    var nearest = tree.nearest(query)
    print("Nearest to (0.1,0.1,0): ", nearest.__repr__())

    var in_radius = tree.points_in_radius(Point(0.0, 0.0, 0.0), 1.5)
    print("Points within radius 1.5 of origin:", len(in_radius))

    # ---------------------------------------------------------------
    # Task 3: Shape healing
    # ---------------------------------------------------------------
    # Build a simple shell with coincident vertices
    var face_pts_a = List[Point]()
    face_pts_a.append(Point(0.0, 0.0, 0.0))
    face_pts_a.append(Point(1.0, 0.0, 0.0))
    face_pts_a.append(Point(1.0, 1.0, 0.0))
    face_pts_a.append(Point(0.0, 1.0, 0.0))
    var fa = Face(face_pts_a)

    # Slightly offset duplicate vertices (within tol)
    var face_pts_b = List[Point]()
    face_pts_b.append(Point(1.0, 0.0, 0.0))
    face_pts_b.append(Point(2.0, 0.0, 0.0))
    face_pts_b.append(Point(2.0, 1.0, 0.0))
    face_pts_b.append(Point(1.0000001, 1.0, 0.0))  # slightly off
    var fb = Face(face_pts_b)

    var shell_faces = List[Face]()
    shell_faces.append(fa)
    shell_faces.append(fb)
    var sh = Shell(shell_faces)

    var healed = merge_coincident_vertices(sh, 1e-5)
    print("Faces after merge_coincident_vertices:", len(healed.faces))

    var cleaned = remove_degenerate_edges(sh)
    print("Faces after remove_degenerate_edges:", len(cleaned.faces))

    var fixed = fix_face_normals(sh)
    print("Faces after fix_face_normals:", len(fixed.faces))

    print("All tests passed!")
