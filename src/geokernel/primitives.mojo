from geokernel import FType, Point, Face
from math import cos, sin, pi


fn box_faces(p_min: Point, p_max: Point) -> List[Face]:
    """Six faces of an axis-aligned box."""
    var x0 = p_min.x; var y0 = p_min.y; var z0 = p_min.z
    var x1 = p_max.x; var y1 = p_max.y; var z1 = p_max.z

    var faces = List[Face]()

    # Bottom (-Z)
    var b = List[Point]()
    b.append(Point(x0, y0, z0)); b.append(Point(x1, y0, z0))
    b.append(Point(x1, y1, z0)); b.append(Point(x0, y1, z0))
    faces.append(Face(b))

    # Top (+Z)
    var t = List[Point]()
    t.append(Point(x0, y0, z1)); t.append(Point(x0, y1, z1))
    t.append(Point(x1, y1, z1)); t.append(Point(x1, y0, z1))
    faces.append(Face(t))

    # Front (-Y)
    var fr = List[Point]()
    fr.append(Point(x0, y0, z0)); fr.append(Point(x0, y0, z1))
    fr.append(Point(x1, y0, z1)); fr.append(Point(x1, y0, z0))
    faces.append(Face(fr))

    # Back (+Y)
    var bk = List[Point]()
    bk.append(Point(x0, y1, z0)); bk.append(Point(x1, y1, z0))
    bk.append(Point(x1, y1, z1)); bk.append(Point(x0, y1, z1))
    faces.append(Face(bk))

    # Left (-X)
    var l = List[Point]()
    l.append(Point(x0, y0, z0)); l.append(Point(x0, y1, z0))
    l.append(Point(x0, y1, z1)); l.append(Point(x0, y0, z1))
    faces.append(Face(l))

    # Right (+X)
    var r = List[Point]()
    r.append(Point(x1, y0, z0)); r.append(Point(x1, y0, z1))
    r.append(Point(x1, y1, z1)); r.append(Point(x1, y1, z0))
    faces.append(Face(r))

    return faces^


fn sphere_faces(center: Point, radius: FType, u_segments: Int = 16, v_segments: Int = 8) -> List[Face]:
    """Quad/triangle mesh faces approximating a sphere."""
    var faces = List[Face]()

    for v in range(v_segments):
        var phi0 = pi * FType(v) / FType(v_segments)
        var phi1 = pi * FType(v + 1) / FType(v_segments)

        for u in range(u_segments):
            var theta0 = 2.0 * pi * FType(u) / FType(u_segments)
            var theta1 = 2.0 * pi * FType(u + 1) / FType(u_segments)

            var p00 = Point(
                center.x + radius * sin(phi0) * cos(theta0),
                center.y + radius * sin(phi0) * sin(theta0),
                center.z + radius * cos(phi0),
            )
            var p10 = Point(
                center.x + radius * sin(phi0) * cos(theta1),
                center.y + radius * sin(phi0) * sin(theta1),
                center.z + radius * cos(phi0),
            )
            var p01 = Point(
                center.x + radius * sin(phi1) * cos(theta0),
                center.y + radius * sin(phi1) * sin(theta0),
                center.z + radius * cos(phi1),
            )
            var p11 = Point(
                center.x + radius * sin(phi1) * cos(theta1),
                center.y + radius * sin(phi1) * sin(theta1),
                center.z + radius * cos(phi1),
            )

            if v == 0:
                # Top cap triangle
                var tri = List[Point]()
                tri.append(p00); tri.append(p11); tri.append(p01)
                faces.append(Face(tri))
            elif v == v_segments - 1:
                # Bottom cap triangle
                var tri = List[Point]()
                tri.append(p00); tri.append(p10); tri.append(p11)
                faces.append(Face(tri))
            else:
                var quad = List[Point]()
                quad.append(p00); quad.append(p10)
                quad.append(p11); quad.append(p01)
                faces.append(Face(quad))

    return faces^


fn cylinder_faces(center: Point, radius: FType, height: FType, segments: Int = 16) -> List[Face]:
    """Faces of a cylinder (side quads + top/bottom discs as fans)."""
    var faces = List[Face]()
    var bot_center = center
    var top_center = Point(center.x, center.y, center.z + height)

    # Precompute ring points
    var bot_ring = List[Point]()
    var top_ring = List[Point]()
    for i in range(segments):
        var theta = 2.0 * pi * FType(i) / FType(segments)
        bot_ring.append(Point(center.x + radius * cos(theta), center.y + radius * sin(theta), center.z))
        top_ring.append(Point(center.x + radius * cos(theta), center.y + radius * sin(theta), center.z + height))

    for i in range(segments):
        var j = (i + 1) % segments

        # Side quad
        var side = List[Point]()
        side.append(bot_ring[i]); side.append(bot_ring[j])
        side.append(top_ring[j]); side.append(top_ring[i])
        faces.append(Face(side))

        # Bottom cap triangle
        var btri = List[Point]()
        btri.append(bot_center); btri.append(bot_ring[j]); btri.append(bot_ring[i])
        faces.append(Face(btri))

        # Top cap triangle
        var ttri = List[Point]()
        ttri.append(top_center); ttri.append(top_ring[i]); ttri.append(top_ring[j])
        faces.append(Face(ttri))

    return faces^


fn cone_faces(center: Point, radius: FType, height: FType, segments: Int = 16) -> List[Face]:
    """Faces of a cone (side triangles + bottom disc as fan)."""
    var faces = List[Face]()
    var bot_center = center
    var apex = Point(center.x, center.y, center.z + height)

    var ring = List[Point]()
    for i in range(segments):
        var theta = 2.0 * pi * FType(i) / FType(segments)
        ring.append(Point(center.x + radius * cos(theta), center.y + radius * sin(theta), center.z))

    for i in range(segments):
        var j = (i + 1) % segments

        # Side triangle
        var side = List[Point]()
        side.append(ring[i]); side.append(ring[j]); side.append(apex)
        faces.append(Face(side))

        # Bottom cap triangle
        var btri = List[Point]()
        btri.append(bot_center); btri.append(ring[j]); btri.append(ring[i])
        faces.append(Face(btri))

    return faces^
