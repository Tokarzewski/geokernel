from geokernel import FType, Point, Vector3
from std.math import sqrt


struct PointInPolygon:
    @staticmethod
    def ray_cast_2d(
        px: FType,
        py: FType,
        polygon_x: List[FType],
        polygon_y: List[FType],
    ) -> Bool:
        """Ray casting algorithm. Returns True if point is inside polygon."""
        var n = len(polygon_x)
        var inside = False
        var j = n - 1
        for i in range(n):
            var xi = polygon_x[i]
            var yi = polygon_y[i]
            var xj = polygon_x[j]
            var yj = polygon_y[j]
            # Check if the edge crosses the horizontal ray from (px, py) in +x direction
            var crosses = ((yi > py) != (yj > py))
            if crosses:
                var x_intersect = (xj - xi) * (py - yi) / (yj - yi) + xi
                if px < x_intersect:
                    inside = not inside
            j = i
        return inside

    @staticmethod
    def classify(p: Point, face_points: List[Point], face_normal: Vector3) -> Bool:
        """Project 3D points onto 2D plane aligned with normal, then ray cast."""
        # Build a local 2D coordinate system on the plane
        # u = any vector perpendicular to normal
        var n = face_normal.normalize()

        # Choose a reference vector not parallel to n
        var helper = Vector3(0.0, 0.0, 1.0)
        if abs(n.dot(helper)) > 0.9:
            helper = Vector3(1.0, 0.0, 0.0)

        var u = n.cross(helper).normalize()
        var v = n.cross(u).normalize()

        # Project each face vertex onto 2D
        var poly_x = List[FType]()
        var poly_y = List[FType]()
        var origin = face_points[0]
        for i in range(len(face_points)):
            var d = Vector3.from_points(origin, face_points[i])
            poly_x.append(d.dot(u))
            poly_y.append(d.dot(v))

        # Project query point p
        var dp = Vector3.from_points(origin, p)
        var px = dp.dot(u)
        var py = dp.dot(v)

        return PointInPolygon.ray_cast_2d(px, py, poly_x, poly_y)
