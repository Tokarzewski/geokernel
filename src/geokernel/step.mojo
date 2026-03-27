"""STEP file format (ISO 10303-21) export for geokernel geometry.

Implements a subset of AP203/AP214 sufficient for exporting:
- Closed shells (CLOSED_SHELL / MANIFOLD_SOLID_BREP)
- Faces (ADVANCED_FACE with FACE_OUTER_BOUND)
- Edges (EDGE_CURVE with LINE geometry)
- Vertices (VERTEX_POINT with CARTESIAN_POINT)

This is write-only; STEP import requires a full parser for the EXPRESS
data model and is out of scope for the initial implementation.

Reference: ISO 10303-21:2002, AP203, AP214
"""

from geokernel import FType, Point, Vector3, Face, Shell


def _fmt(v: FType) -> String:
    """Format a float for STEP output."""
    return String(v)


struct StepWriter:
    """Incremental STEP entity writer.

    Each entity gets a unique #N ID. Build entities bottom-up:
    cartesian points → vertex points → edge curves → edge loops →
    face bounds → advanced faces → closed shell → manifold solid brep.
    """

    var _entities: List[String]
    var _next_id: Int

    def __init__(out self):
        self._entities = List[String]()
        self._next_id = 1

    def _add(mut self, entity: String) -> Int:
        """Add an entity line and return its ID."""
        var eid = self._next_id
        self._entities.append("#" + String(eid) + " = " + entity + ";")
        self._next_id += 1
        return eid

    def cartesian_point(mut self, p: Point) -> Int:
        return self._add(
            "CARTESIAN_POINT('', (" + _fmt(p.x) + ", " + _fmt(p.y) + ", " + _fmt(p.z) + "))"
        )

    def direction(mut self, v: Vector3) -> Int:
        return self._add(
            "DIRECTION('', (" + _fmt(v.x) + ", " + _fmt(v.y) + ", " + _fmt(v.z) + "))"
        )

    def vertex_point(mut self, point_id: Int) -> Int:
        return self._add("VERTEX_POINT('', #" + String(point_id) + ")")

    def vector(mut self, dir_id: Int, magnitude: FType) -> Int:
        return self._add("VECTOR('', #" + String(dir_id) + ", " + _fmt(magnitude) + ")")

    def line(mut self, point_id: Int, vector_id: Int) -> Int:
        return self._add("LINE('', #" + String(point_id) + ", #" + String(vector_id) + ")")

    def edge_curve(mut self, v1_id: Int, v2_id: Int, curve_id: Int) -> Int:
        return self._add(
            "EDGE_CURVE('', #" + String(v1_id) + ", #" + String(v2_id)
            + ", #" + String(curve_id) + ", .T.)"
        )

    def oriented_edge(mut self, edge_id: Int, orientation: Bool) -> Int:
        var orient = ".T." if orientation else ".F."
        return self._add(
            "ORIENTED_EDGE('', *, *, #" + String(edge_id) + ", " + orient + ")"
        )

    def edge_loop(mut self, edge_ids: List[Int]) -> Int:
        var refs = String("(")
        for i in range(len(edge_ids)):
            if i > 0:
                refs += ", "
            refs += "#" + String(edge_ids[i])
        refs += ")"
        return self._add("EDGE_LOOP('', " + refs + ")")

    def face_outer_bound(mut self, loop_id: Int) -> Int:
        return self._add("FACE_OUTER_BOUND('', #" + String(loop_id) + ", .T.)")

    def plane(mut self, point_id: Int, axis_id: Int, ref_dir_id: Int) -> Int:
        var placement = self._add(
            "AXIS2_PLACEMENT_3D('', #" + String(point_id)
            + ", #" + String(axis_id)
            + ", #" + String(ref_dir_id) + ")"
        )
        return self._add("PLANE('', #" + String(placement) + ")")

    def advanced_face(mut self, bound_ids: List[Int], surface_id: Int) -> Int:
        var refs = String("(")
        for i in range(len(bound_ids)):
            if i > 0:
                refs += ", "
            refs += "#" + String(bound_ids[i])
        refs += ")"
        return self._add(
            "ADVANCED_FACE('', " + refs + ", #" + String(surface_id) + ", .T.)"
        )

    def closed_shell(mut self, face_ids: List[Int]) -> Int:
        var refs = String("(")
        for i in range(len(face_ids)):
            if i > 0:
                refs += ", "
            refs += "#" + String(face_ids[i])
        refs += ")"
        return self._add("CLOSED_SHELL('', " + refs + ")")

    def manifold_solid_brep(mut self, shell_id: Int) -> Int:
        return self._add("MANIFOLD_SOLID_BREP('', #" + String(shell_id) + ")")

    def to_string(self) -> String:
        var result = String("")
        for i in range(len(self._entities)):
            result += self._entities[i] + "\n"
        return result


def export_step(shell: Shell, name: String = "geokernel") -> String:
    """Export a Shell to STEP AP203 format.

    Creates a MANIFOLD_SOLID_BREP containing a CLOSED_SHELL with
    ADVANCED_FACE entities for each face.

    Args:
        shell: The geokernel Shell to export.
        name: Name for the STEP file header.

    Returns:
        STEP file content as a string.
    """
    var w = StepWriter()

    var face_ids = List[Int]()

    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        var nv = face.num_vertices()
        if nv < 3:
            continue

        # Create vertices and edges for this face
        var vert_point_ids = List[Int]()
        var vert_ids = List[Int]()
        for vi in range(nv):
            var p = face.get_vertex(vi)
            var cp_id = w.cartesian_point(p)
            vert_point_ids.append(cp_id)
            var vp_id = w.vertex_point(cp_id)
            vert_ids.append(vp_id)

        # Create edges
        var oriented_edge_ids = List[Int]()
        for ei in range(nv):
            var v1_idx = ei
            var v2_idx = (ei + 1) % nv
            var p1 = face.get_vertex(v1_idx)
            var p2 = face.get_vertex(v2_idx)
            var dx = p2.x - p1.x
            var dy = p2.y - p1.y
            var dz = p2.z - p1.z
            var length = (dx * dx + dy * dy + dz * dz)
            if length > 0.0:
                length = length ** 0.5
            else:
                length = 1.0
            var dir_id = w.direction(Vector3(dx / length, dy / length, dz / length))
            var vec_id = w.vector(dir_id, length)
            var line_id = w.line(vert_point_ids[v1_idx], vec_id)
            var ec_id = w.edge_curve(vert_ids[v1_idx], vert_ids[v2_idx], line_id)
            var oe_id = w.oriented_edge(ec_id, True)
            oriented_edge_ids.append(oe_id)

        var loop_id = w.edge_loop(oriented_edge_ids)
        var bound_id = w.face_outer_bound(loop_id)

        # Create surface (PLANE for planar faces)
        var n = face.normal()
        var centroid = face.centroid()
        var cp_id = w.cartesian_point(centroid)
        var axis_id = w.direction(n)
        # Reference direction: perpendicular to normal
        var ref_dir: Vector3
        if abs(n.x) < 0.9:
            ref_dir = Vector3(1.0, 0.0, 0.0)
        else:
            ref_dir = Vector3(0.0, 1.0, 0.0)
        # Cross product to get perpendicular
        var cross_x = n.y * ref_dir.z - n.z * ref_dir.y
        var cross_y = n.z * ref_dir.x - n.x * ref_dir.z
        var cross_z = n.x * ref_dir.y - n.y * ref_dir.x
        var cross_len = (cross_x * cross_x + cross_y * cross_y + cross_z * cross_z)
        if cross_len > 0.0:
            cross_len = cross_len ** 0.5
            cross_x /= cross_len
            cross_y /= cross_len
            cross_z /= cross_len
        var ref_id = w.direction(Vector3(cross_x, cross_y, cross_z))
        var plane_id = w.plane(cp_id, axis_id, ref_id)

        var bounds = List[Int]()
        bounds.append(bound_id)
        var af_id = w.advanced_face(bounds, plane_id)
        face_ids.append(af_id)

    var shell_id = w.closed_shell(face_ids)
    var brep_id = w.manifold_solid_brep(shell_id)

    # Build STEP file
    var result = String("ISO-10303-21;\n")
    result += "HEADER;\n"
    result += "FILE_DESCRIPTION((''), '2;1');\n"
    result += "FILE_NAME('" + name + ".step', '', (''), (''), '', 'geokernel', '');\n"
    result += "FILE_SCHEMA(('AUTOMOTIVE_DESIGN'));\n"
    result += "ENDSEC;\n"
    result += "DATA;\n"
    result += w.to_string()
    result += "ENDSEC;\n"
    result += "END-ISO-10303-21;\n"
    return result


def faces_to_step(faces: List[Face], name: String = "geokernel") -> String:
    """Export a list of faces to STEP format by wrapping them in a Shell."""
    var shell = Shell(faces)
    return export_step(shell, name)
