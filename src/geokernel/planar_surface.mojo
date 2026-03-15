from geokernel import FType, Point, Vector3, Plane
from geokernel.surface import Surface
import math


struct PlanarSurface(Copyable, Movable, ImplicitlyCopyable, Surface):
    var plane: Plane
    var width: FType
    var height: FType

    fn __init__(out self, plane: Plane, width: FType, height: FType):
        self.plane = plane
        self.width = width
        self.height = height

    fn _local_axes(self) -> Tuple[Vector3, Vector3]:
        """Compute two orthogonal tangent vectors in the plane."""
        var n = self.plane.vector
        # Pick a vector not parallel to n
        var up = Vector3(0.0, 0.0, 1.0)
        if math.abs(n.dot(up)) > 0.99:
            up = Vector3(1.0, 0.0, 0.0)
        var u_axis = n.cross(up).normalize()
        var v_axis = n.cross(u_axis).normalize()
        return (u_axis, v_axis)

    fn point_at(self, u: FType, v: FType) -> Point:
        """Map u,v in [0,1] to a 3D point on the surface."""
        var axes = self._local_axes()
        var u_axis = axes[0]
        var v_axis = axes[1]
        # Center the surface on plane.point; u,v in [0,1] → [-w/2, w/2]
        var du = (u - 0.5) * self.width
        var dv = (v - 0.5) * self.height
        var offset = u_axis * du + v_axis * dv
        return self.plane.point.move(offset.x, offset.y, offset.z)

    fn normal_at(self, u: FType, v: FType) -> Vector3:
        """Return the constant plane normal."""
        return self.plane.vector

    fn area(self) -> FType:
        return self.width * self.height

    fn is_planar(self) -> Bool:
        return True

    fn project_point(self, p: Point) -> Point:
        """Project a point onto the plane."""
        return self.plane.project_point(p)

    fn contains_point(self, p: Point, atol: FType) -> Bool:
        """Check if a point lies on this finite planar surface."""
        # First check distance to plane
        var dist = self.plane.distance_to_point(p)
        if math.abs(dist) > atol:
            return False
        # Project point onto plane and check u,v bounds
        var proj = self.plane.project_point(p)
        var axes = self._local_axes()
        var u_axis = axes[0]
        var v_axis = axes[1]
        var diff = Vector3.from_points(self.plane.point, proj)
        var du = diff.dot(u_axis)
        var dv = diff.dot(v_axis)
        return (math.abs(du) <= self.width / 2.0 + atol) and (math.abs(dv) <= self.height / 2.0 + atol)

    fn __repr__(self) -> String:
        return (
            "PlanarSurface(plane="
            + self.plane.__repr__()
            + ", width="
            + str(self.width)
            + ", height="
            + str(self.height)
            + ")"
        )
