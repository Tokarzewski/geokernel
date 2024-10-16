from geokernel import FType, Point, Vector3, Face
from math import sqrt


@value
struct Line:
    var p1: Point
    var p2: Point

    fn __repr__(self) -> String:
        return "Line(" + repr(self.p1) + ", " + repr(self.p2) + ")"

    fn direction(self) -> Vector3:
        return Vector3.from_point(self.p2 - self.p1)

    fn length(self) -> FType:
        var direction = self.direction()
        return sqrt(direction.dot(direction))

    fn point_at(self, t: FType) -> Point:
        return self.p1 + (self.p2 - self.p1) * t

    fn startpoint(self) -> Point:
        return self.p1

    fn midpoint(self) -> Point:
        return self.point_at(t=0.5)

    fn endpoint(self) -> Point:
        return self.p2

    fn reverse(self) -> Self:
        return Self(self.p2, self.p1)

    fn is_parallel(self, other: Self, atol: FType = 1e-15) -> Bool:
        var dir1 = self.direction().normalize()
        var dir2 = other.direction().normalize()
        var cross_product = dir1.cross(dir2)
        return cross_product.length() < atol

    fn move(self, dx: FType, dy: FType, dz: FType) -> Self:
        return Self(self.p1.move(dx, dy, dz), self.p2.move(dx, dy, dz))

    fn move_by_vector(self, v: Vector3) -> Self:
        return self.move(v.x, v.y, v.z)

    fn extrude(self, v: Vector3) -> Face:
        var line2 = self.move_by_vector(v)

        return Face(List[Point](self.p1, self.p2, line2.p2, line2.p1))

    fn intersects(self, other: Self, atol: FType = 1e-15) -> Tuple[Bool, Point]:
        """
        Check if lines intersects in 3D space.
        Returns a tuple containing a boolean (True if lines intersect) and the point of intersection.
        If lines don't intersect, the second element of the tuple will be a Point at (0,0,0).
        """
        var dir1 = self.direction()
        var dir2 = other.direction()
        var normal = dir1.cross(dir2)

        var denom = normal.dot(normal)
        if denom < atol:
            # Lines are parallel or coincident
            return (False, Point(0, 0, 0))

        var diff = Vector3.from_point(other.p1 - self.p1)
        var t = diff.cross(dir2).dot(normal) / denom

        if 0.0 <= t <= 1.0:
            var u = diff.cross(dir1).dot(normal) / denom
            if 0.0 <= u <= 1.0:
                return (True, self.point_at(t))

        # Lines are not parallel or coincident and don't intersect
        return (False, Point(0, 0, 0))
