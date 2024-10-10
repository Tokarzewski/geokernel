from geokernel import Vector3, Matrix3


# Example usage
fn main():
    # matrix1 = Matrix3.identity()
    # print(matrix1.determinant())

    v1 = Vector3(1, 3, 3)
    v2 = Vector3(1, 3, 3)
    v3 = Vector3(1, 3, 3)

    matrix2 = Matrix3(v1, v2, v3)
    print(matrix2.determinant())
