from geokernel import FType, Point
from math import sqrt


@value
struct Vector4(Representable):
    """Vector - with 4 dimensions and Ftype precision."""

    var x: FType
    var y: FType
    var z: FType
    var w: FType

    fn __init__(inout self, x: FType, y: FType, z: FType, w: FType):
        self.x = x
        self.y = y
        self.z = z
        self.w = w

    @staticmethod
    fn zero() -> Self:
        return Self(0, 0, 0, 0)

    @staticmethod
    fn unitX() -> Self:
        return Self(1, 0, 0, 0)

    @staticmethod
    fn unitY() -> Self:
        return Self(0, 1, 0, 0)

    @staticmethod
    fn unitZ() -> Self:
        return Self(0, 0, 1, 0)

    @staticmethod
    fn unitW() -> Self:
        return Self(0, 0, 0, 1)

    fn __add__(self, other: Self) -> Self:
        return Self(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
            self.w + other.w,
        )

    fn __sub__(self, other: Self) -> Self:
        return Self(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
            self.w - other.w,
        )

    fn __mul__(self, scalar: FType) -> Self:
        return Self(
            self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar
        )

    fn __truediv__(self, scalar: FType) -> Self:
        return Self(
            self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar
        )

    fn __repr__(self) -> String:
        return (
            "Vector3("
            + str(self.x)
            + ", "
            + str(self.y)
            + ", "
            + str(self.z)
            + ", "
            + str(self.w)
            + ")"
        )

    fn reverse(inout self) -> Self:
        self.x = -self.x
        self.y = -self.y
        self.z = -self.z
        self.w = -self.w
        return self

    fn dot(self, other: Self) -> FType:
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

    fn length(self) -> FType:
        return sqrt(self.dot(self))

    fn normalize(self) -> Self:
        scale = 1 / self.length()
        return self * scale

    fn lerp(self, other: Self, t: FType) -> Self:
        """Create a new vector that is a linear blend of two vectors."""
        var x = self.x + t * (other.x - self.x)
        var y = self.y + t * (other.y - self.y)
        var z = self.z + t * (other.z - self.z)
        var w = self.w + t * (other.w - self.w)
        return Self(x, y, z, w)
