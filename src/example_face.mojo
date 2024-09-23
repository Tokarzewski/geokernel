from testing import assert_equal, assert_true, assert_false
from geokernel import Point, Face, Vector


fn main():
    var p1 = Point(0, 0, 0)
    var p2 = Point(1, 0, 0)
    var p3 = Point(1, 1, 0)
    var p4 = Point(0, 1, 0)
    var p5 = Point(0.5, 0, 0)

    var square = Face(List[Point](p5, p4, p3, p2, p1))

    print(repr(square))
    print("perimeter:", square.perimeter())
    print("area:", square.area())
    print("centroid", repr(square.centroid()))
    print("normal vector", repr(square.normal()))
    print("normal vector of reversed", repr(square.reverse().normal()))
    print(repr(square.wire()))

    var unit_z = Vector.unitZ()
    var cube = square.extrude(unit_z)
    print(repr(cube))
    print("Cube volume", cube.volume())
