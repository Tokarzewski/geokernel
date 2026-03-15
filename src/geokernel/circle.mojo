from geokernel import FType, Point, Vector3
from math import sqrt, pi, cos, sin


struct Circle(Copyable, Movable, ImplicitlyCopyable):
    var center: Point
    var normal: Vector3
    var radius: FType

    fn __init__(out self, center: Point, normal: Vector3, radius: FType):
        self.center = center
        self.normal = normal
        self.radius = radius

    fn __copyinit__(out self, copy: Self):
        self.center = copy.center
        self.normal = copy.normal
        self.radius = copy.radius

    fn __moveinit__(out self, deinit take: Self):
        self.center = take.center
        self.normal = take.normal
        self.radius = take.radius

    fn point_at(self, t: FType) -> Point:
        """Return parametric point on circle. t=0..1 maps to full circle (2*pi)."""
        var angle = t * 2.0 * pi

        # Build a local coordinate frame in the plane of the circle
        # Find two vectors perpendicular to the normal
        var n = self.normal.normalize()

        # Pick an arbitrary vector not parallel to n
        var arbitrary: Vector3
        if abs(n.x) < 0.9:
            arbitrary = Vector3(1.0, 0.0, 0.0)
        else:
            arbitrary = Vector3(0.0, 1.0, 0.0)

        var u = n.cross(arbitrary).normalize()
        var v = n.cross(u).normalize()

        var x = self.center.x + self.radius * (cos(angle) * u.x + sin(angle) * v.x)
        var y = self.center.y + self.radius * (cos(angle) * u.y + sin(angle) * v.y)
        var z = self.center.z + self.radius * (cos(angle) * u.z + sin(angle) * v.z)

        return Point(x, y, z)

    fn start_point(self) -> Point:
        return self.point_at(0.0)

    fn end_point(self) -> Point:
        return self.point_at(1.0)

    fn length(self) -> FType:
        """Circumference of the circle."""
        return 2.0 * pi * self.radius

    fn is_closed(self) -> Bool:
        return True

    fn contains_point(self, p: Point, atol: FType) -> Bool:
        """Check if point lies on the circle (within tolerance)."""
        # Project p onto the circle plane, then check radius
        var n = self.normal.normalize()
        var cp = Vector3(
            p.x - self.center.x,
            p.y - self.center.y,
            p.z - self.center.z,
        )
        # Distance from center to p projected onto plane
        var dist_along_normal = cp.dot(n)
        # Check point is in the plane
        if abs(dist_along_normal) > atol:
            return False
        # Check radial distance
        var in_plane = Vector3(
            cp.x - dist_along_normal * n.x,
            cp.y - dist_along_normal * n.y,
            cp.z - dist_along_normal * n.z,
        )
        var radial_dist = in_plane.length()
        return abs(radial_dist - self.radius) < atol

    fn project_point(self, p: Point) -> Point:
        """Closest point on the circle to p."""
        var n = self.normal.normalize()
        # Project p onto circle plane
        var cp = Vector3(p.x - self.center.x, p.y - self.center.y, p.z - self.center.z)
        var dist_n = cp.dot(n)
        var in_plane = Vector3(
            cp.x - dist_n * n.x,
            cp.y - dist_n * n.y,
            cp.z - dist_n * n.z,
        )
        var r = in_plane.length()
        if r < 1e-14:
            # p projects onto center — pick arbitrary point on circle
            return self.point_at(0.0)
        var scale = self.radius / r
        return Point(
            self.center.x + in_plane.x * scale,
            self.center.y + in_plane.y * scale,
            self.center.z + in_plane.z * scale,
        )

    fn distance_to_point(self, p: Point) -> FType:
        """Distance from p to the closest point on the circle."""
        var closest = self.project_point(p)
        var dx = closest.x - p.x
        var dy = closest.y - p.y
        var dz = closest.z - p.z
        return sqrt(dx * dx + dy * dy + dz * dz)

    fn __repr__(self) -> String:
        return (
            "Circle(center="
            + self.center.__repr__()
            + ", normal="
            + self.normal.__repr__()
            + ", radius="
            + String(self.radius)
            + ")"
        )
