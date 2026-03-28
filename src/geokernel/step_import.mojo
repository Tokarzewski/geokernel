"""STEP file import (ISO 10303-21) for geokernel.

Parses a subset of AP203/AP214 STEP files:
- CARTESIAN_POINT → Point
- DIRECTION → Vector3
- VERTEX_POINT → vertex reference
- EDGE_CURVE (LINE) → edge
- ORIENTED_EDGE → edge with direction
- EDGE_LOOP → wire
- FACE_OUTER_BOUND → face boundary
- ADVANCED_FACE → Face
- CLOSED_SHELL → Shell
- MANIFOLD_SOLID_BREP → Shell
"""

from geokernel import FType, Point, Vector3, Face, Shell
from std.collections import Dict


def _strip(s: String) -> String:
    """Remove leading/trailing whitespace."""
    var start = 0
    var end = len(s)
    while start < end and (s[byte=start] == " " or s[byte=start] == "\t" or s[byte=start] == "\n" or s[byte=start] == "\r"):
        start += 1
    while end > start and (s[byte=end-1] == " " or s[byte=end-1] == "\t" or s[byte=end-1] == "\n" or s[byte=end-1] == "\r"):
        end -= 1
    return String(s[byte=start:end])


def _parse_float(s: String) raises -> FType:
    return FType(Float64(atof(s)))


def _parse_int_ref(s: String) -> Int:
    """Parse #123 → 123."""
    var stripped = _strip(s)
    if len(stripped) > 0 and stripped[byte=0] == "#":
        stripped = String(stripped[byte=1:])
    try:
        return Int(atof(stripped))
    except:
        return -1


def _parse_entity(line: String) -> (Int, String, String):
    """Parse '#123 = TYPE(args);' → (123, 'TYPE', 'args').
    Returns (-1, '', '') on failure."""
    var eq_pos = line.find("=")
    if eq_pos == -1:
        return (-1, String(""), String(""))
    var id_str = _strip(String(line[byte=0:eq_pos]))
    var id_val = _parse_int_ref(id_str)
    var rest = _strip(String(line[byte=eq_pos+1:]))
    # Remove trailing semicolon
    if len(rest) > 0 and rest[byte=len(rest)-1] == ";":
        rest = String(rest[byte=0:len(rest)-1])
    rest = _strip(rest)
    var paren_pos = rest.find("(")
    if paren_pos == -1:
        return (id_val, rest, String(""))
    var type_name = _strip(String(rest[byte=0:paren_pos]))
    # Find matching closing paren
    var args = String(rest[byte=paren_pos+1:len(rest)-1]) if rest[byte=len(rest)-1] == ")" else String(rest[byte=paren_pos+1:])
    return (id_val, type_name, args)


def _split_top_level_args(args: String) -> List[String]:
    """Split args by comma, respecting nested parentheses."""
    var result = List[String]()
    var depth = 0
    var start = 0
    for i in range(len(args)):
        var c = args[byte=i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        elif c == "," and depth == 0:
            result.append(_strip(String(args[byte=start:i])))
            start = i + 1
    if start < len(args):
        result.append(_strip(String(args[byte=start:])))
    return result^


def _parse_float_list(s: String) raises -> List[FType]:
    """Parse '(1.0, 2.0, 3.0)' → [1.0, 2.0, 3.0]."""
    var inner = _strip(s)
    if len(inner) > 0 and inner[byte=0] == "(":
        inner = String(inner[byte=1:])
    if len(inner) > 0 and inner[byte=len(inner)-1] == ")":
        inner = String(inner[byte=0:len(inner)-1])
    var parts = _split_top_level_args(inner)
    var result = List[FType]()
    for i in range(len(parts)):
        result.append(_parse_float(_strip(parts[i])))
    return result^


def _parse_ref_list(s: String) -> List[Int]:
    """Parse '(#1, #2, #3)' → [1, 2, 3]."""
    var inner = _strip(s)
    if len(inner) > 0 and inner[byte=0] == "(":
        inner = String(inner[byte=1:])
    if len(inner) > 0 and inner[byte=len(inner)-1] == ")":
        inner = String(inner[byte=0:len(inner)-1])
    var parts = _split_top_level_args(inner)
    var result = List[Int]()
    for i in range(len(parts)):
        var r = _parse_int_ref(parts[i])
        if r >= 0:
            result.append(r)
    return result^


def import_step(content: String) raises -> Shell:
    """Parse a STEP file and return a Shell.

    Extracts geometry from the DATA section, resolving entity references
    to build Points → Faces → Shell.
    """
    # Find DATA section
    var data_start = content.find("DATA;")
    var data_end = content.find("ENDSEC;", data_start + 1 if data_start >= 0 else 0)
    if data_start == -1 or data_end == -1:
        return Shell(List[Face]())

    var data_section = String(content[byte=data_start+5:data_end])

    # Parse all entities into a map
    var entity_types = Dict[Int, String]()
    var entity_args = Dict[Int, String]()

    # Split into lines (entities can span multiple lines in STEP)
    # Reassemble by joining until we hit a semicolon
    var current_line = String("")
    for i in range(len(data_section)):
        var c = data_section[byte=i]
        if c == ";":
            current_line += ";"
            var line = _strip(current_line)
            if len(line) > 1 and line[byte=0] == "#":
                var parsed = _parse_entity(line)
                if parsed[0] >= 0:
                    entity_types[parsed[0]] = parsed[1]
                    entity_args[parsed[0]] = parsed[2]
            current_line = String("")
        else:
            current_line += String(data_section[byte=i:i+1])

    # Resolve entities bottom-up
    var points = Dict[Int, Point]()
    var directions = Dict[Int, Vector3]()

    # First pass: CARTESIAN_POINT and DIRECTION
    for entry in entity_types.items():
        var eid = entry[].key
        var etype = entry[].value
        if etype == "CARTESIAN_POINT":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 2:
                var coords = _parse_float_list(args[1])
                if len(coords) >= 3:
                    points[eid] = Point(coords[0], coords[1], coords[2])
        elif etype == "DIRECTION":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 2:
                var coords = _parse_float_list(args[1])
                if len(coords) >= 3:
                    directions[eid] = Vector3(coords[0], coords[1], coords[2])

    # Resolve VERTEX_POINT → Point
    var vertex_points = Dict[Int, Point]()
    for entry in entity_types.items():
        var eid = entry[].key
        if entry[].value == "VERTEX_POINT":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 2:
                var pt_ref = _parse_int_ref(args[1])
                if pt_ref in points:
                    vertex_points[eid] = points[pt_ref]

    # Resolve EDGE_CURVE → (vertex1_id, vertex2_id)
    var edge_curves = Dict[Int, List[Int]]()
    for entry in entity_types.items():
        var eid = entry[].key
        if entry[].value == "EDGE_CURVE":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 3:
                var v1 = _parse_int_ref(args[1])
                var v2 = _parse_int_ref(args[2])
                var refs = List[Int]()
                refs.append(v1)
                refs.append(v2)
                edge_curves[eid] = refs^

    # Resolve ORIENTED_EDGE → edge_curve ref
    var oriented_edges = Dict[Int, Int]()
    for entry in entity_types.items():
        var eid = entry[].key
        if entry[].value == "ORIENTED_EDGE":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 4:
                var ec_ref = _parse_int_ref(args[3])
                oriented_edges[eid] = ec_ref

    # Resolve EDGE_LOOP → list of oriented_edge refs
    var edge_loops = Dict[Int, List[Int]]()
    for entry in entity_types.items():
        var eid = entry[].key
        if entry[].value == "EDGE_LOOP":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 2:
                edge_loops[eid] = _parse_ref_list(args[1])

    # Resolve FACE_OUTER_BOUND → edge_loop ref
    var face_bounds = Dict[Int, Int]()
    for entry in entity_types.items():
        var eid = entry[].key
        if entry[].value == "FACE_OUTER_BOUND" or entry[].value == "FACE_BOUND":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 2:
                face_bounds[eid] = _parse_int_ref(args[1])

    # Resolve ADVANCED_FACE → list of face_bound refs
    var advanced_faces = Dict[Int, List[Int]]()
    for entry in entity_types.items():
        var eid = entry[].key
        if entry[].value == "ADVANCED_FACE":
            var args = _split_top_level_args(entity_args[eid])
            if len(args) >= 2:
                advanced_faces[eid] = _parse_ref_list(args[1])

    # Build faces by walking: ADVANCED_FACE → FACE_BOUND → EDGE_LOOP → ORIENTED_EDGE → EDGE_CURVE → VERTEX_POINT → Point
    var result_faces = List[Face]()
    for af_entry in advanced_faces.items():
        var bound_refs = af_entry[].value
        var face_pts = List[Point]()
        for bi in range(len(bound_refs)):
            var bound_id = bound_refs[bi]
            if bound_id not in face_bounds:
                continue
            var loop_id = face_bounds[bound_id]
            if loop_id not in edge_loops:
                continue
            var oe_refs = edge_loops[loop_id]
            for oei in range(len(oe_refs)):
                var oe_id = oe_refs[oei]
                if oe_id not in oriented_edges:
                    continue
                var ec_id = oriented_edges[oe_id]
                if ec_id not in edge_curves:
                    continue
                var ec_verts = edge_curves[ec_id]
                if len(ec_verts) >= 1:
                    var v_id = ec_verts[0]
                    if v_id in vertex_points:
                        var pt = vertex_points[v_id]
                        # Avoid duplicating the last point
                        if len(face_pts) == 0 or not (face_pts[len(face_pts)-1] == pt):
                            face_pts.append(pt)
        if len(face_pts) >= 3:
            result_faces.append(Face(face_pts))

    return Shell(result_faces)
