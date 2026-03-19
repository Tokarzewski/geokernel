from geokernel import FType, Point
from std.math import sqrt


struct Vector4(Copyable, Movable, ImplicitlyCopyable, Writable):
    """Vector - with 4 dimensions and Ftype precision."""

    var x: FType
    var y: FType
    var z: FType
    var w: FType

    def __init__(out self, x: FType, y: FType, z: FType, w: FType):
        self.x = x
        self.y = y
        self.z = z
        self.w = w


    def __init__(out self, *, deinit take: Self):
        self.x = take.x
        self.y = take.y
        self.z = take.z
        self.w = take.w

    @staticmethod
    def zero() -> Self:
        return Self(0, 0, 0, 0)

    @staticmethod
    def unitX() -> Self:
        return Self(1, 0, 0, 0)

    @staticmethod
    def unitY() -> Self:
        return Self(0, 1, 0, 0)

    @staticmethod
    def unitZ() -> Self:
        return Self(0, 0, 1, 0)

    @staticmethod
    def unitW() -> Self:
        return Self(0, 0, 0, 1)

    def __add__(self, other: Self) -> Self:
        return Self(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
            self.w + other.w,
        )

    def __iadd__(mut self, other: Self):
        self = self.__add__(other)

    def __sub__(self, other: Self) -> Self:
        return Self(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
            self.w - other.w,
        )

    def __isub__(mut self, other: Self):
        self = self.__sub__(other)

    def __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar)

    def __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar)

    def write_to(self, mut writer: Some[Writer]):
        writer.write("Vector4(", self.x, ", ", self.y, ", ", self.z, ", ", self.w, ")")

    def __repr__(self) -> String:
        return String.write(self)

    def components(self) -> Tuple[FType, FType, FType, FType]:
        return (self.x, self.y, self.z, self.w)

    def reverse(self) -> Self:
        return Self(-self.x, -self.y, -self.z, -self.w)

    def inverse(self) -> Self:
        return Self(1 / self.x, 1 / self.y, 1 / self.z, 1 / self.w)

    def dot(self, other: Self) -> FType:
        """
        The dot product is a scalar value that is the sum of the products of
        the corresponding entries of two vectors. It's the product of the
        lengths of the two vectors and the cosine of the angle between them.
        """
        var result: FType = 0
        result += self.x * other.x
        result += self.y * other.y
        result += self.z * other.z
        result += self.w * other.w
        return result

    def length(self) -> FType:
        return sqrt(self.dot(self))

    def normalize(self) -> Self:
        scale = 1 / self.length()
        return self * scale

    def lerp(self, other: Self, t: FType) -> Self:
        """Create a new vector that is a linear blend of two vectors."""
        return self + (other - self) * t
