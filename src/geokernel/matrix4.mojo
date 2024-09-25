from geokernel import FType, Vector4


@value
struct Matrix4:
    var row0: Vector4
    var row1: Vector4
    var row2: Vector4
    var row3: Vector4

    @staticmethod
    fn identity() -> Matrix4:
        return Self(Vector4.unitX(), Vector4.unitY(), Vector4.unitZ(), Vector4.unitW())

    @staticmethod
    fn zero() -> Matrix4:
        return Self(Vector4.zero(), Vector4.zero(), Vector4.zero(), Vector4.zero())

    fn column0(self) -> Vector4:
        return Vector4(self.row0.x, self.row1.x, self.row2.x, self.row3.x)

    fn column1(self) -> Vector4:
        return Vector4(self.row0.y, self.row1.y, self.row2.y, self.row3.y)

    fn column2(self) -> Vector4:
        return Vector4(self.row0.z, self.row1.z, self.row2.z, self.row3.z)

    fn column3(self) -> Vector4:
        return Vector4(self.row0.w, self.row1.w, self.row2.w, self.row3.w)

    fn determinant(self) -> FType:
        return (
            self.row0.x
            * (
                self.row1.y * (self.row2.z * self.row3.w - self.row2.w * self.row3.z)
                - self.row1.z * (self.row2.y * self.row3.w - self.row2.w * self.row3.y)
                + self.row1.w * (self.row2.y * self.row3.z - self.row2.z * self.row3.y)
            )
            - self.row0.y
            * (
                self.row1.x * (self.row2.z * self.row3.w - self.row2.w * self.row3.z)
                - self.row1.z * (self.row2.x * self.row3.w - self.row2.w * self.row3.x)
                + self.row1.w * (self.row2.x * self.row3.z - self.row2.z * self.row3.x)
            )
            + self.row0.z
            * (
                self.row1.x * (self.row2.y * self.row3.w - self.row2.w * self.row3.y)
                - self.row1.y * (self.row2.x * self.row3.w - self.row2.w * self.row3.x)
                + self.row1.w * (self.row2.x * self.row3.y - self.row2.y * self.row3.x)
            )
            - self.row0.w
            * (
                self.row1.x * (self.row2.y * self.row3.z - self.row2.z * self.row3.y)
                - self.row1.y * (self.row2.x * self.row3.z - self.row2.z * self.row3.x)
                + self.row1.z * (self.row2.x * self.row3.y - self.row2.y * self.row3.x)
            )
        )
