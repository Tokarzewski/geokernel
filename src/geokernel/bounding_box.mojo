from geokernel import Point


@value
struct BoundingBox:
    var p_min: Point
    var p_max: Point

    fn __repr__(self) -> String:
        return "BoundingBox(" + repr(self.p_min) + ", " + repr(self.p_max) + ")"

    fn contains(self, point: Point) -> Bool:
        return (
            self.p_min.x <= point.x <= self.p_max.x
            and self.p_min.y <= point.y <= self.p_max.y
            and self.p_min.z <= point.z <= self.p_max.z
        )
