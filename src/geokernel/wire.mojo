from geokernel import FType, Point, Line, Vector3


@value
struct Wire:
    var points: List[Point]

    fn __init__(inout self, points: List[Point]):
        self.points = points

    fn __repr__(self) -> String:
        var result: String = "Wire("
        for i in range(self.points.size):
            if i > 0:
                result += ", "
            result += repr(self.points[i])
        return result + ")"

    fn num_points(self) -> Int:
        return self.points.size

    fn num_segments(self) -> Int:
        return self.points.size - 1

    fn get_point(self, i: Int) -> Point:
        return self.points[i]

    fn get_segment(self, i: Int) -> Line:
        return Line(self.points[i], self.points[i + 1])

    fn startpoint(self) -> Point:
        return self.points[0]

    fn endpoint(self) -> Point:
        return self.points[-1]

    fn is_closed(self) -> Bool:
        return self.startpoint() == self.endpoint()

    fn reverse(inout self) -> Self:
        self.points.reverse()
        return self

    fn length(self) -> FType:
        var total_length: FType = 0
        for i in range(self.num_segments()):
            total_length += self.get_segment(i).length()
        return total_length

    fn move(self, dx: FType, dy: FType, dz: FType) -> Self:
        var moved_points = List[Point]()
        for i in range(len(self.points)):
            var moved_point = self.points[i].move(dx, dy, dz)
            moved_points.append(moved_point)
        return Self(moved_points)

    fn move_by_vector(self, v: Vector3) -> Self:
        return self.move(v.x, v.y, v.z)

    fn extrude(self, v: Vector3) -> Shell:
        var faces = List[Face]()
        for i in range(self.num_segments()):
            var face = self.get_segment(i).extrude(v)
            faces.append(face)
        return Shell(List[Face](faces))
