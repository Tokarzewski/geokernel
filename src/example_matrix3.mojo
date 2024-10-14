from geokernel import Vector3, Matrix3


fn main():
    v1 = Vector3(1, 3, 3)
    v2 = Vector3(1, 3, 3)
    v3 = Vector3(1, 3, 3)

    matrix2 = Matrix3(v1, v2, v3)
    print(matrix2.determinant())
