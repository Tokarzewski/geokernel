from geokernel import FType, Vector3
import math


@value
struct Point(Movable):
    """Point - Point in 3 dimensions and double precision."""

    var x: FType
    var y: FType
    var z: FType
    # var uuid: String

    fn __init__(inout self, x: FType, y: FType, z: FType):
        self.x = x
        self.y = y
        self.z = z
        # self.uuid = generate_uuid()

    fn __eq__(self, other: Point) -> Bool:
        return self.isclose(other, atol=0.0, rtol=1e-15)

    fn __ne__(self, other: Point) -> Bool:
        return not self.__eq__(other)

    fn __add__(self, other: Self) -> Self:
        return Self(self.x + other.x, self.y + other.y, self.z + other.z)

    fn __sub__(self, other: Self) -> Self:
        return Self(self.x - other.x, self.y - other.y, self.z - other.z)

    fn __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar)

    fn __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar)

    fn __repr__(self) -> String:
        return "Point(" + str(self.x) + ", " + str(self.y) + ", " + str(self.z) + ")"

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
