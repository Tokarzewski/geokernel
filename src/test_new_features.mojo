from geokernel import Point, Wire, Face, Shell, Quaternion, Vector3, Line, Plane, Triangulation


def main():
    # Task 1: Quaternion rotate
    var q = Quaternion.from_axis_angle(Vector3(0, 0, 1), 1.5707963)
    var p = Point(1.0, 0.0, 0.0)
    var rotated_p = p.rotate(q)
    print("Rotated point:", rotated_p.__repr__())

    var pts = List[Point]()
    pts.append(Point(0.0, 0.0, 0.0))
    pts.append(Point(1.0, 0.0, 0.0))
    pts.append(Point(2.0, 0.0, 0.0))
    var w = Wire(pts)
    var rotated_w = w.rotate(q)
    print("Rotated wire:", rotated_w.__repr__())

    var face_pts = List[Point]()
    face_pts.append(Point(0.0, 0.0, 0.0))
    face_pts.append(Point(1.0, 0.0, 0.0))
    face_pts.append(Point(1.0, 1.0, 0.0))
    face_pts.append(Point(0.0, 1.0, 0.0))
    var f = Face(face_pts)
    var rotated_f = f.rotate(q)
    print("Rotated face:", rotated_f.__repr__())

    # Task 2: Triangulation
    var tris = Triangulation.triangulate_face(f)
    print("Triangles:", len(tris))

    # Task 3: Shell open_edges / has_holes
    var faces = List[Face]()
    faces.append(f)
    var sh = Shell(faces)
    var open_e = sh.open_edges()
    print("Open edges:", len(open_e))
    print("Has holes:", sh.has_holes())

    # Task 4: Slice shell by plane
    var plane = Plane(Point(0.5, 0.0, 0.0), Vector3(1.0, 0.0, 0.0))
    var halves = sh.slice(plane)
    print("Above faces:", len(halves[0].faces))
    print("Below faces:", len(halves[1].faces))

    # Task 5: Sweep wire
    var wire2_pts = List[Point]()
    wire2_pts.append(Point(0.0, 0.0, 0.0))
    wire2_pts.append(Point(1.0, 0.0, 0.0))
    var w2 = Wire(wire2_pts)
    var path = Line(Point(0.0, 0.0, 0.0), Point(0.0, 0.0, 5.0))
    var swept = w2.sweep(path)
    print("Swept shell faces:", len(swept.faces))

    print("All OK")
