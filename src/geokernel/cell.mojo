from geokernel import FType, Point, LP, Face, AABB


struct Cell(Copyable, Movable, ImplicitlyCopyable):
    var faces: List[Face]

    def __init__(out self, faces: List[Face]):
        self.faces = faces.copy()


    def __init__(out self, *, copy: Self):
        self.faces = copy.faces.copy()

    def __init__(out self, *, deinit take: Self):
        self.faces = take.faces^

    def __repr__(self) -> String:
        var result: String = "Cell(\n"
        for i in range(len(self.faces)):
            if i > 0:
                result += ",\n"
            result += self.faces[i].__repr__()
        return result + ")"

    @staticmethod
    def from_two_points(p_min: Point, p_max: Point) -> Self:
        var faces = List[Face]()

        var x_min = p_min.x
        var y_min = p_min.y
        var z_min = p_min.z
        var x_max = p_max.x
        var y_max = p_max.y
        var z_max = p_max.z

        var p1 = p_min
        var p2 = Point(x_min, y_max, z_min)
        var p3 = Point(x_max, y_max, z_min)
        var p4 = Point(x_max, y_min, z_min)

        var p5 = Point(x_min, y_min, z_max)
        var p6 = Point(x_min, y_max, z_max)
        var p7 = p_max
        var p8 = Point(x_max, y_min, z_max)

        var right: List[Point] = [p3, p7, p8, p4]
        var left: List[Point] = [p1, p5, p6, p2]
        var back: List[Point] = [p2, p6, p7, p3]
        var front: List[Point] = [p1, p4, p8, p5]
        var bottom: List[Point] = [p1, p2, p3, p4]
        var top: List[Point] = [p5, p8, p7, p6]
        faces.append(Face(right))   # Right face (+X)
        faces.append(Face(left))    # Left face (-X)
        faces.append(Face(back))    # Back face (+Y)
        faces.append(Face(front))   # Front face (-Y)
        faces.append(Face(bottom))  # Bottom face (-Z)
        faces.append(Face(top))     # Top face (+Z)

        return Self(faces)

    @staticmethod
    def from_aabb(self, aabb: AABB) -> Self:
        p_min = aabb.p_min
        p_max = aabb.p_max
        return self.from_two_points(p_min, p_max)

    def area(self) -> FType:
        var area: FType = 0.0
        for i in range(len(self.faces)):
            area += self.faces[i].area()
        return area

    def volume(self) -> FType:
        var volume: FType = 0.0
        var reference_point = Point(0, 0, 0)

        for i in range(len(self.faces)):
            face = self.faces[i]
            var normal = face.normal()
            var centroid = face.centroid()
            var displacement = Vector3.from_points(reference_point, centroid)
            var signed_volume = normal.dot(displacement) * face.area()
            volume += signed_volume

        return abs(volume) / 3.0


# IsClosed? Check if all lines are used in exactly 2 faces
# Move, Rotate, Scale, Transform
# Boolean operations 3D
# IsPointInside?
# Centroid
# fn mesh, use face.triangulate()
