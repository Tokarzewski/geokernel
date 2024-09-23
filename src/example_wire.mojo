from geokernel import Point, Wire, Vector


# Example usage
fn main():
    var p1 = Point(0, 0, 0)
    var p2 = Point(1, 0, 0)
    var p3 = Point(1, 1, 0)
    var wire = Wire(List[Point](p1, p2, p3))
    var closed_wire = Wire(List[Point](p1, p2, p3, p1))

    print("Open Wire: " + repr(wire))
    print("Number of points: " + str(wire.num_points()))
    print("Number of segments: " + str(wire.num_segments()))
    print("Total length: " + str(wire.length()))
    print("Is closed: " + str(wire.is_closed()))
    print("")
    print("Closed Wire: " + repr(closed_wire))
    print("Is closed: " + str(closed_wire.is_closed()))
    print("Reversed:", repr(closed_wire.reverse()))
    print("Double Reversed:", repr(closed_wire.reverse().reverse()))
    print(repr(wire.extrude(Vector.from_point(p2))))
