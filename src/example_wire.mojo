from geokernel import Point, Wire, Vector3


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(1, 0, 0)
    p3 = Point(1, 1, 0)
    open_wire = Wire(List[Point](p1, p2, p3))
    closed_wire = Wire(List[Point](p1, p2, p3, p1))

    print("Open Wire: " + repr(open_wire))
    print("Number of points: " + str(open_wire.num_points()))
    print("Number of segments: " + str(open_wire.num_segments()))
    print("Move Open Wire: " + repr(open_wire.move(0, 0, 1)))
    print("Total length: " + str(open_wire.length()))
    print("Is closed: " + str(open_wire.is_closed()))

    print("")

    print("Closed Wire: " + repr(closed_wire))
    print("Number of points: " + str(closed_wire.num_points()))
    print("Number of segments: " + str(closed_wire.num_segments()))
    print("Is closed: " + str(closed_wire.is_closed()))
    print("Reverse:", repr(closed_wire.reverse()))
