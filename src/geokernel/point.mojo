from geokernel import FType, Vector3, Transform
import math


struct Point(Copyable, Movable, ImplicitlyCopyable):
    var x: FType
    var y: FType
    var z: FType

    fn __init__(out self, x: FType, y: FType, z: FType):
        self.x = x
        self.y = y
        self.z = z


    fn __copyinit__(out self, copy: Self):
        self.x = copy.x
        self.y = copy.y
        self.z = copy.z

    fn __moveinit__(out self, deinit take: Self):
        self.x = take.x
        self.y = take.y
        self.z = take.z

    fn __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar)

    fn __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar)

    fn __eq__(self, other: Self) -> Bool:
        return self.isclose(other, atol=1e-15, rtol=1e-15)

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn __add__(self, other: Self) -> Self:
        return Self(self.x + other.x, self.y + other.y, self.z + other.z)

    fn __iadd__(mut self, other: Self):
        self = self.__add__(other)

    fn __sub__(self, other: Self) -> Self:
        return Self(self.x - other.x, self.y - other.y, self.z - other.z)

    fn __isub__(mut self, other: Self):
        self = self.__sub__(other)

    fn __lt__(self, other: Self) -> Bool:
        return self.x < other.x and self.y < other.y and self.z < other.z

    fn __le__(self, other: Point) -> Bool:
        return self.x <= other.x and self.y <= other.y and self.z <= other.z

    fn __gt__(self, other: Point) -> Bool:
        return self.x > other.x and self.y > other.y and self.z > other.z

    fn __ge__(self, other: Point) -> Bool:
        return self.x >= other.x and self.y >= other.y and self.z >= other.z

    fn __repr__(self) -> String:
        return "Point(" + String(self.x) + ", " + String(self.y) + ", " + String(self.z) + ")"

    fn coordinates(self) -> (FType, FType, FType):
        return (self.x, self.y, self.z)

    fn isclose(self, other: Point, atol: FType, rtol: FType) -> Bool:
        return (
            math.isclose(self.x, other.x, atol=atol, rtol=rtol)
            and math.isclose(self.y, other.y, atol=atol, rtol=rtol)
            and math.isclose(self.z, other.z, atol=atol, rtol=rtol)
        )

    fn move(self, dx: FType, dy: FType, dz: FType) -> Self:
        return Self(self.x + dx, self.y + dy, self.z + dz)

    fn move_by_vector(self, v: Vector3) -> Self:
        return self.move(v.x, v.y, v.z)

    fn transform(self, t: Transform) -> Self:
        """Apply a Transform (scale → rotate → translate) to this point."""
        # Scale
        var scaled = Self(self.x * t.scale.x, self.y * t.scale.y, self.z * t.scale.z)
        # Rotate
        var v = t.rotation.rotate_vector(Vector3.from_point(scaled))
        # Translate
        return Self(v.x + t.movement.x, v.y + t.movement.y, v.z + t.movement.z)

    @staticmethod
    fn min(p1: Point, p2: Point) -> Point:
        """New Point with the minimum coordinates of two points."""
        return Point(min(p1.x, p2.x), min(p1.y, p2.y), min(p1.z, p2.z))

    @staticmethod
    fn max(p1: Point, p2: Point) -> Point:
        """New Point with the maximum coordinates of two points."""
        return Point(max(p1.x, p2.x), max(p1.y, p2.y), max(p1.z, p2.z))
