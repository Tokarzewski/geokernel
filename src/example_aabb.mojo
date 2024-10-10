from geokernel import AABB, Point


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(10, 10, 10)

    aabb1 = AABB(p1, p2)
    p3 = Point(5, 5, 5)

    print("Is p3 inside aabb1?:", aabb1.contains(p3))
