from geokernel import FType, Point, Vector3, Plane, Face

comptime SLICE_ATOL: FType = 1e-10


struct FacePair(Movable):
    """Holds two lists of faces: above-plane and below-plane results."""
    var above: List[Face]
    var below: List[Face]

    def __init__(out self):
        self.above = List[Face]()
        self.below = List[Face]()



def classify_point(p: Point, plane: Plane) -> Int:
    """Returns 1 if above plane, -1 if below, 0 if on plane (within SLICE_ATOL).

    Algorithm:
        signed_dist = dot(plane.vector, p - plane.point)
        > atol  → +1 (above)
        < -atol → -1 (below)
        else    →  0 (on plane)
    """
    var diff = Vector3(
        p.x - plane.point.x,
        p.y - plane.point.y,
        p.z - plane.point.z,
    )
    var d = plane.vector.dot(diff)
    if d > SLICE_ATOL:
        return 1
    elif d < -SLICE_ATOL:
        return -1
    else:
        return 0


def _intersect_segment_plane(a: Point, b: Point, plane: Plane) -> Point:
    """Compute the intersection of segment [a,b] with the plane.

    Algorithm (parametric line):
        diff_a = a - plane.point
        dir    = b - a
        t = -dot(n, diff_a) / dot(n, dir)
        hit = a + t * dir
    Clamps t to [0,1] to stay on the segment.
    """
    var da_x = a.x - plane.point.x
    var da_y = a.y - plane.point.y
    var da_z = a.z - plane.point.z
    var db_x = b.x - a.x
    var db_y = b.y - a.y
    var db_z = b.z - a.z
    var denom = plane.vector.x * db_x + plane.vector.y * db_y + plane.vector.z * db_z
    var t: FType = 0.5
    if abs(denom) > 1e-15:
        var numer = -(plane.vector.x * da_x + plane.vector.y * da_y + plane.vector.z * da_z)
        t = numer / denom
        if t < 0.0:
            t = 0.0
        elif t > 1.0:
            t = 1.0
    return Point(a.x + t * db_x, a.y + t * db_y, a.z + t * db_z)


def slice_face_by_plane(face: Face, plane: Plane) -> FacePair:
    """Split a face by a plane. Returns FacePair(above_faces, below_faces).

    Uses Sutherland-Hodgman-style vertex classification:
      1. Classify each vertex as above(+1) / below(-1) / on(0).
      2. All above or on  → face → above.
      3. All below or on  → face → below.
      4. Mixed → walk edges, collecting above and below polygons.

    Edge transition rules:
      above→above: add b to above
      below→below: add b to below
      above→below: compute intersection, close above, open below
      below→above: compute intersection, close below, open above
      any→on     : add b to both sides
      on→above   : add b to above
      on→below   : add b to below
      on→on      : add b to both
    """
    var n = face.num_vertices()
    var classes = List[Int]()
    for i in range(n):
        classes.append(classify_point(face.get_vertex(i), plane))

    var has_above = False
    var has_below = False
    for i in range(n):
        if classes[i] > 0:
            has_above = True
        elif classes[i] < 0:
            has_below = True

    var pair = FacePair()

    if not has_below:
        pair.above.append(face)
        return pair^

    if not has_above:
        pair.below.append(face)
        return pair^

    # Mixed — walk edges
    var above_pts = List[Point]()
    var below_pts = List[Point]()

    # Seed with first vertex
    var c0 = classes[0]
    var p0 = face.get_vertex(0)
    if c0 >= 0:
        above_pts.append(p0)
    if c0 <= 0:
        below_pts.append(p0)

    for i in range(n):
        var a = face.get_vertex(i)
        var b = face.get_vertex((i + 1) % n)
        var ca = classes[i]
        var cb = classes[(i + 1) % n]

        if ca > 0 and cb > 0:
            above_pts.append(b)
        elif ca < 0 and cb < 0:
            below_pts.append(b)
        elif ca > 0 and cb < 0:
            var ix = _intersect_segment_plane(a, b, plane)
            above_pts.append(ix)
            below_pts.append(ix)
            below_pts.append(b)
        elif ca < 0 and cb > 0:
            var ix = _intersect_segment_plane(a, b, plane)
            below_pts.append(ix)
            above_pts.append(ix)
            above_pts.append(b)
        elif ca > 0 and cb == 0:
            above_pts.append(b)
            below_pts.append(b)
        elif ca < 0 and cb == 0:
            above_pts.append(b)
            below_pts.append(b)
        elif ca == 0 and cb > 0:
            above_pts.append(b)
        elif ca == 0 and cb < 0:
            below_pts.append(b)
        elif ca == 0 and cb == 0:
            above_pts.append(b)
            below_pts.append(b)

    if len(above_pts) >= 3:
        pair.above.append(Face(above_pts))
    if len(below_pts) >= 3:
        pair.below.append(Face(below_pts))

    return pair^


def slice_faces_by_plane(faces: List[Face], plane: Plane) -> FacePair:
    """Slice a collection of faces (e.g. a cell's faces) by a plane.
    Returns FacePair(above_faces, below_faces).

    Each face is independently sliced; resulting half-faces are collected.
    """
    var result = FacePair()

    for i in range(len(faces)):
        var part = slice_face_by_plane(faces[i], plane)
        for j in range(len(part.above)):
            result.above.append(part.above[j])
        for j in range(len(part.below)):
            result.below.append(part.below[j])

    return result^
