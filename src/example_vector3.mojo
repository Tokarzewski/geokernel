from geokernel import Vector3
from math import pi
from geokernel import Units


fn main() raises:
    v1 = Vector3(1, 0, 0)
    v2 = Vector3(0, 1, 0)

    print("v1:", repr(v1))
    print("v2:", repr(v2))

    multipled = v1 * 5
    print("v1 x 5:", repr(multipled))

    dot_product = v1.dot(v2)
    print("Dot product:", dot_product)

    cross_product = v1.cross(v2)
    print("Cross product:", repr(cross_product))

    length = v1.length()
    print("v1 length:", length)

    normalized = v1.normalize()
    print("v1 normalized:", repr(normalized))
    angle_rad = v1.angle(v2)

    var units = Units()
    angle_deg = units.convert("rad", "deg", angle_rad)

    print("Degree angle between v1 and v2:", angle_deg)
