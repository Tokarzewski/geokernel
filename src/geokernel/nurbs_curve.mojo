from geokernel import FType, Point, Vector3
from std.math import sqrt


struct NurbsCurve(Copyable, Movable, ImplicitlyCopyable):
    var control_points: List[Point]
    var knots: List[FType]
    var degree: Int
    var weights: List[FType]

    def __init__(out self, control_points: List[Point], knots: List[FType], degree: Int, weights: List[FType]):
        self.control_points = control_points.copy()
        self.knots = knots.copy()
        self.degree = degree
        self.weights = weights.copy()

    def __init__(out self, *, copy: Self):
        self.control_points = copy.control_points.copy()
        self.knots = copy.knots.copy()
        self.degree = copy.degree
        self.weights = copy.weights.copy()

    def __init__(out self, *, deinit take: Self):
        self.control_points = take.control_points^
        self.knots = take.knots^
        self.degree = take.degree
        self.weights = take.weights^

    def num_control_points(self) -> Int:
        return len(self.control_points)

    def _find_knot_span(self, t: FType) -> Int:
        """Find the knot span index for parameter t using binary search."""
        var n = self.num_control_points() - 1
        var p = self.degree

        # Clamp t to valid range
        var t_clamped = t
        var t_min = self.knots[p]
        var t_max = self.knots[n + 1]
        if t_clamped <= t_min:
            return p
        if t_clamped >= t_max:
            return n

        var low = p
        var high = n + 1
        var mid = (low + high) // 2
        while t_clamped < self.knots[mid] or t_clamped >= self.knots[mid + 1]:
            if t_clamped < self.knots[mid]:
                high = mid
            else:
                low = mid
            mid = (low + high) // 2
        return mid

    def _basis_functions(self, span: Int, t: FType) -> List[FType]:
        """Compute B-spline basis functions N[0..degree] at t."""
        var p = self.degree
        var N = List[FType]()
        for _ in range(p + 1):
            N.append(0.0)
        N[0] = 1.0

        var left = List[FType]()
        var right = List[FType]()
        for _ in range(p + 1):
            left.append(0.0)
            right.append(0.0)

        for j in range(1, p + 1):
            left[j] = t - self.knots[span + 1 - j]
            right[j] = self.knots[span + j] - t
            var saved: FType = 0.0
            for r in range(j):
                var denom = right[r + 1] + left[j - r]
                if denom == 0.0:
                    N[r] = saved
                    saved = 0.0
                else:
                    var temp = N[r] / denom
                    N[r] = saved + right[r + 1] * temp
                    saved = left[j - r] * temp
            N[j] = saved

        return N.copy()

    def point_at(self, t: FType) -> Point:
        """Evaluate NURBS curve at parameter t using de Boor / rational B-spline."""
        var n = self.num_control_points()
        if n == 0:
            return Point(0.0, 0.0, 0.0)
        if n == 1:
            return self.control_points[0]

        var span = self._find_knot_span(t)
        var N = self._basis_functions(span, t)
        var p = self.degree

        var wx: FType = 0.0
        var wy: FType = 0.0
        var wz: FType = 0.0
        var w_sum: FType = 0.0

        for i in range(p + 1):
            var idx = span - p + i
            if idx < 0 or idx >= n:
                continue
            var w = self.weights[idx]
            var basis = N[i] * w
            wx += basis * self.control_points[idx].x
            wy += basis * self.control_points[idx].y
            wz += basis * self.control_points[idx].z
            w_sum += basis

        if w_sum == 0.0:
            return Point(0.0, 0.0, 0.0)

        return Point(wx / w_sum, wy / w_sum, wz / w_sum)

    def derivative_at(self, t: FType) -> Vector3:
        """Numerical first derivative via central differences."""
        var h: FType = 1e-6
        var t_min: FType = 0.0
        var t_max: FType = 1.0
        if len(self.knots) > 0:
            t_min = self.knots[self.degree]
            t_max = self.knots[self.num_control_points()]

        var t1 = t - h
        var t2 = t + h
        if t1 < t_min:
            t1 = t_min
        if t2 > t_max:
            t2 = t_max

        var p1 = self.point_at(t1)
        var p2 = self.point_at(t2)
        var dt = t2 - t1
        if dt == 0.0:
            return Vector3(0.0, 0.0, 0.0)
        return Vector3(
            (p2.x - p1.x) / dt,
            (p2.y - p1.y) / dt,
            (p2.z - p1.z) / dt,
        )

    def length(self) -> FType:
        """Approximate arc length via numerical integration with 100 segments."""
        var segments = 100
        var n = self.num_control_points()
        if n == 0:
            return 0.0

        var t_min: FType = 0.0
        var t_max: FType = 1.0
        if len(self.knots) > 0:
            t_min = self.knots[self.degree]
            t_max = self.knots[n]

        var total: FType = 0.0
        var prev = self.point_at(t_min)
        for i in range(1, segments + 1):
            var t = t_min + (t_max - t_min) * FType(i) / FType(segments)
            var curr = self.point_at(t)
            var dx = curr.x - prev.x
            var dy = curr.y - prev.y
            var dz = curr.z - prev.z
            total += sqrt(dx * dx + dy * dy + dz * dz)
            prev = curr

        return total

    def is_closed(self) -> Bool:
        """Check if start and end control points coincide."""
        var n = self.num_control_points()
        if n < 2:
            return False
        var p_start = self.control_points[0]
        var p_end = self.control_points[n - 1]
        var dx = p_end.x - p_start.x
        var dy = p_end.y - p_start.y
        var dz = p_end.z - p_start.z
        return sqrt(dx * dx + dy * dy + dz * dz) < 1e-10

    def project_point(self, p: Point) -> Point:
        """Find the closest point on the curve to p by sampling + refinement."""
        var n = self.num_control_points()
        if n == 0:
            return Point(0.0, 0.0, 0.0)
        var t_min: FType = 0.0
        var t_max: FType = 1.0
        if len(self.knots) > 0:
            t_min = self.knots[self.degree]
            t_max = self.knots[n]
        var samples = 64
        var best_t = t_min
        var best_dist_sq: FType = 1e38
        for i in range(samples + 1):
            var t = t_min + (t_max - t_min) * FType(i) / FType(samples)
            var q = self.point_at(t)
            var dx = q.x - p.x
            var dy = q.y - p.y
            var dz = q.z - p.z
            var d2 = dx * dx + dy * dy + dz * dz
            if d2 < best_dist_sq:
                best_dist_sq = d2
                best_t = t
        # Refine with golden-section-like bisection over a small interval
        var lo = best_t - (t_max - t_min) / FType(samples)
        var hi = best_t + (t_max - t_min) / FType(samples)
        if lo < t_min:
            lo = t_min
        if hi > t_max:
            hi = t_max
        for _ in range(32):
            var m1 = lo + (hi - lo) / 3.0
            var m2 = hi - (hi - lo) / 3.0
            var q1 = self.point_at(m1)
            var q2 = self.point_at(m2)
            var d1 = (q1.x - p.x) ** 2 + (q1.y - p.y) ** 2 + (q1.z - p.z) ** 2
            var d2 = (q2.x - p.x) ** 2 + (q2.y - p.y) ** 2 + (q2.z - p.z) ** 2
            if d1 < d2:
                hi = m2
            else:
                lo = m1
        return self.point_at((lo + hi) / 2.0)

    def distance_to_point(self, p: Point) -> FType:
        """Distance from p to the closest point on the curve."""
        var closest = self.project_point(p)
        var dx = closest.x - p.x
        var dy = closest.y - p.y
        var dz = closest.z - p.z
        return sqrt(dx * dx + dy * dy + dz * dz)

    def reverse(self) -> NurbsCurve:
        """Return a new curve with reversed parameterization."""
        var n = self.num_control_points()
        var rev_pts = List[Point]()
        var rev_weights = List[FType]()
        for i in range(n - 1, -1, -1):
            rev_pts.append(self.control_points[i])
            rev_weights.append(self.weights[i])
        # Reverse and remap knots: new_knot[i] = knot_max - knot[n_knots-1-i] + knot_min
        var nk = len(self.knots)
        var k_min = self.knots[0]
        var k_max = self.knots[nk - 1]
        var rev_knots = List[FType]()
        for i in range(nk - 1, -1, -1):
            rev_knots.append(k_max - self.knots[i] + k_min)
        return NurbsCurve(rev_pts, rev_knots, self.degree, rev_weights)

    def sample(self, num_points: Int = 50) -> List[Point]:
        """Sample the curve at uniform parameter intervals."""
        var result = List[Point]()
        var n = self.num_control_points()
        if n == 0:
            return result^
        var t_min = self.knots[self.degree]
        var t_max = self.knots[n]
        for i in range(num_points + 1):
            var t = t_min + (t_max - t_min) * FType(i) / FType(num_points)
            result.append(self.point_at(t))
        return result^

    def curvature_at(self, t: FType) -> FType:
        """Approximate curvature at parameter t via finite differences.
        Curvature = |T'| / |r'| where T is the unit tangent."""
        var h: FType = 1e-5
        var d1 = self.derivative_at(t)
        var d2_plus = self.derivative_at(t + h)
        var d2_minus = self.derivative_at(t - h)
        # Second derivative approximation
        var ddx = (d2_plus.x - d2_minus.x) / (2.0 * h)
        var ddy = (d2_plus.y - d2_minus.y) / (2.0 * h)
        var ddz = (d2_plus.z - d2_minus.z) / (2.0 * h)
        # Cross product of first and second derivatives
        var cx = d1.y * ddz - d1.z * ddy
        var cy = d1.z * ddx - d1.x * ddz
        var cz = d1.x * ddy - d1.y * ddx
        var cross_mag = sqrt(cx * cx + cy * cy + cz * cz)
        var d1_mag = d1.length()
        if d1_mag < 1e-15:
            return 0.0
        return cross_mag / (d1_mag * d1_mag * d1_mag)

    def __repr__(self) -> String:
        return (
            "NurbsCurve(degree="
            + String(self.degree)
            + ", num_control_points="
            + String(self.num_control_points())
            + ")"
        )
