from geokernel import Point


@value
struct AABB:
    """Axis Aligned Bounding Box."""

    var p_min: Point
    var p_max: Point

    fn __repr__(self) -> String:
        return "AABB(" + repr(self.p_min) + ", " + repr(self.p_max) + ")"

    fn contains(self, point: Point) -> Bool:
        return (
            self.p_min.x <= point.x <= self.p_max.x
            and self.p_min.y <= point.y <= self.p_max.y
            and self.p_min.z <= point.z <= self.p_max.z
        )

    fn extend(inout self, point: Point) -> Self:
        self.p_min = Point(
            min(self.p_min.x, point.x),
            min(self.p_min.y, point.y),
            min(self.p_min.z, point.z),
        )
        self.p_max = Point(
            max(self.p_max.x, point.x),
            max(self.p_max.y, point.y),
            max(self.p_max.z, point.z),
        )
        return self
