from geokernel import FType, Point, Vector3
from math import sqrt


struct NurbsCurve(Copyable, Movable, ImplicitlyCopyable):
    var control_points: List[Point]
    var knots: List[FType]
    var degree: Int
    var weights: List[FType]

    fn __init__(out self, control_points: List[Point], knots: List[FType], degree: Int, weights: List[FType]):
        self.control_points = control_points.copy()
        self.knots = knots.copy()
        self.degree = degree
        self.weights = weights.copy()

    fn __copyinit__(out self, copy: Self):
        self.control_points = copy.control_points.copy()
        self.knots = copy.knots.copy()
        self.degree = copy.degree
        self.weights = copy.weights.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.control_points = take.control_points^
        self.knots = take.knots^
        self.degree = take.degree
        self.weights = take.weights^

    fn num_control_points(self) -> Int:
        return len(self.control_points)

    fn _find_knot_span(self, t: FType) -> Int:
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

    fn _basis_functions(self, span: Int, t: FType) -> List[FType]:
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

    fn point_at(self, t: FType) -> Point:
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

    fn derivative_at(self, t: FType) -> Vector3:
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

    fn length(self) -> FType:
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

    fn is_closed(self) -> Bool:
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

    fn __repr__(self) -> String:
        return (
            "NurbsCurve(degree="
            + String(self.degree)
            + ", num_control_points="
            + String(self.num_control_points())
            + ")"
        )
