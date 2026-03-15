from geokernel import Point


struct AABB(Copyable, Movable, ImplicitlyCopyable):
    """Axis Aligned Bounding Box."""

    var p_min: Point
    var p_max: Point

    fn __init__(out self, p_min: Point, p_max: Point):
        """Simple and efficient way to define AABB
        if you can't define p_min and p_max correctly, use 2nd init method.
        """
        self.p_min = p_min
        self.p_max = p_max

    fn __init__(out self, points: List[Point]):
        self.p_min = points[0]
        self.p_max = points[0]
        self.extend(points)


    fn __copyinit__(out self, copy: Self):
        self.p_min = copy.p_min
        self.p_max = copy.p_max

    fn __moveinit__(out self, deinit take: Self):
        self.p_min = take.p_min
        self.p_max = take.p_max

    fn __repr__(self) -> String:
        return "AABB(" + self.p_min.__repr__() + ", " + self.p_max.__repr__() + ")"

    fn contains(self, point: Point) -> Bool:
        return self.p_min <= point <= self.p_max

    fn extend(mut self, points: List[Point]):
        for i in range(0, len(points)):
            self.p_min = Point.min(self.p_min, points[i])
            self.p_max = Point.max(self.p_max, points[i])
