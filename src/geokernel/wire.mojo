from geokernel import FType, Point, Line, Vector3, Transform, Quaternion, Shell, Face


struct Wire(Copyable, Movable, ImplicitlyCopyable):
    var points: List[Point]

    fn __init__(out self, points: List[Point]):
        self.points = points.copy()


    fn __copyinit__(out self, copy: Self):
        self.points = copy.points.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.points = take.points^

    fn __repr__(self) -> String:
        var result: String = "Wire("
        for i in range(len(self.points)):
            if i > 0:
                result += ", "
            result += self.points[i].__repr__()
        return result + ")"

    fn num_points(self) -> Int:
        return len(self.points)

    fn num_segments(self) -> Int:
        return len(self.points) - 1

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

    fn reverse(mut self) -> Self:
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

    fn transform(self, t: Transform) -> Self:
        """Apply a Transform to all points of the wire."""
        var transformed_points = List[Point]()
        for i in range(len(self.points)):
            transformed_points.append(self.points[i].transform(t))
        return Self(transformed_points)

    fn intersects_line(self, l: Line) -> Bool:
        """Return True if the wire intersects the given line segment."""
        for i in range(self.num_segments()):
            var seg = self.get_segment(i)
            var result = seg.intersects(l)
            if result[0]:
                return True
        return False

    fn intersect_line(self, l: Line) -> List[Point]:
        """Return all intersection points between the wire segments and the line."""
        var result = List[Point]()
        for i in range(self.num_segments()):
            var seg = self.get_segment(i)
            var intersection = seg.intersects(l)
            if intersection[0]:
                result.append(intersection[1])
        return result^

    fn rotate(self, q: Quaternion) -> Self:
        var rotated = List[Point]()
        for i in range(len(self.points)):
            rotated.append(self.points[i].rotate(q))
        return Self(rotated)

    fn sweep(self, path: Line) -> Shell:
        var direction = path.direction()
        var moved = self.move_by_vector(direction)
        var faces = List[Face]()
        for i in range(self.num_segments()):
            var seg_start = self.get_segment(i)
            var seg_end = moved.get_segment(i)
            var face_pts = List[Point]()
            face_pts.append(seg_start.p1)
            face_pts.append(seg_start.p2)
            face_pts.append(seg_end.p2)
            face_pts.append(seg_end.p1)
            faces.append(Face(face_pts))
        return Shell(faces)

    fn extrude(self, v: Vector3) -> Shell:
        var faces = List[Face]()
        for i in range(self.num_segments()):
            var face = self.get_segment(i).extrude(v)
            faces.append(face)
        return Shell(faces)
