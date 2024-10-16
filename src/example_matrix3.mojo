from geokernel import Vector3, Matrix3


fn main():
    r1 = Vector3(1, 2, -1)
    r2 = Vector3(3, 2, 0)
    r3 = Vector3(-4, 0, 2)
    matrixA = Matrix3(r1, r2, r3)

    r4 = Vector3(3, 4, 2)
    r5 = Vector3(0, 1, 0)
    r6 = Vector3(-2, 0, 1)
    matrixB = Matrix3(r4, r5, r6)

    matrixC = matrixA * matrixB

    print("A", repr(matrixA))
    print("B", repr(matrixB))
    print("C", repr(matrixC))

    print()
    print("Transpose")
    print(repr(matrixA))
    print(repr(matrixA.transpose()))

    print()
    print("MatrixA determinant:", str(matrixA.determinant()))
