from geokernel import FType, Point, Line, Wire, Vector3, Cell, Transform, Quaternion
from math import sqrt


struct Face(Copyable, Movable, ImplicitlyCopyable):
    var points: List[Point]

    fn __init__(out self, points: List[Point]):
        self.points = points.copy()
        if self.points[0] != self.points[-1]:
            self.points.append(self.points[0])


    fn __copyinit__(out self, copy: Self):
        self.points = copy.points.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.points = take.points^

    fn __repr__(self) -> String:
        var result: String = "Face("
        for i in range(len(self.points)):
            if i > 0:
                result += ", "
            result += self.points[i].__repr__()
        return result + ")"

    fn reverse(var self) -> Self:
        self.points.reverse()
        return self

    fn num_vertices(self) -> Int:
        return len(self.points) - 1

    fn num_edges(self) -> Int:
        return len(self.points) - 1

    fn get_vertex(self, i: Int) -> Point:
        return self.points[i]

    fn get_edge(self, i: Int) -> Line:
        return Line(self.points[i], self.points[(i + 1)])

    fn wire(self) -> Wire:
        return Wire(self.points)

    fn move(self, dx: FType, dy: FType, dz: FType) -> Self:
        var moved_points = List[Point]()
        for i in range(len(self.points)):
            moved_points.append(self.points[i].move(dx, dy, dz))
        return Self(moved_points)

    fn move_by_vector(self, v: Vector3) -> Self:
        return self.move(v.x, v.y, v.z)

    fn transform(self, t: Transform) -> Self:
        """Apply a Transform to all points of the face."""
        var transformed_points = List[Point]()
        for i in range(len(self.points)):
            transformed_points.append(self.points[i].transform(t))
        return Self(transformed_points)

    fn rotate(self, q: Quaternion) -> Self:
        var rotated = List[Point]()
        for i in range(len(self.points)):
            rotated.append(self.points[i].rotate(q))
        return Self(rotated)

    fn perimeter(self) -> FType:
        var total_length: FType = 0
        for i in range(self.num_edges()):
            total_length += self.get_edge(i).length()
        return total_length

    fn area(self) -> FType:
        var ref_point = self.points[0]
        var normal = Vector3(0, 0, 0)

        for i in range(1, self.num_vertices() - 1):
            var v1 = Vector3.from_points(ref_point, self.points[i])
            var v2 = Vector3.from_points(ref_point, self.points[i + 1])
            normal += v1.cross(v2)

        return normal.length() / 2.0

    fn normal(self) -> Vector3:
        var p1 = self.points[0]
        var p2 = self.points[1]
        var v1 = Vector3.from_points(p1, p2)

        for i in range(self.num_vertices()):
            var p3 = self.points[(i + 2)]
            var v2 = Vector3.from_points(p1, p3)
            var cross_product = v1.cross(v2)
            if cross_product.length() > 0:
                return cross_product.normalize()
        return Vector3(0, 0, 0)

    fn centroid(self) -> Point:
        var weighted_sum = Point(0, 0, 0)
        var total_area: FType = 0.0

        for i in range(self.num_vertices()):
            var p1 = self.points[i]
            var p2 = self.points[(i + 1) % self.num_vertices()]
            var p3 = self.points[(i + 2) % self.num_vertices()]

            var triangle = Face([p1, p2, p3])
            var triangle_area = triangle.area()
            var triangle_centroid = (p1 + p2 + p3) / 3

            weighted_sum += triangle_centroid * triangle_area
            total_area += triangle_area

        return weighted_sum / total_area

    fn is_planar(self, atol: FType = 1e-10) -> Bool:
        """Check if all vertices lie on the same plane."""
        if self.num_vertices() <= 3:
            return True
        var n = self.normal()
        var origin = self.points[0]
        for i in range(1, self.num_vertices()):
            var d = Vector3.from_points(origin, self.points[i])
            if abs(n.dot(d)) > atol:
                return False
        return True

    fn project_point(self, p: Point) -> Point:
        """Project 3D point onto face plane."""
        var n = self.normal()
        var origin = self.points[0]
        var d = Vector3.from_points(origin, p)
        var dist = n.dot(d)
        return Point(
            p.x - n.x * dist,
            p.y - n.y * dist,
            p.z - n.z * dist,
        )

    fn contains_point_2d(self, p: Point, atol: FType = 1e-10) -> Bool:
        """Point-in-polygon test using ray casting (2D projection).
        Projects all points onto the face plane first."""
        var n = self.normal().normalize()

        # Build local 2D coordinate system
        var ref_v = Vector3(0.0, 0.0, 1.0)
        if abs(n.dot(ref_v)) > 0.9:
            ref_v = Vector3(1.0, 0.0, 0.0)
        var u = n.cross(ref_v).normalize()
        var v = n.cross(u).normalize()

        var origin = self.points[0]

        # Project polygon vertices
        var poly_x = List[FType]()
        var poly_y = List[FType]()
        for i in range(self.num_vertices()):
            var d = Vector3.from_points(origin, self.points[i])
            poly_x.append(d.dot(u))
            poly_y.append(d.dot(v))

        # Project query point (first project onto plane)
        var pp = self.project_point(p)
        var dp = Vector3.from_points(origin, pp)
        var px = dp.dot(u)
        var py = dp.dot(v)

        # Ray casting
        var inside = False
        var num = len(poly_x)
        var j = num - 1
        for i in range(num):
            var xi = poly_x[i]
            var yi = poly_y[i]
            var xj = poly_x[j]
            var yj = poly_y[j]
            var crosses = ((yi > py) != (yj > py))
            if crosses:
                var x_intersect = (xj - xi) * (py - yi) / (yj - yi) + xi
                if px < x_intersect:
                    inside = not inside
            j = i
        return inside

    fn triangulate(self) -> List[Face]:
        """Fan triangulation. Returns list of triangle faces."""
        var result = List[Face]()
        var n = self.num_vertices()
        for i in range(1, n - 1):
            var tri_pts = List[Point]()
            tri_pts.append(self.points[0])
            tri_pts.append(self.points[i])
            tri_pts.append(self.points[i + 1])
            result.append(Face(tri_pts))
        return result.copy()

    fn push_pull(self, distance: Float64) -> Shell:
        """Extrude this face along its normal by the given distance, returning the resulting Shell."""
        var n = self.normal()
        var v = n * distance
        var top = self.move_by_vector(v)
        var sides = self.wire().extrude(v)
        var faces = List[Face]()
        faces.append(self)
        faces.append(top)
        for i in range(len(sides.faces)):
            faces.append(sides.faces[i])
        return Shell(faces)

    fn intersects_line(self, l: Line) -> Bool:
        """True if the line segment intersects this face."""
        return self.intersect_line(l) is not None

    fn intersect_line(self, l: Line) -> Optional[Point]:
        """Intersection point of a line segment with this face plane, or None."""
        var n = self.normal()
        var denom = n.dot(l.direction())
        if abs(denom) < 1e-12:
            return None  # parallel
        var d = Vector3.from_points(l.p1, self.points[0])
        var t = n.dot(d) / denom
        if t < 0.0 or t > 1.0:
            return None  # outside segment range
        var hit = l.point_at(t)
        if self.contains_point_2d(hit):
            return hit
        return None

    fn extrude(self, v: Vector3) -> Cell:
        var faces = List[Face]()
        faces.append(self)  # original polygon
        faces.append(self.move_by_vector(v))  # moved polygon
        faces.extend(self.wire().extrude(v).faces)  # sides
        return Cell(faces)


# Rotate, Scale, Transform
# Boolean operations 2D
