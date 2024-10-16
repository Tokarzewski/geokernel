from geokernel import Point, Wire, Vector3


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(1, 0, 0)
    p3 = Point(1, 1, 0)
    wire = Wire(List[Point](p1, p2, p3))
    closed_wire = Wire(List[Point](p1, p2, p3, p1))

    print("Open Wire: " + repr(wire))
    print("Move Open Wire: " + repr(wire.move(0, 0, 1)))
    print("Number of points: " + str(wire.num_points()))
    print("Number of segments: " + str(wire.num_segments()))
    print("Total length: " + str(wire.length()))
    print("Is closed: " + str(wire.is_closed()))
    print("")
    print("Closed Wire: " + repr(closed_wire))
    print("Is closed: " + str(closed_wire.is_closed()))
    print("Reverse:", repr(closed_wire.reverse()))
    print("Double Reverse:", repr(closed_wire.reverse().reverse()))
    print(repr(wire.extrude(Vector3.from_point(p2))))
