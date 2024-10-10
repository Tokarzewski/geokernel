from geokernel import Point, Line, Vector3


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(1, 1, 1)
    line1 = Line(p1, p2)
    print("Line1:", repr(line1))
    print("direction:", repr(line1.direction()))
    print("line length:", line1.length())
    print("midpoint:", repr(line1.midpoint()))
    print("reversed line", repr(line1.reverse()))
    print("")

    p3 = Point(0, 0, 0)
    p4 = Point(2, 2, 2)
    line2 = Line(p3, p4)
    print("Line2:", repr(line2))
    print("Is line1 parallel to line2:", line1.is_parallel(line2))
    print("")

    p5 = Point(0, 1, 0)
    p6 = Point(1, 2, 0)
    line3 = Line(p5, p6)
    print("Line3:", repr(line3))
    print("Is line1 parallel to line3:", line1.is_parallel(line3))

    print("Moved line3", repr(line3.moved(0, 0, 1)))

    direction = Vector3(0, 0, 5)
    extruded_line = line1.extrude(direction)
    print(repr(extruded_line))

    p7 = Point(1, 1, 0)
    p8 = Point(0, 0, 1)
    p9 = Point(0, 0, 0)
    p10 = Point(1, 1, 1)

    line_l = Line(p7, p8)
    line_p = Line(p9, p10)
    result = line_l.intersects(line_p)

    intersects = result.get[0, Bool]()
    point = result.get[1, Point]()
    print("Lines intersect:", intersects)
    print("Lines intersect at:", repr(point))
