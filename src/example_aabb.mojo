from geokernel import AABB, Point, LP


fn main():
    p1 = Point(0, 0, 0)
    p2 = Point(10, 10, 10)
    p4 = Point(-10, -10, -10)
    p5 = Point(15, 15, 15)

    aabb1 = AABB(p1, p2)
    aabb1 = aabb1.extend(p4)
    aabb1 = aabb1.extend(p5)

    aabb2 = AABB(LP(p5, p2, p4, p1))

    p3 = Point(5, 5, 5)
    p6 = Point(20, 20, -20)

    print(repr(aabb1))
    print(repr(aabb2))

    print("Is p3 inside aabb1?:", aabb1.contains(p3))
    print("Is p6 inside aabb2?:", aabb2.contains(p6))
