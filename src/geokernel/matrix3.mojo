from geokernel import FType, Vector3


struct Matrix3(Copyable, Movable, ImplicitlyCopyable):
    """Row Major 3x3 Matrix."""

    var row1: Vector3
    var row2: Vector3
    var row3: Vector3

    def __init__(out self, row1: Vector3, row2: Vector3, row3: Vector3):
        self.row1 = row1
        self.row2 = row2
        self.row3 = row3

    def __init__(out self, *, deinit take: Self):
        self.row1 = take.row1
        self.row2 = take.row2
        self.row3 = take.row3

    def __add__(self, scalar: FType) -> Self:
        return Self(self.row1 + scalar, self.row2 + scalar, self.row3 + scalar)

    def __sub__(self, scalar: FType) -> Self:
        return Self(self.row1 - scalar, self.row2 - scalar, self.row3 - scalar)

    def __mul__(self, scalar: FType) -> Self:
        return Self(self.row1 * scalar, self.row2 * scalar, self.row3 * scalar)

    def __truediv__(self, scalar: FType) -> Self:
        return Self(self.row1 / scalar, self.row2 / scalar, self.row3 / scalar)

    def __mul__(self, other: Self) -> Self:
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

    def __repr__(self) -> String:
        return (
            "Matrix3(\n"
            + self.row1.__repr__()
            + ", \n"
            + self.row2.__repr__()
            + ", \n"
            + self.row3.__repr__()
            + ")"
        )

    @staticmethod
    def identity() -> Matrix3:
        return Self(Vector3.unitX(), Vector3.unitY(), Vector3.unitZ())

    @staticmethod
    def zero() -> Matrix3:
        return Self(Vector3.zero(), Vector3.zero(), Vector3.zero())

    def col1(self) -> Vector3:
        return Vector3(self.row1.x, self.row2.x, self.row3.x)

    def col2(self) -> Vector3:
        return Vector3(self.row1.y, self.row2.y, self.row3.y)

    def col3(self) -> Vector3:
        return Vector3(self.row1.z, self.row2.z, self.row3.z)

    def transpose(self) -> Self:
        return Self(self.col1(), self.col2(), self.col3())

    def determinant(self) -> FType:
        return (
            self.row1.x * (self.row2.y * self.row3.z - self.row2.z * self.row3.y)
            - self.row1.y * (self.row2.x * self.row3.z - self.row2.z * self.row3.x)
            + self.row1.z * (self.row2.x * self.row3.y - self.row2.y * self.row3.x)
        )
