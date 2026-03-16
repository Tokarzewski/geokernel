from std.testing import assert_true
from geokernel import FType, Point, Face
from geokernel.obj import export_obj, import_obj

def main() raises:
    var p1 = Point(0.0, 0.0, 0.0)
    var p2 = Point(1.0, 0.0, 0.0)
    var p3 = Point(0.0, 1.0, 0.0)
    var pts = List[Point]()
    pts.append(p1); pts.append(p2); pts.append(p3)
    var f = Face(pts)
    var faces = List[Face]()
    faces.append(f)
    var obj = export_obj(faces)
    print(obj)
    var imported = import_obj(obj)
    print("faces:", len(imported))
    print("vertices:", imported[0].num_vertices())
