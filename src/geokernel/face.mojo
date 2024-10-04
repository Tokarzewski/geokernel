from geokernel import FType, Point, Line, Wire, Vector3, Cell
from math import sqrt


@value
struct Face:
    var points: List[Point]

    fn __init__(inout self, points: List[Point]):
        self.points = points
        if self.points[0] != self.points[-1]:
            self.points.append(self.points[0])

    fn __repr__(self) -> String:
        var result: String = "Face("
        for i in range(self.points.size):
            if i > 0:
                result += ", "
            result += repr(self.points[i])
        return result + ")"

    fn reverse(owned self) -> Self:
        self.points.reverse()
        return self

    fn num_vertices(self) -> Int:
        return self.points.size - 1

    fn num_edges(self) -> Int:
        return self.points.size - 1

    fn get_vertex(self, i: Int) -> Point:
        return self.points[i]

    fn get_edge(self, i: Int) -> Line:
        return Line(self.points[i], self.points[(i + 1)])

    fn wire(self) -> Wire:
        return Wire(self.points)

    fn perimeter(self) -> FType:
        var total_length: FType = 0
        for i in range(self.num_edges()):
            total_length += self.get_edge(i).length()
        return total_length

    fn area(self) -> FType:
        var ref_point = self.points[0]
        var normal = Vector3(0, 0, 0)

        for i in range(1, self.num_vertices() - 1):
            var v1 = Vector3.from_points(ref_point, self.points[i])
            var v2 = Vector3.from_points(ref_point, self.points[i + 1])
            normal += v1.cross(v2)

        return normal.length() / 2.0

    fn normal(self) -> Vector3:
        var p1 = self.points[0]
        var p2 = self.points[1]
        var v1 = Vector3.from_points(p1, p2)

        for i in range(self.num_vertices()):
            var p3 = self.points[(i + 2)]
            var v2 = Vector3.from_points(p1, p3)
            var cross_product = v1.cross(v2)
            if cross_product.length() > 0:
                return cross_product.normalize()
        return Vector3(0, 0, 0)

    fn centroid(self) -> Point:
        var weighted_sum = Point(0, 0, 0)
        var total_area: FType = 0.0

        for i in range(self.num_vertices()):
            var p1 = self.points[i]
            var p2 = self.points[(i + 1) % self.num_vertices()]
            var p3 = self.points[(i + 2) % self.num_vertices()]

            var triangle = Face(List[Point](p1, p2, p3))
            var triangle_area = triangle.area()
            var triangle_centroid = (p1 + p2 + p3) / 3

            weighted_sum += triangle_centroid * triangle_area
            total_area += triangle_area

        return weighted_sum / total_area

    fn move(inout self, dx: FType, dy: FType, dz: FType) -> Self:
        for i in range(len(self.points)):
            _ = self.points[i].move(dx, dy, dz)
        return self

    fn move_by_vector(inout self, v: Vector3) -> Self:
        return self.move(v.x, v.y, v.z)

    fn moved(self, dx: FType, dy: FType, dz: FType) -> Self:
        var moved_points = List[Point]()
        for i in range(len(self.points)):
            moved_points.append(self.points[i].moved(dx, dy, dz))
        return Self(moved_points)

    fn moved_by_vector(self, v: Vector3) -> Self:
        return self.moved(v.x, v.y, v.z)

    fn extrude(self, v: Vector3) -> Cell:
        var faces = List[Face]()
        faces.append(self)  # original polygon
        faces.append(self.moved_by_vector(v))  # moved polygon
        faces.extend(self.wire().extrude(v).faces)  # sides
        return Cell(faces)

    # fn triangulate(self) -> List[Face]:


# Rotate, Scale, Transform
# Boolean operations 2D
