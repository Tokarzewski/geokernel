from geokernel import FType, Point, Vector3, Line, Face, PointInPolygon


fn line_face_intersection(line: Line, face: Face) -> Tuple[Bool, Point]:
    """Ray-plane intersection, then point-in-polygon test.

    Algorithm:
      1. Compute face normal and a point on the plane (first vertex).
      2. t = dot(normal, plane_pt - line.p1) / dot(normal, direction)
      3. If t < 0 or t > 1 → no intersection (outside segment range).
      4. Intersection point: p = line.p1 + t * direction
      5. PointInPolygon.classify() to check if point is inside face.

    Returns (intersects, point). Point is (0,0,0) if no intersection.
    """
    var n = face.normal()
    var direction = line.direction()  # unnormalized p2 - p1; matches parametric t in [0,1]
    var denom = n.dot(direction)

    if abs(denom) < 1e-12:
        return (False, Point(0, 0, 0))  # line parallel to face plane

    # diff = plane_pt - line.p1
    var diff = Vector3.from_points(line.p1, face.points[0])
    var t = n.dot(diff) / denom

    if t < 0.0 or t > 1.0:
        return (False, Point(0, 0, 0))  # intersection outside segment

    var hit = line.point_at(t)

    # Check if hit point lies inside the face polygon
    if PointInPolygon.classify(hit, face.points, n):
        return (True, hit)

    return (False, Point(0, 0, 0))


fn point_in_solid_ray_cast(p: Point, faces: List[Face]) -> Bool:
    """Cast ray in +Z direction from p, count face crossings.
    Odd count = inside, even = outside.

    Algorithm (Jordan curve theorem in 3D):
      For each face, test whether the +Z semi-infinite ray from p intersects it.
      t = dot(normal, face_pt - p) / dot(normal, (0,0,1))
      t must be > 0 (strictly above p) for a valid crossing.
    """
    var count = 0
    var ray_dir = Vector3(0.0, 0.0, 1.0)  # +Z ray

    for i in range(len(faces)):
        var face = faces[i]
        var n = face.normal()
        var denom = n.dot(ray_dir)

        if abs(denom) < 1e-12:
            continue  # face is horizontal — ray grazes it, skip

        # d = face_origin - p
        var d = Vector3.from_points(p, face.points[0])
        var t = n.dot(d) / denom

        if t <= 1e-12:
            continue  # intersection behind or exactly at p

        # Intersection point on face plane
        var hit = Point(p.x, p.y, p.z + t)  # ray_dir = (0,0,1) so only z changes

        if face.contains_point_2d(hit):
            count += 1

    return count % 2 == 1
