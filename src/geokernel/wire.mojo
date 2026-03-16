from geokernel import FType, Point, Line, Vector3, Transform, Quaternion, Shell, Face, AABB
from math import sqrt


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

    fn is_closed(self, atol: FType = 1e-10) -> Bool:
        """True if the first and last points are within atol of each other."""
        var s = self.startpoint()
        var e = self.endpoint()
        var dx = s.x - e.x
        var dy = s.y - e.y
        var dz = s.z - e.z
        from math import sqrt
        return sqrt(dx * dx + dy * dy + dz * dz) <= atol

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

    fn sweep_along_wire(self, path: Wire) -> Shell:
        """Sweep this wire profile along a path wire, creating a Shell."""
        var faces = List[Face]()
        var path_pts = path.points.copy()
        if len(path_pts) < 2:
            return Shell(faces)
        var current = self
        for i in range(len(path_pts) - 1):
            var delta = Vector3(
                path_pts[i + 1].x - path_pts[i].x,
                path_pts[i + 1].y - path_pts[i].y,
                path_pts[i + 1].z - path_pts[i].z,
            )
            var next_pos = current.move_by_vector(delta)
            for j in range(current.num_segments()):
                var seg_a = current.get_segment(j)
                var seg_b = next_pos.get_segment(j)
                var face_pts = List[Point]()
                face_pts.append(seg_a.p1)
                face_pts.append(seg_a.p2)
                face_pts.append(seg_b.p2)
                face_pts.append(seg_b.p1)
                faces.append(Face(face_pts))
            current = next_pos
        return Shell(faces)

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

    fn is_planar(self, atol: FType = 1e-10) -> Bool:
        """True if all points are coplanar (consistent normal across consecutive triples)."""
        var n = len(self.points)
        if n < 3:
            return True
        # Find first valid normal
        var ref_normal = Vector3(0.0, 0.0, 0.0)
        for i in range(n - 2):
            var v1 = Vector3(
                self.points[i + 1].x - self.points[i].x,
                self.points[i + 1].y - self.points[i].y,
                self.points[i + 1].z - self.points[i].z,
            )
            var v2 = Vector3(
                self.points[i + 2].x - self.points[i].x,
                self.points[i + 2].y - self.points[i].y,
                self.points[i + 2].z - self.points[i].z,
            )
            var candidate = v1.cross(v2)
            if candidate.length() > atol:
                ref_normal = candidate.normalize()
                break
        if ref_normal.length() < atol:
            return True  # all collinear — trivially planar
        # Check all points against the plane defined by points[0] + ref_normal
        var origin = self.points[0]
        for i in range(1, n):
            var d = Vector3(
                self.points[i].x - origin.x,
                self.points[i].y - origin.y,
                self.points[i].z - origin.z,
            )
            if abs(ref_normal.dot(d)) > atol:
                return False
        return True

    fn bounding_box(self) -> AABB:
        """Axis-aligned bounding box of all wire points."""
        return AABB(self.points)

    fn remove_collinear_edges(self) -> Wire:
        """Merge consecutive collinear segments by removing intermediate points."""
        return self.remove_collinear_points()

    fn remove_collinear_points(self, atol: FType = 1e-10) -> Wire:
        """Remove intermediate collinear points, keeping only direction changes.

        A point is collinear if the cross product of the two adjacent edge
        vectors has length <= atol (i.e. the three points are co-linear).
        """
        var n = len(self.points)
        if n < 3:
            return self
        var result = List[Point]()
        result.append(self.points[0])
        for i in range(1, n - 1):
            var v1 = Vector3(
                self.points[i].x - self.points[i - 1].x,
                self.points[i].y - self.points[i - 1].y,
                self.points[i].z - self.points[i - 1].z,
            )
            var v2 = Vector3(
                self.points[i + 1].x - self.points[i].x,
                self.points[i + 1].y - self.points[i].y,
                self.points[i + 1].z - self.points[i].z,
            )
            var cross = v1.cross(v2)
            if cross.length() > atol:
                result.append(self.points[i])
        result.append(self.points[n - 1])
        return Wire(result)
