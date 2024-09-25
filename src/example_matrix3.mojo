from geokernel import Vector3, Matrix3


# Example usage
fn main():
    # var matrix1 = Matrix3.identity()
    # print(matrix1.determinant())

    var v1 = Vector3(1, 3, 3)
    var v2 = Vector3(1, 3, 3)
    var v3 = Vector3(1, 3, 3)

    var matrix2 = Matrix3(v1, v2, v3)
    print(matrix2.determinant())
