from geokernel import FType, Point, Vector3
from geokernel.surface import Surface
import math


fn _find_span(n: Int, degree: Int, t: FType, knots: List[FType]) -> Int:
    """Find knot span index using binary search (Cox-de Boor)."""
    if t >= knots[n + 1]:
        return n
    if t <= knots[degree]:
        return degree
    var low = degree
    var high = n + 1
    var mid = (low + high) // 2
    while t < knots[mid] or t >= knots[mid + 1]:
        if t < knots[mid]:
            high = mid
        else:
            low = mid
        mid = (low + high) // 2
    return mid


fn _basis_funs(span: Int, t: FType, degree: Int, knots: List[FType]) -> List[FType]:
    """Compute non-zero B-spline basis functions."""
    var N = List[FType]()
    for _ in range(degree + 1):
        N.append(0.0)
    N[0] = 1.0
    var left = List[FType]()
    var right = List[FType]()
    for _ in range(degree + 1):
        left.append(0.0)
        right.append(0.0)
    for j in range(1, degree + 1):
        left[j] = t - knots[span + 1 - j]
        right[j] = knots[span + j] - t
        var saved: FType = 0.0
        for r in range(j):
            var temp = N[r] / (right[r + 1] + left[j - r])
            N[r] = saved + right[r + 1] * temp
            saved = left[j - r] * temp
        N[j] = saved
    return N.copy()


fn _basis_funs_deriv(span: Int, t: FType, degree: Int, knots: List[FType]) -> (List[FType], List[FType]):
    """Compute B-spline basis functions and their first derivatives."""
    var N = _basis_funs(span, t, degree, knots)
    var dN = List[FType]()
    for _ in range(degree + 1):
        dN.append(0.0)
    # First derivative using finite difference of basis functions
    if degree >= 1:
        var N_minus = List[FType]()
        for _ in range(degree + 1):
            N_minus.append(0.0)
        # Compute derivatives via recurrence
        # d/du N_{i,p}(u) = p/(u_{i+p} - u_i) * N_{i,p-1}(u) - p/(u_{i+p+1} - u_{i+1}) * N_{i+1,p-1}(u)
        var N_prev = _basis_funs(span, t, degree - 1, knots)
        for i in range(degree + 1):
            var left_val: FType = 0.0
            var right_val: FType = 0.0
            # N_{span-degree+i, degree-1}
            var idx_left = span - degree + i
            if i < degree:
                var denom_left = knots[idx_left + degree] - knots[idx_left]
                if denom_left > 1e-14:
                    left_val = FType(degree) * N_prev[i] / denom_left
            if i > 0:
                var idx_right = span - degree + i
                var denom_right = knots[idx_right + degree] - knots[idx_right]
                if denom_right > 1e-14:
                    right_val = FType(degree) * N_prev[i - 1] / denom_right
            dN[i] = left_val - right_val
    return (N, dN)


struct NurbsSurface(Copyable, Movable, Surface):
    var control_points: List[List[Point]]
    var knots_u: List[FType]
    var knots_v: List[FType]
    var _degree_u: Int
    var _degree_v: Int
    var weights: List[List[FType]]

    fn __init__(
        out self,
        control_points: List[List[Point]],
        knots_u: List[FType],
        knots_v: List[FType],
        degree_u: Int,
        degree_v: Int,
        weights: List[List[FType]],
    ):
        self.control_points = control_points.copy()
        self.knots_u = knots_u.copy()
        self.knots_v = knots_v.copy()
        self._degree_u = degree_u
        self._degree_v = degree_v
        self.weights = weights.copy()

    fn num_control_points_u(self) -> Int:
        return len(self.control_points)

    fn num_control_points_v(self) -> Int:
        if len(self.control_points) == 0:
            return 0
        return len(self.control_points[0])

    fn degree_u(self) -> Int:
        return self._degree_u

    fn degree_v(self) -> Int:
        return self._degree_v

    fn point_at(self, u: FType, v: FType) -> Point:
        """Evaluate NURBS surface at (u, v) using tensor product B-spline."""
        var n_u = self.num_control_points_u()
        var n_v = self.num_control_points_v()
        var p = self._degree_u
        var q = self._degree_v

        var span_u = _find_span(n_u - 1, p, u, self.knots_u)
        var span_v = _find_span(n_v - 1, q, v, self.knots_v)
        var Nu = _basis_funs(span_u, u, p, self.knots_u)
        var Nv = _basis_funs(span_v, v, q, self.knots_v)

        var wx: FType = 0.0
        var wy: FType = 0.0
        var wz: FType = 0.0
        var wsum: FType = 0.0

        for i in range(p + 1):
            var row_idx = span_u - p + i
            for j in range(q + 1):
                var col_idx = span_v - q + j
                var w = self.weights[row_idx][col_idx]
                var cp = self.control_points[row_idx][col_idx]
                var coeff = Nu[i] * Nv[j] * w
                wx += coeff * cp.x
                wy += coeff * cp.y
                wz += coeff * cp.z
                wsum += coeff

        if wsum == 0.0:
            return Point(0.0, 0.0, 0.0)
        return Point(wx / wsum, wy / wsum, wz / wsum)

    fn partial_u(self, u: FType, v: FType) -> Vector3:
        """Partial derivative in u direction via central finite differences."""
        var h: FType = 1e-6
        var u0 = u - h if u - h >= self.knots_u[0] else u
        var u1 = u + h if u + h <= self.knots_u[len(self.knots_u) - 1] else u
        var step = u1 - u0
        if step < 1e-15:
            return Vector3(0.0, 0.0, 0.0)
        var p0 = self.point_at(u0, v)
        var p1 = self.point_at(u1, v)
        return Vector3((p1.x - p0.x) / step, (p1.y - p0.y) / step, (p1.z - p0.z) / step)

    fn partial_v(self, u: FType, v: FType) -> Vector3:
        """Partial derivative in v direction via central finite differences."""
        var h: FType = 1e-6
        var v0 = v - h if v - h >= self.knots_v[0] else v
        var v1 = v + h if v + h <= self.knots_v[len(self.knots_v) - 1] else v
        var step = v1 - v0
        if step < 1e-15:
            return Vector3(0.0, 0.0, 0.0)
        var p0 = self.point_at(u, v0)
        var p1 = self.point_at(u, v1)
        return Vector3((p1.x - p0.x) / step, (p1.y - p0.y) / step, (p1.z - p0.z) / step)

    fn normal_at(self, u: FType, v: FType) -> Vector3:
        """Surface normal = cross product of partial derivatives."""
        var du = self.partial_u(u, v)
        var dv = self.partial_v(u, v)
        var n = du.cross(dv)
        var length = n.length()
        if length < 1e-15:
            return Vector3(0.0, 0.0, 1.0)
        return n / length

    fn area(self) -> FType:
        """Numerical area via 10x10 sampling (midpoint rule)."""
        var n_u_knots = len(self.knots_u)
        var n_v_knots = len(self.knots_v)
        var u_min = self.knots_u[0]
        var u_max = self.knots_u[n_u_knots - 1]
        var v_min = self.knots_v[0]
        var v_max = self.knots_v[n_v_knots - 1]

        var N = 10
        var du = (u_max - u_min) / FType(N)
        var dv = (v_max - v_min) / FType(N)
        var total: FType = 0.0

        for i in range(N):
            for j in range(N):
                var u = u_min + (FType(i) + 0.5) * du
                var v = v_min + (FType(j) + 0.5) * dv
                var pu = self.partial_u(u, v)
                var pv = self.partial_v(u, v)
                var cross = pu.cross(pv)
                total += cross.length() * du * dv

        return total

    fn is_planar(self) -> Bool:
        """Check if all control points are coplanar."""
        var n_u = self.num_control_points_u()
        var n_v = self.num_control_points_v()
        if n_u * n_v < 4:
            return True

        # Build reference plane from first 3 non-collinear points
        var p0 = self.control_points[0][0]
        var p1 = self.control_points[0][1] if n_v > 1 else self.control_points[1][0]
        var p2 = self.control_points[1][0] if n_u > 1 else self.control_points[0][2]

        var v1 = Vector3.from_points(p0, p1)
        var v2 = Vector3.from_points(p0, p2)
        var normal = v1.cross(v2)
        if normal.length() < 1e-14:
            # Try another combination
            return True

        normal = normal.normalize()
        var atol: FType = 1e-10

        for i in range(n_u):
            for j in range(n_v):
                var cp = self.control_points[i][j]
                var diff = Vector3.from_points(p0, cp)
                var dist = math.abs(diff.dot(normal))
                if dist > atol:
                    return False
        return True

    fn __repr__(self) -> String:
        return (
            "NurbsSurface(nu="
            + String(self.num_control_points_u())
            + ", nv="
            + String(self.num_control_points_v())
            + ", degree_u="
            + String(self._degree_u)
            + ", degree_v="
            + String(self._degree_v)
            + ")"
        )
