from geokernel import FType, Point, Vector, Face
from math import sqrt


@value
struct Line:
    var p1: Point
    var p2: Point

    fn __repr__(self) -> String:
        return "Line(" + repr(self.p1) + ", " + repr(self.p2) + ")"

    fn direction(self) -> Vector:
        return Vector.from_point(self.p2) - Vector.from_point(self.p1)

    fn length(self) -> FType:
        var direction = self.direction()
        return sqrt(direction.dot(direction))

    fn point_at(self, t: FType) -> Point:
        """Calculate a point along the line at a given parameter t starting from p1.
        """
        return Point(
            self.p1.x + t * (self.p2.x - self.p1.x),
            self.p1.y + t * (self.p2.y - self.p1.y),
            self.p1.z + t * (self.p2.z - self.p1.z),
        )

    fn startpoint(self) -> Point:
        return self.p1

    fn midpoint(self) -> Point:
        return self.point_at(t=0.5)

    fn endpoint(self) -> Point:
        return self.p2

    fn reverse(self) -> Self:
        return Self(self.p2, self.p1)

    fn is_parallel(self, other: Self, tolerance: FType = 1e-9) -> Bool:
        """
        Check if this line is parallel to another line.
        """
        var dir1 = self.direction().normalize()
        var dir2 = other.direction().normalize()
        var cross_product = dir1.cross(dir2)
        return cross_product.length() < tolerance

    fn move(inout self, dx: FType, dy: FType, dz: FType) -> Self:
        _ = self.p1.move(dx, dy, dz)
        _ = self.p2.move(dx, dy, dz)
        return self

    fn move_by_vector(inout self, v: Vector) -> Self:
        return self.move(v.x, v.y, v.z)

    fn moved(self, dx: FType, dy: FType, dz: FType) -> Self:
        return Self(self.p1.moved(dx, dy, dz), self.p2.moved(dx, dy, dz))

    fn moved_by_vector(self, v: Vector) -> Self:
        return self.moved(v.x, v.y, v.z)

    fn extrude(self, v: Vector) -> Face:
        var line2 = self.moved_by_vector(v)

        return Face(List[Point](self.p1, self.p2, line2.p2, line2.p1))

    # fn intersects(self, other: Self) -> Bool:
