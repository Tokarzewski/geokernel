from geokernel import FType, Point
from math import sqrt, acos, pi


@value
struct Vector3:
    var x: FType
    var y: FType
    var z: FType

    fn __init__(inout self, x: FType, y: FType, z: FType):
        self.x = x
        self.y = y
        self.z = z

    @staticmethod
    fn from_point(p: Point) -> Self:
        return Self(p.x, p.y, p.z)

    @staticmethod
    fn to_point(self) -> Point:
        return Point(self.x, self.y, self.z)

    @staticmethod
    fn from_points(p1: Point, p2: Point) -> Self:
        """The vector points from p1 to p2."""
        return Self(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z)

    @staticmethod
    fn zero() -> Self:
        return Self(0, 0, 0)

    @staticmethod
    fn unitX() -> Self:
        return Self(1, 0, 0)

    @staticmethod
    fn unitY() -> Self:
        return Self(0, 1, 0)

    @staticmethod
    fn unitZ() -> Self:
        return Self(0, 0, 1)

    # Scalar dunder methods
    fn __add__(self, scalar: FType) -> Self:
        return Self(self.x + scalar, self.y + scalar, self.z + scalar)

    fn __sub__(self, scalar: FType) -> Self:
        return Self(self.x - scalar, self.y - scalar, self.z - scalar)

    fn __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar)

    fn __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar)

    # Vector dunder methods
    fn __add__(self, other: Self) -> Self:
        return Self(self.x + other.x, self.y + other.y, self.z + other.z)

    fn __iadd__(inout self, other: Self):
        self = self.__add__(other)

    fn __sub__(self, other: Self) -> Self:
        return Self(self.x - other.x, self.y - other.y, self.z - other.z)

    fn __isub__(inout self, other: Self):
        self = self.__sub__(other)

    fn __repr__(self) -> String:
        return "Vector3(" + str(self.x) + ", " + str(self.y) + ", " + str(self.z) + ")"

    fn components(self) -> (FType, FType, FType):
        return (self.x, self.y, self.z)

    fn reverse(self) -> Self:
        return Self(-self.x, -self.y, -self.z)

    fn inverse(self) -> Self:
        return Self(1 / self.x, 1 / self.y, 1 / self.z)

    fn dot(self, other: Self) -> FType:
        """
        Sum of the products of corresponding components.
        """
        var result: FType = 0.0
        result += self.x * other.x
        result += self.y * other.y
        result += self.z * other.z
        return result

    fn cross(self, other: Self) -> Self:
        """The cross product of two vectors is a vector perpendicular to both."""
        return Self(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        )

    fn length(self) -> FType:
        return sqrt(self.dot(self))

    fn normalize(self) -> Self:
        scale = 1 / self.length()
        return self * scale

    fn angle(self, other: Self) -> FType:
        """Calculate angle in radians between two vectors."""
        dot_product = self.dot(other)

        mag_sq_v1 = self.dot(self)
        mag_sq_v2 = other.dot(other)

        if mag_sq_v1 == 0 or mag_sq_v2 == 0:
            return 0

        cos_angle = dot_product / sqrt(mag_sq_v1 * mag_sq_v2)

        return acos(cos_angle)

    fn lerp(self, other: Self, t: FType) -> Self:
        """Create a new vector that is a linear blend of two vectors."""
        return self + (other - self) * t
