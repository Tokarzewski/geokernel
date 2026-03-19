from geokernel import FType, Vector4, Quaternion
from std.math import sqrt


struct Matrix4(Copyable, Movable, ImplicitlyCopyable):
    """Row Major 4x4 Matrix."""

    var row1: Vector4
    var row2: Vector4
    var row3: Vector4
    var row4: Vector4

    def __init__(out self, row1: Vector4, row2: Vector4, row3: Vector4, row4: Vector4):
        self.row1 = row1
        self.row2 = row2
        self.row3 = row3
        self.row4 = row4

    def __init__(out self, q: Quaternion):
        var x = q.x
        var y = q.y
        var z = q.z
        var w = q.w

        var x2 = x * x
        var y2 = y * y
        var z2 = z * z
        var xy = x * y
        var xz = x * z
        var yz = y * z
        var wx = w * x
        var wy = w * y
        var wz = w * z

        self.row1 = Vector4(1 - 2 * (y2 + z2), 2 * (xy - wz), 2 * (xz + wy), 0)
        self.row2 = Vector4(2 * (xy + wz), 1 - 2 * (x2 + z2), 2 * (yz - wx), 0)
        self.row3 = Vector4(2 * (xz - wy), 2 * (yz + wx), 1 - 2 * (x2 + y2), 0)
        self.row4 = Vector4(0, 0, 0, 1)


    @staticmethod
    def identity() -> Matrix4:
        return Self(Vector4.unitX(), Vector4.unitY(), Vector4.unitZ(), Vector4.unitW())

    @staticmethod
    def zero() -> Matrix4:
        return Self(Vector4.zero(), Vector4.zero(), Vector4.zero(), Vector4.zero())

    def column0(self) -> Vector4:
        return Vector4(self.row1.x, self.row2.x, self.row3.x, self.row4.x)

    def column1(self) -> Vector4:
        return Vector4(self.row1.y, self.row2.y, self.row3.y, self.row4.y)

    def column2(self) -> Vector4:
        return Vector4(self.row1.z, self.row2.z, self.row3.z, self.row4.z)

    def column3(self) -> Vector4:
        return Vector4(self.row1.w, self.row2.w, self.row3.w, self.row4.w)

    def determinant(self) -> FType:
        return (
            self.row1.x
            * (
                self.row2.y * (self.row3.z * self.row4.w - self.row3.w * self.row4.z)
                - self.row2.z * (self.row3.y * self.row4.w - self.row3.w * self.row4.y)
                + self.row2.w * (self.row3.y * self.row4.z - self.row3.z * self.row4.y)
            )
            - self.row1.y
            * (
                self.row2.x * (self.row3.z * self.row4.w - self.row3.w * self.row4.z)
                - self.row2.z * (self.row3.x * self.row4.w - self.row3.w * self.row4.x)
                + self.row2.w * (self.row3.x * self.row4.z - self.row3.z * self.row4.x)
            )
            + self.row1.z
            * (
                self.row2.x * (self.row3.y * self.row4.w - self.row3.w * self.row4.y)
                - self.row2.y * (self.row3.x * self.row4.w - self.row3.w * self.row4.x)
                + self.row2.w * (self.row3.x * self.row4.y - self.row3.y * self.row4.x)
            )
            - self.row1.w
            * (
                self.row2.x * (self.row3.y * self.row4.z - self.row3.z * self.row4.y)
                - self.row2.y * (self.row3.x * self.row4.z - self.row3.z * self.row4.x)
                + self.row2.z * (self.row3.x * self.row4.y - self.row3.y * self.row4.x)
            )
        )

    def movement(self) -> Vector3:
        return Vector3(self.row4.x, self.row4.y, self.row4.z)

    def scale(self) -> Vector3:
        return Vector3(
            Vector3(self.row1.x, self.row1.y, self.row1.z).length(),
            Vector3(self.row2.x, self.row2.y, self.row2.z).length(),
            Vector3(self.row3.x, self.row3.y, self.row3.z).length(),
        )

    def rotation(self) -> Quaternion:
        var m00 = self.row1.x
        var m01 = self.row1.y
        var m02 = self.row1.z
        var m10 = self.row2.x
        var m11 = self.row2.y
        var m12 = self.row2.z
        var m20 = self.row3.x
        var m21 = self.row3.y
        var m22 = self.row3.z

        trace = m00 + m11 + m22

        if trace > 0:
            s = 0.5 / sqrt(trace + 1.0)
            x = (m21 - m12) * s
            y = (m02 - m20) * s
            z = (m10 - m01) * s
            w = 0.25 / s
        elif m00 > m11 and m00 > m22:
            s = 2.0 * sqrt(1.0 + m00 - m11 - m22)
            x = 0.25 * s
            y = (m01 + m10) / s
            z = (m02 + m20) / s
            w = (m21 - m12) / s
        elif m11 > m22:
            s = 2.0 * sqrt(1.0 + m11 - m00 - m22)
            x = (m01 + m10) / s
            y = 0.25 * s
            z = (m12 + m21) / s
            w = (m02 - m20) / s
        else:
            s = 2.0 * sqrt(1.0 + m22 - m00 - m11)
            x = (m02 + m20) / s
            y = (m12 + m21) / s
            z = 0.25 * s
            w = (m10 - m01) / s
        return Quaternion(x, y, z, w).normalize()
