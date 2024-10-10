from geokernel import Point, Face, Cell


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
    rect1 = Face(List[Point](p1, p4, p3, p2))  # Bottom face
    rect2 = Face(List[Point](p5, p6, p7, p8))  # Top face
    rect3 = Face(List[Point](p1, p2, p6, p5))  # Front face
    rect4 = Face(List[Point](p2, p3, p7, p6))  # Right face
    rect5 = Face(List[Point](p3, p4, p8, p7))  # Back face
    rect6 = Face(List[Point](p4, p1, p5, p8))  # Left face

    cube = Cell(List[Face](rect1, rect2, rect3, rect4, rect5, rect6))
    print(repr(cube))
    print("cube area:", cube.area())
    print("cube volume:", cube.volume())
