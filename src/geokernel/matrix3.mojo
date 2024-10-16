from geokernel import FType, Vector3


@value
struct Matrix3:
    """Row Major 3x3 Matrix."""

    var row1: Vector3
    var row2: Vector3
    var row3: Vector3

    fn __add__(self, scalar: FType) -> Self:
        return Self(self.row1 + scalar, self.row2 + scalar, self.row3 + scalar)

    fn __sub__(self, scalar: FType) -> Self:
        return Self(self.row1 - scalar, self.row2 - scalar, self.row3 - scalar)

    fn __mul__(self, scalar: FType) -> Self:
        return Self(self.row1 * scalar, self.row2 * scalar, self.row3 * scalar)

    fn __truediv__(self, scalar: FType) -> Self:
        return Self(self.row1 / scalar, self.row2 / scalar, self.row3 / scalar)

    fn __mul__(self, other: Self) -> Self:
        return Self(
            Vector3(
                self.row1.dot(other.col1()),
                self.row1.dot(other.col2()),
                self.row1.dot(other.col3()),
            ),
            Vector3(
                self.row2.dot(other.col1()),
                self.row2.dot(other.col2()),
                self.row2.dot(other.col3()),
            ),
            Vector3(
                self.row3.dot(other.col1()),
                self.row3.dot(other.col2()),
                self.row3.dot(other.col3()),
            ),
        )

    fn __repr__(self) -> String:
        return (
            "Matrix3(\n"
            + repr(self.row1)
            + ", \n"
            + repr(self.row2)
            + ", \n"
            + repr(self.row3)
            + ")"
        )

    @staticmethod
    fn identity() -> Matrix3:
        return Self(Vector3.unitX(), Vector3.unitY(), Vector3.unitZ())

    @staticmethod
    fn zero() -> Matrix3:
        return Self(Vector3.zero(), Vector3.zero(), Vector3.zero())

    fn col1(self) -> Vector3:
        return Vector3(self.row1.x, self.row2.x, self.row3.x)

    fn col2(self) -> Vector3:
        return Vector3(self.row1.y, self.row2.y, self.row3.y)

    fn col3(self) -> Vector3:
        return Vector3(self.row1.z, self.row2.z, self.row3.z)

    fn transpose(self) -> Self:
        return Self(self.col1(), self.col2(), self.col3())

    fn determinant(self) -> FType:
        return (
            self.row1.x * (self.row2.y * self.row3.z - self.row2.z * self.row3.y)
            - self.row1.y * (self.row2.x * self.row3.z - self.row2.z * self.row3.x)
            + self.row1.z * (self.row2.x * self.row3.y - self.row2.y * self.row3.x)
        )
