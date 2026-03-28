from geokernel import FType, Point
from std.math import sqrt, acos, pi


struct Vector3(Copyable, Movable, ImplicitlyCopyable, Writable):
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

    @staticmethod
    def from_point(p: Point) -> Self:
        return Self(p.x, p.y, p.z)

    @staticmethod
    def to_point(self) -> Point:
        return Point(self.x, self.y, self.z)

    @staticmethod
    def from_points(p1: Point, p2: Point) -> Self:
        """The vector points from p1 to p2."""
        return Self(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z)

    @staticmethod
    def zero() -> Self:
        return Self(0, 0, 0)

    @staticmethod
    def unitX() -> Self:
        return Self(1, 0, 0)

    @staticmethod
    def unitY() -> Self:
        return Self(0, 1, 0)

    @staticmethod
    def unitZ() -> Self:
        return Self(0, 0, 1)

    # Scalar dunder methods
    def __add__(self, scalar: FType) -> Self:
        return Self(self.x + scalar, self.y + scalar, self.z + scalar)

    def __sub__(self, scalar: FType) -> Self:
        return Self(self.x - scalar, self.y - scalar, self.z - scalar)

    def __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar)

    def __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar)

    # Vector dunder methods
    def __add__(self, other: Self) -> Self:
        return Self(self.x + other.x, self.y + other.y, self.z + other.z)

    def __iadd__(mut self, other: Self):
        self = self.__add__(other)

    def __sub__(self, other: Self) -> Self:
        return Self(self.x - other.x, self.y - other.y, self.z - other.z)

    def __isub__(mut self, other: Self):
        self = self.__sub__(other)

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Vector3(", self.x, ", ", self.y, ", ", self.z, ")")

    def __repr__(self) -> String:
        return String.write(self)

    def components(self) -> Tuple[FType, FType, FType]:
        return (self.x, self.y, self.z)

    def reverse(self) -> Self:
        return Self(-self.x, -self.y, -self.z)

    def inverse(self) -> Self:
        """Component-wise reciprocal. Zero components are left as zero."""
        var ix = 1.0 / self.x if abs(self.x) > 1e-30 else 0.0
        var iy = 1.0 / self.y if abs(self.y) > 1e-30 else 0.0
        var iz = 1.0 / self.z if abs(self.z) > 1e-30 else 0.0
        return Self(ix, iy, iz)

    def dot(self, other: Self) -> FType:
        """
        Sum of the products of corresponding components.
        """
        var result: FType = 0.0
        result += self.x * other.x
        result += self.y * other.y
        result += self.z * other.z
        return result

    def cross(self, other: Self) -> Self:
        """The cross product of two vectors is a vector perpendicular to both."""
        return Self(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        )

    def length(self) -> FType:
        return sqrt(self.dot(self))

    def normalize(self) -> Self:
        var len = self.length()
        if len < 1e-15:
            return Self(0.0, 0.0, 0.0)
        return self * (1.0 / len)

    def angle(self, other: Self) -> FType:
        """Calculate angle in radians between two vectors."""
        dot_product = self.dot(other)

        mag_sq_v1 = self.dot(self)
        mag_sq_v2 = other.dot(other)

        if mag_sq_v1 == 0 or mag_sq_v2 == 0:
            return 0

        cos_angle = dot_product / sqrt(mag_sq_v1 * mag_sq_v2)

        return acos(cos_angle)

    def lerp(self, other: Self, t: FType) -> Self:
        """Create a new vector that is a linear blend of two vectors."""
        return self + (other - self) * t
