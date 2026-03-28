from geokernel import FType, Point, Vector3, Face, Cell, Plane


# ---------------------------------------------------------------------------
# Sutherland-Hodgman polygon clipping (convex clip polygon)
# ---------------------------------------------------------------------------

def _intersect_edge_plane(
    a: Point, b: Point, c: Point, d: Point
) -> Point:
    """Compute intersection of segment ab with the infinite line cd (2D via xy)."""
    var a1 = d.y - c.y
    var b1 = c.x - d.x
    var c1 = a1 * c.x + b1 * c.y

    var a2 = b.y - a.y
    var b2 = a.x - b.x
    var c2 = a2 * a.x + b2 * a.y

    var det = a1 * b2 - a2 * b1
    var ix = (b2 * c1 - b1 * c2) / det
    var iy = (a1 * c2 - a2 * c1) / det

    # Interpolate z linearly along ab
    var dx = b.x - a.x
    var dy = b.y - a.y
    var t = ((ix - a.x) / dx if abs(dx) > 1e-15 else 0.0) if abs(dx) > abs(dy)
        else ((iy - a.y) / dy if abs(dy) > 1e-15 else 0.0)
    var iz = a.z + t * (b.z - a.z)
    return Point(ix, iy, iz)


def _inside_half_plane(p: Point, a: Point, b: Point) -> Bool:
    """Return True if p is on the left side (or on) the directed edge a->b (2D test)."""
    return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x) >= -1e-15


def clip_polygon(subject: List[Point], clip: List[Point]) -> List[Point]:
    """Sutherland-Hodgman polygon clipping.
    Both polygons must be convex and lie in the same plane (Z ignored for clipping edge).
    Returns clipped polygon vertices (open list, last != first)."""
    if len(subject) == 0 or len(clip) == 0:
        return List[Point]()

    var output = subject.copy()

    var n = len(clip)
    for i in range(n):
        if len(output) == 0:
            break
        var input_list = output.copy()
        output = List[Point]()
        var a = clip[i]
        var b = clip[(i + 1) % n]

        var count = len(input_list)
        for j in range(count):
            var current = input_list[j]
            var prev = input_list[(j + count - 1) % count]

            if _inside_half_plane(current, a, b):
                if not _inside_half_plane(prev, a, b):
                    output.append(_intersect_edge_plane(prev, current, a, b))
                output.append(current)
            elif _inside_half_plane(prev, a, b):
                output.append(_intersect_edge_plane(prev, current, a, b))

    return output^


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _face_to_open_points(f: Face) -> List[Point]:
    """Return vertices of a Face as an open list (last != first)."""
    var pts = List[Point]()
    var n = f.num_vertices()
    for i in range(n):
        pts.append(f.get_vertex(i))
    return pts^


def _normals_parallel(a: Face, b: Face, atol: FType = 1e-10) -> Bool:
    """Return True if the two face normals are parallel (same or opposite)."""
    var na = a.normal().normalize()
    var nb = b.normal().normalize()
    var cross = na.cross(nb)
    return cross.length() < atol


def _coplanar_check(a: Face, b: Face, atol: FType = 1e-10) -> Bool:
    """Return True if a and b lie on the same plane."""
    if not _normals_parallel(a, b, atol):
        return False
    var na = a.normal().normalize()
    var d = Vector3.from_points(a.get_vertex(0), b.get_vertex(0))
    return abs(na.dot(d)) < atol


# ---------------------------------------------------------------------------
# 2D Face boolean operations (coplanar convex faces)
# ---------------------------------------------------------------------------

def intersect_faces(a: Face, b: Face) -> Face:
    """Return the intersection of two coplanar convex faces.
    Returns an empty Face (0 vertices) if disjoint or not coplanar."""
    if not _coplanar_check(a, b):
        # Guard: not coplanar — return empty face
        return Face(List[Point]())

    var pts_a = _face_to_open_points(a)
    var pts_b = _face_to_open_points(b)
    var result = clip_polygon(pts_a, pts_b)

    if len(result) < 3:
        return Face(List[Point]())
    return Face(result)


def union_faces(a: Face, b: Face) -> List[Face]:
    """Return the union of two coplanar convex faces.
    If they overlap returns one merged face; if disjoint returns both originals."""
    if not _coplanar_check(a, b):
        # Guard: not coplanar — return both unchanged
        var result = List[Face]()
        result.append(a)
        result.append(b)
        return result^

    var inter = intersect_faces(a, b)
    if inter.num_vertices() <= 0:
        # Disjoint — return both
        var result = List[Face]()
        result.append(a)
        result.append(b)
        return result^

    # Overlap: union is the convex hull of both vertex sets (approximate for convex inputs)
    var all_pts = _face_to_open_points(a)
    var pts_b = _face_to_open_points(b)
    for i in range(len(pts_b)):
        all_pts.append(pts_b[i])

    var hull = _convex_hull_2d(all_pts, a.normal())
    var result = List[Face]()
    result.append(Face(hull))
    return result^


def difference_faces(a: Face, b: Face) -> List[Face]:
    """Return a minus b for two coplanar convex faces.
    Returns at most one face (the clipped remainder).
    For concave differences a proper decomposition would be needed; this returns the
    Sutherland-Hodgman clip of a against the complement of b via reversed winding."""
    if not _coplanar_check(a, b):
        # Guard: not coplanar — return a unchanged
        var result = List[Face]()
        result.append(a)
        return result^

    var inter = intersect_faces(a, b)
    if inter.num_vertices() <= 0:
        # No overlap — a minus b == a
        var result = List[Face]()
        result.append(a)
        return result^

    # Clip a against each reversed edge of b (complement half-planes of b)
    var pts_a = _face_to_open_points(a)
    var pts_b = _face_to_open_points(b)

    # Reverse b's clip edges to get the exterior half-planes
    var pts_b_rev = List[Point]()
    var nb = len(pts_b)
    for i in range(nb):
        pts_b_rev.append(pts_b[nb - 1 - i])

    var clipped = clip_polygon(pts_a, pts_b_rev)

    var result = List[Face]()
    if len(clipped) >= 3:
        result.append(Face(clipped))
    return result^


# ---------------------------------------------------------------------------
# Convex hull helper (2D, projected onto face plane)
# ---------------------------------------------------------------------------

def _convex_hull_2d(pts: List[Point], normal: Vector3) -> List[Point]:
    """Compute convex hull of pts projected onto the plane with the given normal.
    Returns hull vertices in CCW order (3D points on the original plane)."""
    if len(pts) == 0:
        return List[Point]()

    # Build local 2D basis
    var n = normal.normalize()
    var ref_v = Vector3(0.0, 0.0, 1.0)
    if abs(n.dot(ref_v)) > 0.9:
        ref_v = Vector3(1.0, 0.0, 0.0)
    var u = n.cross(ref_v).normalize()
    var v = n.cross(u).normalize()
    var origin = pts[0]

    # Project to 2D
    var xs = List[FType]()
    var ys = List[FType]()
    var mp = pts.copy()
    for i in range(len(pts)):
        var d = Vector3.from_points(origin, pts[i])
        xs.append(d.dot(u))
        ys.append(d.dot(v))

    var num = len(xs)

    # Find pivot (lowest y, then leftmost)
    var pivot = 0
    for i in range(1, num):
        if ys[i] < ys[pivot] or (ys[i] == ys[pivot] and xs[i] < xs[pivot]):
            pivot = i

    # Swap pivot to index 0
    var tmp_x = xs[0]; xs[0] = xs[pivot]; xs[pivot] = tmp_x
    var tmp_y = ys[0]; ys[0] = ys[pivot]; ys[pivot] = tmp_y
    var tmp_p = mp[0]; mp[0] = mp[pivot]; mp[pivot] = tmp_p

    var px = xs[0]
    var py = ys[0]

    # Sort by polar angle (CCW, ascending from smallest angle) — selection sort
    # cross(a,b) = ax*by - ay*bx > 0 means a is CW from b (a has smaller polar angle)
    # We want the point with the smallest polar angle first → find min → swap when j < min
    for i in range(1, num - 1):
        var min_idx = i
        for j in range(i + 1, num):
            var ax = xs[j] - px; var ay = ys[j] - py
            var bx = xs[min_idx] - px; var by = ys[min_idx] - py
            var cross = ax * by - ay * bx
            if cross > 0:
                # j is more CW than min_idx → j has smaller polar angle → j comes first
                min_idx = j
            elif cross == 0:
                if ax * ax + ay * ay < bx * bx + by * by:
                    min_idx = j
        if min_idx != i:
            var tx = xs[i]; xs[i] = xs[min_idx]; xs[min_idx] = tx
            var ty = ys[i]; ys[i] = ys[min_idx]; ys[min_idx] = ty
            var tp2 = mp[i]; mp[i] = mp[min_idx]; mp[min_idx] = tp2

    # Graham scan stack
    var stack = List[Int]()
    stack.append(0)
    stack.append(1)
    for i in range(2, num):
        while len(stack) > 1:
            var b_idx = stack[len(stack) - 1]
            var a_idx = stack[len(stack) - 2]
            var ax2 = xs[b_idx] - xs[a_idx]; var ay2 = ys[b_idx] - ys[a_idx]
            var bx2 = xs[i] - xs[a_idx];    var by2 = ys[i] - ys[a_idx]
            if ax2 * by2 - ay2 * bx2 <= 0:
                _ = stack.pop()
            else:
                break
        stack.append(i)

    var hull = List[Point]()
    for i in range(len(stack)):
        hull.append(mp[stack[i]])
    return hull^


# ---------------------------------------------------------------------------
# 3D solid boolean stubs
# ---------------------------------------------------------------------------

def _face_centroid_inside_cell(face: Face, cell_faces: List[Face]) -> Bool:
    """Test if a face's centroid is inside a solid defined by cell_faces.
    Uses +X ray casting (odd crossing count = inside)."""
    var p = face.centroid()
    var ray_dir = Vector3(1.0, 0.0, 0.0)
    var count = 0
    for i in range(len(cell_faces)):
        var cf = cell_faces[i]
        var n = cf.normal()
        var denom = n.dot(ray_dir)
        if abs(denom) < 1e-10:
            continue
        var d = Vector3.from_points(p, cf.points[0])
        var t = n.dot(d) / denom
        if t <= 1e-10:
            continue
        var hit = Point(p.x + ray_dir.x * t, p.y + ray_dir.y * t, p.z + ray_dir.z * t)
        if cf.contains_point_2d(hit):
            count += 1
    return count % 2 == 1


def union_cells(a: Cell, b: Cell) -> Cell:
    """3D union: faces of A outside B + faces of B outside A.
    Uses face centroid classification via ray casting."""
    var a_faces = a.faces
    var b_faces = b.faces
    var result_faces = List[Face]()

    # Faces of A not inside B
    for i in range(len(a_faces)):
        if not _face_centroid_inside_cell(a_faces[i], b_faces):
            result_faces.append(a_faces[i])

    # Faces of B not inside A
    for i in range(len(b_faces)):
        if not _face_centroid_inside_cell(b_faces[i], a_faces):
            result_faces.append(b_faces[i])

    if len(result_faces) == 0:
        return a  # fallback: no faces classified → return a
    return Cell(result_faces)


def intersect_cells(a: Cell, b: Cell) -> Cell:
    """3D intersection: faces of A inside B + faces of B inside A (reversed normals)."""
    var a_faces = a.faces
    var b_faces = b.faces
    var result_faces = List[Face]()

    # Faces of A inside B
    for i in range(len(a_faces)):
        if _face_centroid_inside_cell(a_faces[i], b_faces):
            result_faces.append(a_faces[i])

    # Faces of B inside A (reversed to point outward from intersection)
    for i in range(len(b_faces)):
        if _face_centroid_inside_cell(b_faces[i], a_faces):
            result_faces.append(b_faces[i].reverse())

    if len(result_faces) == 0:
        return Cell(List[Face]())  # empty intersection
    return Cell(result_faces)


def difference_cells(a: Cell, b: Cell) -> Cell:
    """3D difference (A - B): faces of A outside B + faces of B inside A (reversed)."""
    var a_faces = a.faces
    var b_faces = b.faces
    var result_faces = List[Face]()

    # Faces of A not inside B
    for i in range(len(a_faces)):
        if not _face_centroid_inside_cell(a_faces[i], b_faces):
            result_faces.append(a_faces[i])

    # Faces of B inside A (reversed to carve out the volume)
    for i in range(len(b_faces)):
        if _face_centroid_inside_cell(b_faces[i], a_faces):
            result_faces.append(b_faces[i].reverse())

    if len(result_faces) == 0:
        return a  # fallback
    return Cell(result_faces)


def slice_cell(c: Cell, p: Plane) -> Tuple[Cell, Cell]:
    """Slice a cell by a plane. Faces with centroids on positive side go to
    first cell, negative to second. Faces straddling the plane are split
    using polygon clipping."""
    var above = List[Face]()
    var below = List[Face]()

    for i in range(len(c.faces)):
        var face = c.faces[i]
        var centroid = face.centroid()
        var dist = p.distance_to_point(centroid)

        if dist > 1e-10:
            above.append(face)
        elif dist < -1e-10:
            below.append(face)
        else:
            # On the plane — add to both
            above.append(face)
            below.append(face)

    # Create capping faces from the cross-section
    # Collect vertices near the plane from both halves
    var cap_pts = List[Point]()
    for i in range(len(c.faces)):
        var face = c.faces[i]
        for j in range(face.num_vertices()):
            var v = face.get_vertex(j)
            if abs(p.distance_to_point(v)) < 1e-6:
                # Check if already collected
                var found = False
                for k in range(len(cap_pts)):
                    var dx = cap_pts[k].x - v.x
                    var dy = cap_pts[k].y - v.y
                    var dz = cap_pts[k].z - v.z
                    if dx * dx + dy * dy + dz * dz < 1e-12:
                        found = True
                        break
                if not found:
                    cap_pts.append(v)

    if len(cap_pts) >= 3:
        # Build cap face from convex hull of intersection points
        var hull = _convex_hull_2d(cap_pts, p.vector)
        if len(hull) >= 3:
            var cap = Face(hull)
            above.append(cap)
            below.append(cap.reverse())

    return (Cell(above), Cell(below))
