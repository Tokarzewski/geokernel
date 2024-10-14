from geokernel import FType, Point, Face, Cell


@value
struct Shell:
    var faces: List[Face]

    fn __init__(inout self, faces: List[Face]):
        self.faces = faces

    fn __repr__(self) -> String:
        var result: String = "Shell(\n"
        for i in range(self.faces.size):
            if i > 0:
                result += ",\n"
            result += repr(self.faces[i])
        return result + ")"

    fn area(self) -> FType:
        var area: FType = 0.0
        for i in range(self.faces.size):
            area += self.faces[i].area()
        return area

    # fn gaps(): #find gaps in the shell

    # fn cap(): #cap gaps

    # fn close() -> Cell: # if there are no gaps left then can be closed and return cell object

    # fn mesh, use face.triangulate()
