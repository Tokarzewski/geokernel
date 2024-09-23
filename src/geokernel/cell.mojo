from geokernel import FType, Point, Face


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
            var displacement = Vector.from_points(reference_point, centroid)
            var signed_volume = normal.dot(displacement) * face.area()
            volume += signed_volume

        return abs(volume) / 3.0


# IsClosed? Check if all edges are adjacent to only 2 faces
# Move, Rotate, Scale, Transform
# Boolean operations 3D
# IsPointInside?
# Centroid
# fn mesh, use face.triangulate()
