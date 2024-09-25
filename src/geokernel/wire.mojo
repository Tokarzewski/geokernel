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
        if self.is_closed():
            return self.points.size - 1
        else:
            return self.points.size

    fn get_point(self, i: Int) -> Point:
        return self.points[i]

    fn get_segment(self, i: Int) -> Line:
        return Line(self.points[i], self.points[i + 1])

    fn reverse(owned self) -> Self:
        self.points.reverse()
        return self

    fn length(self) -> FType:
        var total_length: FType = 0
        for i in range(self.num_segments()):
            total_length += self.get_segment(i).length()
        return total_length

    fn is_closed(self) -> Bool:
        if self.points.size < 3:
            return False
        return self.points[0] == self.points[self.points.size - 1]

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

    fn extrude(self, v: Vector3) -> Shell:
        var faces = List[Face]()
        for i in range(self.num_segments()):
            var face = self.get_segment(i).extrude(v)
            faces.append(face)
        return Shell(List[Face](faces))
