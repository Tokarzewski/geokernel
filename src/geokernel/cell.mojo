from geokernel import FType, Point, LP, Face, AABB


@value
struct Cell:
    var faces: List[Face]

    fn __init__(inout self, faces: List[Face]):
        self.faces = faces

    fn __repr__(self) -> String:
        var result: String = "Cell(\n"
        for i in range(self.faces.size):
            if i > 0:
                result += ",\n"
            result += repr(self.faces[i])
        return result + ")"

    @staticmethod
    fn from_two_points(p_min: Point, p_max: Point) -> Self:
        var faces = List[Face]()

        (x_min, y_min, z_min) = p_min.coordinates()
        (x_max, y_max, z_max) = p_max.coordinates()

        var p1 = p_min
        var p2 = Point(x_min, y_max, z_min)
        var p3 = Point(x_max, y_max, z_min)
        var p4 = Point(x_max, y_min, z_min)

        var p5 = Point(x_min, y_min, z_max)
        var p6 = Point(x_min, y_max, z_max)
        var p7 = p_max
        var p8 = Point(x_max, y_min, z_max)

        faces.append(Face(LP(p3, p7, p8, p4)))  # Right face (+X)
        faces.append(Face(LP(p1, p5, p6, p2)))  # Left face (-X)

        faces.append(Face(LP(p2, p6, p7, p3)))  # Back face (+Y)
        faces.append(Face(LP(p1, p4, p8, p5)))  # Front face (-Y)

        faces.append(Face(LP(p1, p2, p3, p4)))  # Bottom face (-Z)
        faces.append(Face(LP(p5, p8, p7, p6)))  # Top face (+Z)

        return Self(faces)

    @staticmethod
    fn from_aabb(self, aabb: AABB) -> Self:
        p_min = aabb.p_min
        p_max = aabb.p_max
        return self.from_two_points(p_min, p_max)

    fn area(self) -> FType:
        var area: FType = 0.0
        for i in range(self.faces.size):
            area += self.faces[i].area()
        return area

    fn volume(self) -> FType:
        var volume: FType = 0.0
        var reference_point = Point(0, 0, 0)

        for i in range(self.faces.size):
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
