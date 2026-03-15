from geokernel import Point, Face, Cell, Plane
from geokernel.boolean import clip_polygon, intersect_faces, union_faces, difference_faces, union_cells, intersect_cells, difference_cells, slice_cell


fn main():
    # Test clip_polygon: clip a square by a smaller square
    var subject = List[Point]()
    subject.append(Point(0.0, 0.0, 0.0))
    subject.append(Point(2.0, 0.0, 0.0))
    subject.append(Point(2.0, 2.0, 0.0))
    subject.append(Point(0.0, 2.0, 0.0))

    var clip = List[Point]()
    clip.append(Point(1.0, 1.0, 0.0))
    clip.append(Point(3.0, 1.0, 0.0))
    clip.append(Point(3.0, 3.0, 0.0))
    clip.append(Point(1.0, 3.0, 0.0))

    var clipped = clip_polygon(subject, clip)
    print("clip_polygon result vertices:", len(clipped))  # expect 3

    # Test intersect_faces
    var pts_a = List[Point]()
    pts_a.append(Point(0.0, 0.0, 0.0))
    pts_a.append(Point(2.0, 0.0, 0.0))
    pts_a.append(Point(2.0, 2.0, 0.0))
    pts_a.append(Point(0.0, 2.0, 0.0))
    var fa = Face(pts_a)

    var pts_b = List[Point]()
    pts_b.append(Point(1.0, 1.0, 0.0))
    pts_b.append(Point(3.0, 1.0, 0.0))
    pts_b.append(Point(3.0, 3.0, 0.0))
    pts_b.append(Point(1.0, 3.0, 0.0))
    var fb = Face(pts_b)

    var inter = intersect_faces(fa, fb)
    print("intersect_faces vertices:", inter.num_vertices())  # expect 3 (unit square corner)

    # Test union_faces
    var union = union_faces(fa, fb)
    print("union_faces count:", len(union))  # expect 1 (overlap -> merged hull)

    # Test difference_faces
    var diff = difference_faces(fa, fb)
    print("difference_faces count:", len(diff))  # expect 1 or 0

    # Test 3D stubs compile and run
    var empty_faces = List[Face]()
    var ca = Cell(empty_faces)
    var cb = Cell(empty_faces)
    var _ = union_cells(ca, cb)
    var _ = intersect_cells(ca, cb)
    var _ = difference_cells(ca, cb)
    var plane = Plane(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0))
    var _ = slice_cell(ca, plane)
    print("3D stubs: OK")
