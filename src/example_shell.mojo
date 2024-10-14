from geokernel import Point, LP, Face, Shell


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(1, 0, 0)
    p3 = Point(1, 1, 0)
    p4 = Point(0, 1, 0)
    p5 = Point(0, 0, 1)
    p6 = Point(1, 0, 1)
    p7 = Point(1, 1, 1)
    p8 = Point(0, 1, 1)

    # Define rectangles with consistent outward-facing normals
    rect1 = Face(LP(p1, p4, p3, p2))  # Bottom face
    rect2 = Face(LP(p5, p6, p7, p8))  # Top face
    rect3 = Face(LP(p1, p2, p6, p5))  # Front face
    rect4 = Face(LP(p2, p3, p7, p6))  # Right face
    rect5 = Face(LP(p3, p4, p8, p7))  # Back face
    rect6 = Face(LP(p4, p1, p5, p8))  # Left face

    shell = Shell(List[Face](rect1, rect2, rect3, rect4, rect5, rect6))
    print(repr(shell))
    print("")

    # Display vector normals
    print("Display vector normals for surfaces")
    print("Bottom face -", repr(rect1.normal()))
    print("Top face -", repr(rect2.normal()))
    print("Front face -", repr(rect3.normal()))
    print("Right face -", repr(rect4.normal()))
    print("Back face -", repr(rect5.normal()))
    print("Left face -", repr(rect6.normal()))
