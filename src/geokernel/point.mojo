from geokernel import FType, Vector3
import math


@value
struct Point(Movable):
    var x: FType
    var y: FType
    var z: FType

    fn __init__(inout self, x: FType, y: FType, z: FType):
        self.x = x
        self.y = y
        self.z = z

    fn __eq__(self, other: Point) -> Bool:
        return self.isclose(other, atol=1e-15, rtol=1e-15)

    fn __ne__(self, other: Point) -> Bool:
        return not self.__eq__(other)

    fn __add__(self, other: Self) -> Self:
        return Self(self.x + other.x, self.y + other.y, self.z + other.z)

    fn __iadd__(inout self, other: Self):
        self = self.__add__(other)

    fn __sub__(self, other: Self) -> Self:
        return Self(self.x - other.x, self.y - other.y, self.z - other.z)

    fn __isub__(inout self, other: Self):
        self = self.__sub__(other)

    fn __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar)

    fn __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar)

    fn __lt__(self, other: Point) -> Bool:
        return self.x < other.x and self.y < other.y and self.z < other.z

    fn __le__(self, other: Point) -> Bool:
        return self.x <= other.x and self.y <= other.y and self.z <= other.z

    fn __gt__(self, other: Point) -> Bool:
        return self.x > other.x and self.y > other.y and self.z > other.z

    fn __ge__(self, other: Point) -> Bool:
        return self.x >= other.x and self.y >= other.y and self.z >= other.z

    fn __repr__(self) -> String:
        return "Point(" + str(self.x) + ", " + str(self.y) + ", " + str(self.z) + ")"

    fn coordinates(self) -> (FType, FType, FType):
        return (self.x, self.y, self.z)

    fn isclose(self, other: Point, atol: FType, rtol: FType) -> Bool:
        return (
            math.isclose(self.x, other.x, atol=atol, rtol=rtol)
            and math.isclose(self.y, other.y, atol=atol, rtol=rtol)
            and math.isclose(self.z, other.z, atol=atol, rtol=rtol)
        )

    fn move(inout self, dx: FType, dy: FType, dz: FType) -> Self:
        self.x = self.x + dx
        self.y = self.y + dy
        self.z = self.z + dz
        return self

    fn moved(self, dx: FType, dy: FType, dz: FType) -> Self:
        return Self(self.x + dx, self.y + dy, self.z + dz)

    fn move_by_vector(inout self, v: Vector3) -> Self:
        return self.move(v.x, v.y, v.z)

    fn moved_by_vector(self, v: Vector3) -> Self:
        return self.moved(v.x, v.y, v.z)

    @staticmethod
    fn min(p1: Point, p2: Point) -> Point:
        """New Point with the minimum coordinates of two points."""
        return Point(min(p1.x, p2.x), min(p1.y, p2.y), min(p1.z, p2.z))

    @staticmethod
    fn max(p1: Point, p2: Point) -> Point:
        """New Point with the maximum coordinates of two points."""
        return Point(max(p1.x, p2.x), max(p1.y, p2.y), max(p1.z, p2.z))
