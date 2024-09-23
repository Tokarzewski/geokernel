from geokernel import BoundingBox, Point


fn main():
    var p1 = Point(0, 0, 0)
    var p2 = Point(10, 10, 10)

    var BBOX1 = BoundingBox(p1, p2)
    var p3 = Point(5, 5, 5)
    print("Is p3 in BBOX?:", BBOX1.contains(p3))
