from geokernel import Cell, Point

def main() raises:
    var c = Cell.from_two_points(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    print(len(c.faces))
