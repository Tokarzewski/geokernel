from geokernel import FType, Point, Face, Cell


struct Shell(Copyable, Movable, ImplicitlyCopyable):
    var faces: List[Face]

    fn __init__(out self, faces: List[Face]):
        self.faces = faces


    fn __copyinit__(out self, copy: Self):
        self.faces = copy.faces.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.faces = take.faces^

    fn __repr__(self) -> String:
        var result: String = "Shell(\n"
        for i in range(self.faces.size):
            if i > 0:
                result += ",\n"
            result += self.faces[i].__repr__()
        return result + ")"

    fn area(self) -> FType:
        var area: FType = 0.0
        for i in range(self.faces.size):
            area += self.faces[i].area()
        return area

    # fn gaps(): #return list of gaps in the shell

    # fn cap(): #cap gaps

    # fn close() -> Cell: # if there are no gaps left then can be closed and return cell object

    # fn mesh, use face.triangulate()
