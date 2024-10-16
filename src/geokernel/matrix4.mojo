from geokernel import FType, Vector4, Quaternion
from math import sqrt


@value
struct Matrix4:
    """Row Major 4x4 Matrix."""

    var row1: Vector4
    var row2: Vector4
    var row3: Vector4
    var row4: Vector4

    fn __init__(inout self, row1: Vector4, row2: Vector4, row3: Vector4, row4: Vector4):
        self.row1 = row1
        self.row2 = row2
        self.row3 = row3
        self.row4 = row4

    fn __init__(inout self, q: Quaternion):
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
    fn identity() -> Matrix4:
        return Self(Vector4.unitX(), Vector4.unitY(), Vector4.unitZ(), Vector4.unitW())

    @staticmethod
    fn zero() -> Matrix4:
        return Self(Vector4.zero(), Vector4.zero(), Vector4.zero(), Vector4.zero())

    fn column0(self) -> Vector4:
        return Vector4(self.row1.x, self.row2.x, self.row3.x, self.row4.x)

    fn column1(self) -> Vector4:
        return Vector4(self.row1.y, self.row2.y, self.row3.y, self.row4.y)

    fn column2(self) -> Vector4:
        return Vector4(self.row1.z, self.row2.z, self.row3.z, self.row4.z)

    fn column3(self) -> Vector4:
        return Vector4(self.row1.w, self.row2.w, self.row3.w, self.row4.w)

    fn determinant(self) -> FType:
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

    fn movement(self) -> Vector3:
        return Vector3(self.row4.x, self.row4.y, self.row4.z)

    fn scale(self) -> Vector3:
        return Vector3(
            Vector3(self.row1.x, self.row1.y, self.row1.z).length(),
            Vector3(self.row2.x, self.row2.y, self.row2.z).length(),
            Vector3(self.row3.x, self.row3.y, self.row3.z).length(),
        )

    fn rotation(self) -> Quaternion:
        m00, m01, m02, _ = self.row1.components()
        m10, m11, m12, _ = self.row2.components()
        m20, m21, m22, _ = self.row3.components()

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
