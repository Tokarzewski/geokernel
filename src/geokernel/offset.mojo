"""Offset, fillet, and chamfer operations for faces and shells."""

from geokernel import FType, Point, Vector3, Face, Shell
from std.math import sqrt, cos, sin, pi


def offset_face(face: Face, distance: FType) -> Face:
    """Offset a face along its normal by a distance.

    Positive distance moves outward (along normal), negative moves inward.
    Each vertex is translated along the face normal.
    """
    var n = face.normal()
    var offset = Vector3(n.x * distance, n.y * distance, n.z * distance)
    var new_pts = List[Point]()
    for i in range(face.num_vertices()):
        var p = face.get_vertex(i)
        new_pts.append(Point(p.x + offset.x, p.y + offset.y, p.z + offset.z))
    return Face(new_pts)


def offset_shell(shell: Shell, distance: FType) -> Shell:
    """Offset all faces of a shell along their individual normals.

    Creates a thickened or shrunken version of the shell.
    Does NOT re-intersect adjacent faces — for simple offset only.
    """
    var new_faces = List[Face]()
    for i in range(len(shell.faces)):
        new_faces.append(offset_face(shell.faces[i], distance))
    return Shell(new_faces)


def thicken_shell(shell: Shell, thickness: FType) -> Shell:
    """Create a thick solid from a surface shell.

    Returns a shell with:
    - Original faces (outer surface)
    - Offset faces reversed (inner surface)
    - Side faces connecting the two surfaces at boundaries
    """
    var outer = shell
    var inner = offset_shell(shell, -thickness)

    var result_faces = List[Face]()

    # Add outer faces
    for i in range(len(outer.faces)):
        result_faces.append(outer.faces[i])

    # Add inner faces (reversed normals to point inward)
    for i in range(len(inner.faces)):
        result_faces.append(inner.faces[i].reverse())

    # Add side faces at boundaries (connecting outer to inner edges)
    # For each boundary edge of the original shell, create a quad face
    var open_edges = outer.open_edges()
    for i in range(len(open_edges)):
        var p1 = open_edges[i][0]
        var p2 = open_edges[i][1]
        # Find corresponding inner points
        # Approximate: find the face containing this edge, use its normal
        var found_face_idx = -1
        for fi in range(len(shell.faces)):
            var face = shell.faces[fi]
            for ei in range(face.num_edges()):
                var edge = face.get_edge(ei)
                if edge.p1 == p1 and edge.p2 == p2:
                    found_face_idx = fi
                    break
                if edge.p1 == p2 and edge.p2 == p1:
                    found_face_idx = fi
                    break
            if found_face_idx >= 0:
                break

        if found_face_idx >= 0:
            var n = shell.faces[found_face_idx].normal()
            var off = Vector3(n.x * (-thickness), n.y * (-thickness), n.z * (-thickness))
            var p3 = Point(p2.x + off.x, p2.y + off.y, p2.z + off.z)
            var p4 = Point(p1.x + off.x, p1.y + off.y, p1.z + off.z)
            var side = List[Point]()
            side.append(p1); side.append(p2); side.append(p3); side.append(p4)
            result_faces.append(Face(side))

    return Shell(result_faces)


def chamfer_edge(face1: Face, face2: Face, distance: FType) -> Face:
    """Create a chamfer (flat cut) face between two adjacent faces.

    The chamfer face connects points at `distance` from the shared edge
    on each face. Returns the chamfer face.
    """
    # Find shared edge vertices
    var shared = List[Point]()
    for i in range(face1.num_vertices()):
        var p1 = face1.get_vertex(i)
        for j in range(face2.num_vertices()):
            if p1 == face2.get_vertex(j):
                shared.append(p1)
                break

    if len(shared) < 2:
        return Face(List[Point]())  # No shared edge

    var e1 = shared[0]
    var e2 = shared[1]

    # Find the direction away from the edge on each face
    var n1 = face1.normal()
    var n2 = face2.normal()
    var edge_dir = Vector3(e2.x - e1.x, e2.y - e1.y, e2.z - e1.z)
    var edge_len = edge_dir.length()
    if edge_len < 1e-15:
        return Face(List[Point]())
    edge_dir = edge_dir.normalize()

    # Perpendicular direction on each face (away from edge)
    var perp1 = n1.cross(edge_dir).normalize()
    var perp2 = n2.cross(edge_dir).normalize()

    # Chamfer points: offset from edge vertices along face perpendiculars
    var chamfer_pts = List[Point]()
    chamfer_pts.append(Point(e1.x + perp1.x * distance, e1.y + perp1.y * distance, e1.z + perp1.z * distance))
    chamfer_pts.append(Point(e2.x + perp1.x * distance, e2.y + perp1.y * distance, e2.z + perp1.z * distance))
    chamfer_pts.append(Point(e2.x + perp2.x * distance, e2.y + perp2.y * distance, e2.z + perp2.z * distance))
    chamfer_pts.append(Point(e1.x + perp2.x * distance, e1.y + perp2.y * distance, e1.z + perp2.z * distance))

    return Face(chamfer_pts)


def fillet_edge(face1: Face, face2: Face, radius: FType, segments: Int = 8) -> List[Face]:
    """Create a fillet (rounded) surface between two adjacent faces.

    Approximates a circular arc between the two faces with `segments` strips.
    Returns list of quad faces forming the fillet.
    """
    var shared = List[Point]()
    for i in range(face1.num_vertices()):
        var p1 = face1.get_vertex(i)
        for j in range(face2.num_vertices()):
            if p1 == face2.get_vertex(j):
                shared.append(p1)
                break

    if len(shared) < 2:
        return List[Face]()

    var e1 = shared[0]
    var e2 = shared[1]

    var n1 = face1.normal()
    var n2 = face2.normal()
    var edge_dir = Vector3(e2.x - e1.x, e2.y - e1.y, e2.z - e1.z).normalize()

    var perp1 = n1.cross(edge_dir).normalize()
    var perp2 = n2.cross(edge_dir).normalize()

    # Generate arc points between perp1 and perp2 directions
    var result = List[Face]()
    var angle = perp1.angle(perp2)
    if angle < 1e-10:
        return result^

    for s in range(segments):
        var t0 = FType(s) / FType(segments)
        var t1 = FType(s + 1) / FType(segments)
        var dir0 = perp1.lerp(perp2, t0).normalize() * radius
        var dir1 = perp1.lerp(perp2, t1).normalize() * radius

        var pts = List[Point]()
        pts.append(Point(e1.x + dir0.x, e1.y + dir0.y, e1.z + dir0.z))
        pts.append(Point(e2.x + dir0.x, e2.y + dir0.y, e2.z + dir0.z))
        pts.append(Point(e2.x + dir1.x, e2.y + dir1.y, e2.z + dir1.z))
        pts.append(Point(e1.x + dir1.x, e1.y + dir1.y, e1.z + dir1.z))
        result.append(Face(pts))

    return result^
