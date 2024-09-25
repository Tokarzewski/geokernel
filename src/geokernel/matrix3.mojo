from geokernel import FType, Vector3


@value
struct Matrix3:
    var row0: Vector3
    var row1: Vector3
    var row2: Vector3

    @staticmethod
    fn identity() -> Matrix3:
        return Self(Vector3.unitX(), Vector3.unitY(), Vector3.unitZ())

    @staticmethod
    fn zero() -> Matrix3:
        return Self(Vector3.zero(), Vector3.zero(), Vector3.zero())

    fn column0(self) -> Vector3:
        return Vector3(self.row0.x, self.row1.x, self.row2.x)

    fn column1(self) -> Vector3:
        return Vector3(self.row0.y, self.row1.y, self.row2.y)

    fn column2(self) -> Vector3:
        return Vector3(self.row0.z, self.row1.z, self.row2.z)

    fn determinant(self) -> FType:
        return (
            self.row0.x
            * (self.row1.y * self.row2.z - self.row1.z * self.row2.y)
            - self.row0.y
            * (self.row1.x * self.row2.z - self.row1.z * self.row2.x)
            + self.row0.z
            * (self.row1.x * self.row2.y - self.row1.y * self.row2.x)
        )
