from geokernel import FType, Vector3, Transform, Quaternion
import std.math as math


struct Point(Copyable, Movable, ImplicitlyCopyable, Writable):
    var x: FType
    var y: FType
    var z: FType

    def __init__(out self, x: FType, y: FType, z: FType):
        self.x = x
        self.y = y
        self.z = z


    def __init__(out self, *, deinit take: Self):
        self.x = take.x
        self.y = take.y
        self.z = take.z

    def __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar)

    def __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar)

    def __eq__(self, other: Self) -> Bool:
        return self.isclose(other, atol=1e-15, rtol=1e-15)

    def __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    def __add__(self, other: Self) -> Self:
        return Self(self.x + other.x, self.y + other.y, self.z + other.z)

    def __iadd__(mut self, other: Self):
        self = self.__add__(other)

    def __sub__(self, other: Self) -> Self:
        return Self(self.x - other.x, self.y - other.y, self.z - other.z)

    def __isub__(mut self, other: Self):
        self = self.__sub__(other)

    def __lt__(self, other: Self) -> Bool:
        """Lexicographic ordering: compare x, then y, then z."""
        if self.x != other.x:
            return self.x < other.x
        if self.y != other.y:
            return self.y < other.y
        return self.z < other.z

    def __le__(self, other: Point) -> Bool:
        return self == other or self < other

    def __gt__(self, other: Point) -> Bool:
        if self.x != other.x:
            return self.x > other.x
        if self.y != other.y:
            return self.y > other.y
        return self.z > other.z

    def __ge__(self, other: Point) -> Bool:
        return self == other or self > other

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Point(", self.x, ", ", self.y, ", ", self.z, ")")

    def __repr__(self) -> String:
        return String.write(self)

    def coordinates(self) -> Tuple[FType, FType, FType]:
        return (self.x, self.y, self.z)

    def isclose(self, other: Point, atol: FType, rtol: FType) -> Bool:
        return (
            math.isclose(self.x, other.x, atol=atol, rtol=rtol)
            and math.isclose(self.y, other.y, atol=atol, rtol=rtol)
            and math.isclose(self.z, other.z, atol=atol, rtol=rtol)
        )

    def isclose(self, other: Point, tol: Float64 = 1e-9) -> Bool:
        var dx = self.x - other.x
        var dy = self.y - other.y
        var dz = self.z - other.z
        return math.sqrt(dx * dx + dy * dy + dz * dz) <= tol

    def move(self, dx: FType, dy: FType, dz: FType) -> Self:
        return Self(self.x + dx, self.y + dy, self.z + dz)

    def move_by_vector(self, v: Vector3) -> Self:
        return self.move(v.x, v.y, v.z)

    def transform(self, t: Transform) -> Self:
        """Apply a Transform (scale → rotate → translate) to this point."""
        # Scale
        var scaled = Self(self.x * t.scale.x, self.y * t.scale.y, self.z * t.scale.z)
        # Rotate
        var v = t.rotation.rotate_vector(Vector3.from_point(scaled))
        # Translate
        return Self(v.x + t.movement.x, v.y + t.movement.y, v.z + t.movement.z)

    def rotate(self, q: Quaternion) -> Self:
        var v = q.rotate_vector(Vector3(self.x, self.y, self.z))
        return Self(v.x, v.y, v.z)

    @staticmethod
    def min(p1: Point, p2: Point) -> Point:
        """New Point with the minimum coordinates of two points."""
        return Point(min(p1.x, p2.x), min(p1.y, p2.y), min(p1.z, p2.z))

    @staticmethod
    def max(p1: Point, p2: Point) -> Point:
        """New Point with the maximum coordinates of two points."""
        return Point(max(p1.x, p2.x), max(p1.y, p2.y), max(p1.z, p2.z))
