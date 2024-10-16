from geokernel import Point


@value
struct AABB:
    """Axis Aligned Bounding Box."""

    var p_min: Point
    var p_max: Point

    fn __init__(inout self, p_min: Point, p_max: Point):
        """Simple and efficient way to define AABB
        if you can't define p_min and p_max correctly, use 2nd init method.
        """
        self.p_min = p_min
        self.p_max = p_max

    fn __init__(inout self, points: List[Point]):
        self.p_min = points[0]
        self.p_max = points[0]
        self.extend(points)

    fn __repr__(self) -> String:
        return "AABB(" + repr(self.p_min) + ", " + repr(self.p_max) + ")"

    fn contains(self, point: Point) -> Bool:
        return self.p_min <= point <= self.p_max

    fn extend(inout self, points: List[Point]):
        for i in range(0, points.size):
            self.p_min = Point.min(self.p_min, points[i])
            self.p_max = Point.max(self.p_max, points[i])
