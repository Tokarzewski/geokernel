from geokernel import Point, Face, Cell


fn main():
    var p1 = Point(0, 0, 0)
    var p2 = Point(1, 0, 0)
    var p3 = Point(1, 1, 0)
    var p4 = Point(0, 1, 0)
    var p5 = Point(0, 0, 1)
    var p6 = Point(1, 0, 1)
    var p7 = Point(1, 1, 1)
    var p8 = Point(0, 1, 1)

    # Define squares with consistent outward-facing normals
    var square1 = Face(List[Point](p1, p4, p3, p2))  # Bottom face
    var square2 = Face(List[Point](p5, p6, p7, p8))  # Top face
    var square3 = Face(List[Point](p1, p2, p6, p5))  # Front face
    var square4 = Face(List[Point](p2, p3, p7, p6))  # Right face
    var square5 = Face(List[Point](p3, p4, p8, p7))  # Back face
    var square6 = Face(List[Point](p4, p1, p5, p8))  # Left face

    var cube = Cell(
        List[Face](square1, square2, square3, square4, square5, square6)
    )
    print(repr(cube))
    print("cube area:", cube.area())
    print("cube volume:", cube.volume())
