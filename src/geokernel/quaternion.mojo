from geokernel import FType, Vector3
from std.math import sin, cos, sqrt, acos, pi, atan2, asin


struct Quaternion(Copyable, Movable, ImplicitlyCopyable):
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

    def __add__(self, other: Self) -> Self:
        return Self(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
            self.w + other.w,
        )

    def __sub__(self, other: Self) -> Self:
        return Self(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
            self.w - other.w,
        )

    def __mul__(self, scalar: FType) -> Self:
        return Self(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar)

    def __mul__(self, q: Self) -> Self:
        return Self(
            self.w * q.x + self.x * q.w + self.y * q.z - self.z * q.y,
            self.w * q.y - self.x * q.z + self.y * q.w + self.z * q.x,
            self.w * q.z + self.x * q.y - self.y * q.x + self.z * q.w,
            self.w * q.w - self.x * q.x - self.y * q.y - self.z * q.z,
        )

    def __truediv__(self, scalar: FType) -> Self:
        return Self(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar)

    def __repr__(self) -> String:
        return (
            "Quaternion("
            + String(self.x)
            + ", "
            + String(self.y)
            + ", "
            + String(self.z)
            + ", "
            + String(self.w)
            + ")"
        )

    @staticmethod
    def identity() -> Self:
        return Self(0, 0, 0, 1)

    @staticmethod
    def from_axis_angle(axis: Vector3, angle: FType) -> Self:
        var half_angle = angle / 2
        var s = sin(half_angle)
        return Self(axis.x * s, axis.y * s, axis.z * s, cos(half_angle)).normalize()

    @staticmethod
    def from_euler_angles(roll: FType, pitch: FType, yaw: FType) -> Self:
        var cy = cos(yaw * 0.5)
        var sy = sin(yaw * 0.5)
        var cp = cos(pitch * 0.5)
        var sp = sin(pitch * 0.5)
        var cr = cos(roll * 0.5)
        var sr = sin(roll * 0.5)

        return Self(
            sr * cp * cy - cr * sp * sy,
            cr * sp * cy + sr * cp * sy,
            cr * cp * sy - sr * sp * cy,
            cr * cp * cy + sr * sp * sy,
        )

    def dot(self, other: Self) -> FType:
        return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w

    def length(self) -> FType:
        return sqrt(self.dot(self))

    def normalize(self) -> Self:
        var len = self.length()
        if len == 0:
            return self.identity()
        else:
            return self / len

    def conjugate(self) -> Self:
        return Self(-self.x, -self.y, -self.z, self.w)

    def inverse(self) -> Self:
        var norm_sq = self.x**2 + self.y**2 + self.z**2 + self.w**2
        return self.conjugate() / norm_sq

    def to_axis_angle(self) -> Tuple[Vector3, FType]:
        var q = self.normalize()
        var angle = 2 * acos(q.w)
        var s = sqrt(1 - q.w**2)
        if s < 1e-5:
            return (Vector3(1, 0, 0), angle)
        return (Vector3(q.x, q.y, q.z) / s, angle)

    def rotate_vector(self, v: Vector3) -> Vector3:
        var q_v = Self(v.x, v.y, v.z, 0)
        var q_result = self * q_v * self.inverse()
        return Vector3(q_result.x, q_result.y, q_result.z)

    def to_euler_angles(self) -> Tuple[FType, FType, FType]:
        """Returns XYZ (roll, pitch, yaw) in radians."""
        var sinr_cosp = 2 * (self.w * self.x + self.y * self.z)
        var cosr_cosp = 1 - 2 * (self.x * self.x + self.y * self.y)
        var roll = atan2(sinr_cosp, cosr_cosp)

        var sinp = 2 * (self.w * self.y - self.z * self.x)
        var pitch = asin(sinp)

        var siny_cosp = 2 * (self.w * self.z + self.x * self.y)
        var cosy_cosp = 1 - 2 * (self.y * self.y + self.z * self.z)
        var yaw = atan2(siny_cosp, cosy_cosp)

        return (roll, pitch, yaw)

    def nlerp(q1: Self, q2: Self, t: FType) -> Self:
        return (q1 * (1 - t) + q2 * t).normalize()
