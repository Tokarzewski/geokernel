from geokernel import Vector3
from math import pi


# Example usage
fn main():
    var v1 = Vector3(1, 0, 0)
    var v2 = Vector3(0, 1, 0)

    print("v1:", repr(v1))
    print("v2:", repr(v2))

    var multipled = v1 * 5
    print("v1 x 5:", repr(multipled))

    var dot_product = v1.dot(v2)
    print("Dot product:", dot_product)

    var cross_product = v1.cross(v2)
    print("Cross product:", repr(cross_product))

    var length = v1.length()
    print("v1 length:", length)

    var normalized = v1.normalize()
    print("v1 normalized:", repr(normalized))

    var angle = v1.angle(v2)
    print("Degree angle between v1 and v2:", angle * 180 / pi)

    print("reversed", repr(v1.reversed()))
    print("reverse", repr(v1.reverse()))
    print("reverse", repr(v1.reverse()))
