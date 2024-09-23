from geokernel import FType, Point, Vector


@value
struct Plane:
    var point: Point
    var vector: Vector

    fn __init__(inout self, point: Point, vector: Vector):
        self.point = point
        self.vector = vector.normalize()

    @staticmethod
    fn from_points(p1: Point, p2: Point, p3: Point) -> Self:
        """Create a plane from three non-collinear points."""
        var v1 = Vector.from_point(p2) - Vector.from_point(p1)
        var v2 = Vector.from_point(p3) - Vector.from_point(p1)
        var normal = v1.cross(v2).normalize()
        return Self(p1, normal)

    fn distance_to_point(self, point: Point) -> FType:
        """Calculate the signed distance from a point to the plane."""
        var p2p_vec = Vector.from_point(point) - Vector.from_point(self.point)
        return self.vector.dot(p2p_vec)

    fn project_point(self, point: Point) -> Point:
        """Project a point onto the plane."""
        var distance = self.distance_to_point(point)
        var projection_vector = self.vector * distance
        return Point(
            point.x - projection_vector.x,
            point.y - projection_vector.y,
            point.z - projection_vector.z,
        )

    fn __repr__(self) -> String:
        return (
            "Plane(point="
            + repr(self.point)
            + ", vector="
            + repr(self.vector)
            + ")"
        )
