from geokernel import FType, Point, Vector3


@value
struct Plane:
    var point: Point
    var vector: Vector3

    fn __init__(inout self, point: Point, vector: Vector3):
        """Create a plane from point and vector."""
        self.point = point
        self.vector = vector.normalize()

    fn __init__(inout self, p1: Point, p2: Point, p3: Point):
        """Create a plane from three non-collinear points."""
        var v1 = Vector3.from_point(p2) - Vector3.from_point(p1)
        var v2 = Vector3.from_point(p3) - Vector3.from_point(p1)
        var normal = v1.cross(v2).normalize()
        self.point = p1
        self.vector = normal

    fn __repr__(self) -> String:
        return "Plane(point=" + repr(self.point) + ", vector=" + repr(self.vector) + ")"

    fn distance_to_point(self, point: Point) -> FType:
        """Calculate the signed distance from a point to the plane."""
        return self.vector.dot(Vector3.from_points(self.point, point))

    fn project_point(self, point: Point) -> Point:
        """Project a point onto the plane."""
        var singed_distance = self.distance_to_point(point)
        var projection_vector = self.vector * singed_distance
        return point - Vector3.to_point(projection_vector)
