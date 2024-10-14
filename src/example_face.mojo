from geokernel import Point, Face, Vector3


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(0, 1, 0)
    p3 = Point(1, 1, 0)
    p4 = Point(1, 0, 0)

    square = Face(List[Point](p1, p2, p3, p4))

    print(repr(square))
    print("perimeter:", square.perimeter())
    print("area:", square.area())
    print("centroid", repr(square.centroid()))
    print("normal vector", repr(square.normal()))
    print("normal vector of reversed", repr(square.reverse().normal()))

    wire = square.wire()
    print(repr(wire))

    diagonal = Vector3(1, 1, 1)
    cube = square.extrude(diagonal)
    print(repr(cube))
    print("Cube volume", cube.volume())
