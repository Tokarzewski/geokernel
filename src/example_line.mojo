from geokernel import Point, Line, Vector


fn main():
    var p1 = Point(0, 0, 0)
    var p2 = Point(1, 0, 0)
    var line1 = Line(p1, p2)
    print("Line1:", repr(line1))
    print("direction:", repr(line1.direction()))
    print("line length:", line1.length())
    print("midpoint:", repr(line1.midpoint()))
    print("reversed line", repr(line1.reverse()))
    print("")

    # Test is_parallel
    var p3 = Point(2, 2, 2)
    var p4 = Point(-2, -2, -2)
    var line2 = Line(p3, p4)
    print("Line2:", repr(line2))
    print("Is line1 parallel to line2:", line1.is_parallel(line2))
    print("")

    var p5 = Point(0, 1, 0)
    var p6 = Point(1, 2, 0)
    var line3 = Line(p5, p6)
    print("Line3:", repr(line3))
    print("Is line1 parallel to line3:", line1.is_parallel(line3))

    print("Moved line3", repr(line3.moved(0, 0, 1)))

    var direction = Vector(0, 0, 5)
    var extruded_line = line1.extrude(direction)
    print(repr(extruded_line))
