from geokernel import Point, Face, Cell, LP, AABB


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(0, 1, 0)
    p3 = Point(1, 1, 0)
    p4 = Point(1, 0, 0)

    p5 = Point(0, 0, 1)
    p6 = Point(0, 1, 1)
    p7 = Point(1, 1, 1)
    p8 = Point(1, 0, 1)

    # Define rectangles with consistent outward-facing normals
    rect1 = Face(LP(p3, p7, p8, p4))  # Right face (+X)
    rect2 = Face(LP(p1, p5, p6, p2))  # Left face (-X)

    rect3 = Face(LP(p2, p6, p7, p3))  # Back face (+Y)
    rect4 = Face(LP(p1, p4, p8, p5))  # Front face (-Y)

    rect5 = Face(LP(p1, p2, p3, p4))  # Bottom face (-Z)
    rect6 = Face(LP(p5, p8, p7, p6))  # Top face (+Z)

    cube1 = Cell(List[Face](rect1, rect2, rect3, rect4, rect5, rect6))

    print(repr(cube1))
    print("cube area:", cube1.area())
    print("cube volume:", cube1.volume())

    cube2 = Cell.from_two_points(p1, p7)

    print(repr(cube2))
    print("cube area:", cube2.area())
    print("cube volume:", cube2.volume())
