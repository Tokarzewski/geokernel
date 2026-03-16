from geokernel import FType, Point, Line, Wire, Vector3, Cell, Transform, Quaternion, Plane
from math import sqrt


struct Face(Copyable, Movable, ImplicitlyCopyable):
    var points: List[Point]

    fn __init__(out self, points: List[Point]):
        self.points = points.copy()
        if len(self.points) > 0 and self.points[0] != self.points[-1]:
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


# ---------------------------------------------------------------------------
# Face-face intersection
# ---------------------------------------------------------------------------

fn _normals_parallel_ff(a: Face, b: Face, atol: FType = 1e-10) -> Bool:
    """Return True if the two face normals are parallel (same or opposite direction)."""
    var na = a.normal().normalize()
    var nb = b.normal().normalize()
    return na.cross(nb).length() < atol


fn _coplanar_faces(a: Face, b: Face, atol: FType = 1e-10) -> Bool:
    """Return True if a and b lie on the same infinite plane."""
    if not _normals_parallel_ff(a, b, atol):
        return False
    var na = a.normal().normalize()
    var d = Vector3.from_points(a.get_vertex(0), b.get_vertex(0))
    return abs(na.dot(d)) < atol


fn _clip_polygon_by_halfplane(
    pts: List[Point],
    edge_a: Point,
    edge_b: Point,
    u: Vector3,
    v: Vector3,
    origin: Point,
) -> List[Point]:
    """Sutherland-Hodgman single edge clip step in 2D (projected)."""
    var output = List[Point]()
    var n = len(pts)
    if n == 0:
        return output^

    fn project2d(p: Point) -> Tuple[FType, FType]:
        var dv = Vector3.from_points(origin, p)
        return (dv.dot(u), dv.dot(v))

    fn inside(p: Point) -> Bool:
        var pp = project2d(p)
        var pa = project2d(edge_a)
        var pb = project2d(edge_b)
        var cross = (pb[0] - pa[0]) * (pp[1] - pa[1]) - (pb[1] - pa[1]) * (pp[0] - pa[0])
        return cross >= -1e-15

    fn intersect_edge(p1: Point, p2: Point) -> Point:
        var a2d = project2d(p1)
        var b2d = project2d(p2)
        var ea = project2d(edge_a)
        var eb = project2d(edge_b)
        # Line-line intersection in 2D
        var a1 = eb[1] - ea[1]
        var b1 = ea[0] - eb[0]
        var c1 = a1 * ea[0] + b1 * ea[1]
        var a2 = b2d[1] - a2d[1]
        var b2 = a2d[0] - b2d[0]
        var c2 = a2 * a2d[0] + b2 * a2d[1]
        var det = a1 * b2 - a2 * b1
        if abs(det) < 1e-15:
            return p1
        var ix = (b2 * c1 - b1 * c2) / det
        var iy = (a1 * c2 - a2 * c1) / det
        # Interpolate t along p1->p2
        var dx = b2d[0] - a2d[0]
        var dy = b2d[1] - a2d[1]
        var t: FType = 0.0
        if abs(dx) > abs(dy):
            t = (ix - a2d[0]) / dx if abs(dx) > 1e-15 else 0.0
        else:
            t = (iy - a2d[1]) / dy if abs(dy) > 1e-15 else 0.0
        var iz = p1.z + t * (p2.z - p1.z)
        # Reconstruct 3D point from 2D coords
        var pt = origin + Vector3.to_point(u * ix + v * iy)
        return Point(pt.x, pt.y, p1.z + t * (p2.z - p1.z))

    for j in range(n):
        var cur = pts[j]
        var prev = pts[(j + n - 1) % n]
        var cur_in = inside(cur)
        var prev_in = inside(prev)
        if cur_in:
            if not prev_in:
                output.append(intersect_edge(prev, cur))
            output.append(cur)
        elif prev_in:
            output.append(intersect_edge(prev, cur))
    return output^


fn _build_2d_basis(normal: Vector3) -> Tuple[Vector3, Vector3]:
    """Build an orthonormal 2D basis (u, v) for the given normal."""
    var n = normal.normalize()
    var ref_v = Vector3(0.0, 0.0, 1.0)
    if abs(n.dot(ref_v)) > 0.9:
        ref_v = Vector3(1.0, 0.0, 0.0)
    var u = n.cross(ref_v).normalize()
    var v = n.cross(u).normalize()
    return (u, v)


fn _project_2d(p: Point, origin: Point, u: Vector3, v: Vector3) -> Tuple[FType, FType]:
    """Project 3D point onto local 2D coords."""
    var d = Vector3.from_points(origin, p)
    return (d.dot(u), d.dot(v))


fn intersect_faces(f1: Face, f2: Face, atol: FType = 1e-10) -> Optional[Wire]:
    """Compute the intersection of two faces.

    Cases:
    - Coplanar + overlapping: return Wire of intersection polygon.
    - Non-coplanar: compute the intersection line of the two planes, then
      clip against each face to find the shared segment. Returns a 2-vertex Wire.
    - No intersection: return None.
    """
    if _coplanar_faces(f1, f2, atol):
        # Clip f1 against f2 as convex polygons (Sutherland-Hodgman)
        var n1 = f1.normal().normalize()
        var basis = _build_2d_basis(n1)
        var u = basis[0]
        var v = basis[1]
        var origin = f1.get_vertex(0)

        # Build open vertex lists
        var pts1 = List[Point]()
        for i in range(f1.num_vertices()):
            pts1.append(f1.get_vertex(i))
        var pts2 = List[Point]()
        for i in range(f2.num_vertices()):
            pts2.append(f2.get_vertex(i))

        # Clip pts1 against each edge of pts2
        var output = pts1.copy()
        var n_clip = len(pts2)
        for ei in range(n_clip):
            if len(output) == 0:
                break
            output = _clip_polygon_by_halfplane(
                output, pts2[ei], pts2[(ei + 1) % n_clip], u, v, origin
            )

        if len(output) < 2:
            return None

        # Build a closed Wire from the intersection polygon
        var wire_pts = List[Point]()
        for i in range(len(output)):
            wire_pts.append(output[i])
        # close the wire
        wire_pts.append(output[0])
        return Wire(wire_pts)

    else:
        # Non-coplanar: find the intersection line of the two planes
        var n1 = f1.normal().normalize()
        var n2 = f2.normal().normalize()

        # Direction of intersection line = cross(n1, n2)
        var line_dir = n1.cross(n2)
        if line_dir.length() < atol:
            return None  # parallel normals (already handled above, but guard)

        line_dir = line_dir.normalize()

        # Find a point on the intersection line via solving the 2-plane system
        # n1·p = d1, n2·p = d2  (where d = n·origin)
        var d1 = n1.dot(Vector3.from_point(f1.get_vertex(0)))
        var d2 = n2.dot(Vector3.from_point(f2.get_vertex(0)))

        # Use the approach: pick the axis with largest |line_dir| component
        var abs_x = abs(line_dir.x)
        var abs_y = abs(line_dir.y)
        var abs_z = abs(line_dir.z)

        var pt_on_line: Point
        if abs_z >= abs_x and abs_z >= abs_y:
            # Set z=0, solve for x,y
            var a11 = n1.x; var a12 = n1.y
            var a21 = n2.x; var a22 = n2.y
            var det = a11 * a22 - a12 * a21
            if abs(det) < 1e-15:
                return None
            var px = (d1 * a22 - d2 * a12) / det
            var py = (a11 * d2 - a21 * d1) / det
            pt_on_line = Point(px, py, 0.0)
        elif abs_y >= abs_x:
            # Set y=0, solve for x,z
            var a11 = n1.x; var a12 = n1.z
            var a21 = n2.x; var a22 = n2.z
            var det = a11 * a22 - a12 * a21
            if abs(det) < 1e-15:
                return None
            var px = (d1 * a22 - d2 * a12) / det
            var pz = (a11 * d2 - a21 * d1) / det
            pt_on_line = Point(px, 0.0, pz)
        else:
            # Set x=0, solve for y,z
            var a11 = n1.y; var a12 = n1.z
            var a21 = n2.y; var a22 = n2.z
            var det = a11 * a22 - a12 * a21
            if abs(det) < 1e-15:
                return None
            var py = (d1 * a22 - d2 * a12) / det
            var pz = (a11 * d2 - a21 * d1) / det
            pt_on_line = Point(0.0, py, pz)

        # Parametrise: points on intersection line = pt_on_line + t * line_dir
        # For each face, project its edges onto the line and collect t-intervals
        fn face_t_interval(face: Face) -> Optional[Tuple[FType, FType]]:
            """Compute the parameter interval [t_min, t_max] where the intersection
            line passes through the face (via edge crossings)."""
            var t_vals = List[FType]()
            var nv = face.num_vertices()
            var n_face = face.normal().normalize()

            for ei in range(nv):
                var ea = face.get_vertex(ei)
                var eb = face.get_vertex((ei + 1) % nv)
                # Project ea, eb onto the plane's line direction
                # First: how far each endpoint is above/below the intersection line's plane
                # We check if edge ea->eb crosses the "half-plane" boundary.
                # Actually, clip the edge against the intersection line parameter:
                # The intersection line lies in the plane of f1 AND f2.
                # For a given face, an edge crosses the line if the two endpoints
                # are on opposite sides of the line (in 3D, use another plane through line).
                # Easier: parametrise the segment ea->eb, find where it hits the line.
                # Since the intersection line is in both planes, for face edges we want
                # where the edge (a 3D segment) is closest to the intersection line.
                # Better approach: project face vertices onto line direction parameter t,
                # then check if the face "contains" the line.

                # Use: for face f, find all edge-intersection-line crossings:
                # Edge ea->eb parametrised as ea + s*(eb-ea), s in [0,1].
                # The intersection line: pt_on_line + t*line_dir.
                # These are nearest-approach computation: if distance < atol → crossing.

                # Simpler: project each vertex onto line direction t, and for each edge
                # check if the edge actually intersects the plane of the OTHER face at some t.
                # We'll collect t-params of where each face's edges cross the intersection line.

                # For a face edge to "see" the intersection line, we project the edge
                # onto the line's direction parameter. The edge lies in the face plane.
                # Find the t where the edge crosses the intersection line direction:
                # Parametric: P(s) = ea + s*(eb-ea)
                # Distance to line (pt_on_line, line_dir): 
                #   vec = P(s) - pt_on_line
                #   component perp to line_dir = vec - (vec·line_dir)*line_dir
                # Minimize distance → solve for s where perp component = 0... complex.
                # 
                # Cleaner: The intersection line is the intersection of the two planes.
                # For face edges, we can check if the edge crosses the intersection line
                # by testing the signed distance of each endpoint to the OTHER face's plane.
                # If opposite signs → the edge crosses the plane → compute crossing t.
                pass

            # Alternative: use the plane of the other face to clip face edges
            return None

        # Use plane-based clipping: project each face's edges against the other plane
        # to find where the intersection line enters/exits each face.

        # For f1: clip its edges against plane of f2 → collect t-values on line_dir
        # For f2: clip its edges against plane of f1 → collect t-values on line_dir

        fn collect_edge_crossings(face: Face, plane_n: Vector3, plane_d: FType) -> List[FType]:
            """Find t-params where face edges cross the given plane."""
            var ts = List[FType]()
            var nv = face.num_vertices()
            for ei in range(nv):
                var ea = face.get_vertex(ei)
                var eb = face.get_vertex((ei + 1) % nv)
                var da = plane_n.dot(Vector3.from_point(ea)) - plane_d
                var db = plane_n.dot(Vector3.from_point(eb)) - plane_d
                if (da > atol and db < -atol) or (da < -atol and db > atol):
                    # Edge crosses plane
                    var s = da / (da - db)
                    var px = ea.x + s * (eb.x - ea.x)
                    var py = ea.y + s * (eb.y - ea.y)
                    var pz = ea.z + s * (eb.z - ea.z)
                    var cross_pt = Point(px, py, pz)
                    # Project onto intersection line
                    var delta = Vector3.from_points(pt_on_line, cross_pt)
                    var t = delta.dot(line_dir)
                    ts.append(t)
                elif abs(da) <= atol:
                    var delta = Vector3.from_points(pt_on_line, ea)
                    ts.append(delta.dot(line_dir))
                elif abs(db) <= atol:
                    var delta = Vector3.from_points(pt_on_line, eb)
                    ts.append(delta.dot(line_dir))
            return ts^

        var d2_val = n2.dot(Vector3.from_point(f2.get_vertex(0)))
        var d1_val = n1.dot(Vector3.from_point(f1.get_vertex(0)))

        var ts1 = collect_edge_crossings(f1, n2, d2_val)
        var ts2 = collect_edge_crossings(f2, n1, d1_val)

        if len(ts1) < 2 or len(ts2) < 2:
            return None

        # Find min/max t for each face
        var t1_min = ts1[0]; var t1_max = ts1[0]
        for i in range(1, len(ts1)):
            if ts1[i] < t1_min: t1_min = ts1[i]
            if ts1[i] > t1_max: t1_max = ts1[i]

        var t2_min = ts2[0]; var t2_max = ts2[0]
        for i in range(1, len(ts2)):
            if ts2[i] < t2_min: t2_min = ts2[i]
            if ts2[i] > t2_max: t2_max = ts2[i]

        # Overlap of [t1_min, t1_max] and [t2_min, t2_max]
        var t_start = t1_min if t1_min > t2_min else t2_min
        var t_end   = t1_max if t1_max < t2_max else t2_max

        if t_start > t_end + atol:
            return None  # no overlap

        # Build the 2-point Wire
        var p_start = Point(
            pt_on_line.x + t_start * line_dir.x,
            pt_on_line.y + t_start * line_dir.y,
            pt_on_line.z + t_start * line_dir.z,
        )
        var p_end = Point(
            pt_on_line.x + t_end * line_dir.x,
            pt_on_line.y + t_end * line_dir.y,
            pt_on_line.z + t_end * line_dir.z,
        )
        var wire_pts = List[Point]()
        wire_pts.append(p_start)
        wire_pts.append(p_end)
        return Wire(wire_pts)


# Rotate, Scale, Transform
# Boolean operations 2D
