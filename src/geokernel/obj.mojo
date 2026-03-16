from geokernel import FType, Point, Face, Shell
from geokernel.triangulation import Triangulation
from math import abs as fabs


fn shell_to_obj(shell: Shell) -> String:
    """Export a Shell to Wavefront OBJ format.

    Faces are triangulated before export.
    Output:
        v x y z   (one per unique vertex)
        f i j k   (1-indexed triangle indices)
    """
    # Collect all triangulated faces
    var triangles = List[List[Int]]()  # global index triples
    var all_points = List[List[Float64]]()  # x, y, z

    # We accumulate vertices globally with a simple list; no deduplication.
    var vertex_offset = 0

    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        var tris = Triangulation.triangulate(face.points)
        # For this face, vertices start at vertex_offset+1 (1-indexed OBJ)
        for i in range(face.num_vertices()):
            var p = face.get_vertex(i)
            var pt = List[Float64]()
            pt.append(Float64(p.x))
            pt.append(Float64(p.y))
            pt.append(Float64(p.z))
            all_points.append(pt)

        for ti in range(len(tris)):
            var tri = List[Int]()
            tri.append(tris[ti][0] + vertex_offset + 1)
            tri.append(tris[ti][1] + vertex_offset + 1)
            tri.append(tris[ti][2] + vertex_offset + 1)
            triangles.append(tri)

        vertex_offset += face.num_vertices()

    # Build OBJ string
    var result: String = "# OBJ export by geokernel\n"

    for i in range(len(all_points)):
        result += (
            "v "
            + String(all_points[i][0])
            + " "
            + String(all_points[i][1])
            + " "
            + String(all_points[i][2])
            + "\n"
        )

    for i in range(len(triangles)):
        result += (
            "f "
            + String(triangles[i][0])
            + " "
            + String(triangles[i][1])
            + " "
            + String(triangles[i][2])
            + "\n"
        )

    return result


fn faces_to_obj(faces: List[Face]) -> String:
    """Export a list of Faces to Wavefront OBJ format.

    Faces are triangulated before export.
    Output:
        v x y z   (one per vertex, per face — no deduplication)
        f i j k   (1-indexed triangle indices)
    """
    var triangles = List[List[Int]]()
    var all_points = List[List[Float64]]()
    var vertex_offset = 0

    for fi in range(len(faces)):
        var face = faces[fi]
        var tris = Triangulation.triangulate(face.points)

        for i in range(face.num_vertices()):
            var p = face.get_vertex(i)
            var pt = List[Float64]()
            pt.append(Float64(p.x))
            pt.append(Float64(p.y))
            pt.append(Float64(p.z))
            all_points.append(pt)

        for ti in range(len(tris)):
            var tri = List[Int]()
            tri.append(tris[ti][0] + vertex_offset + 1)
            tri.append(tris[ti][1] + vertex_offset + 1)
            tri.append(tris[ti][2] + vertex_offset + 1)
            triangles.append(tri)

        vertex_offset += face.num_vertices()

    var result: String = "# OBJ export by geokernel\n"

    for i in range(len(all_points)):
        result += (
            "v "
            + String(all_points[i][0])
            + " "
            + String(all_points[i][1])
            + " "
            + String(all_points[i][2])
            + "\n"
        )

    for i in range(len(triangles)):
        result += (
            "f "
            + String(triangles[i][0])
            + " "
            + String(triangles[i][1])
            + " "
            + String(triangles[i][2])
            + "\n"
        )

    return result


fn _split_line(line: String) -> List[String]:
    """Split a line by whitespace into tokens."""
    var tokens = List[String]()
    var current = String("")
    for i in range(len(line)):
        var c = String(line[byte=i])
        if c == " " or c == "\t":
            if len(current) > 0:
                tokens.append(current)
                current = String("")
        else:
            current += c
    if len(current) > 0:
        tokens.append(current)
    return tokens^


fn _pts_equal(a: Point, b: Point, tol: FType = 1e-10) -> Bool:
    """Check if two points are equal within tolerance."""
    return (
        fabs(a.x - b.x) < tol
        and fabs(a.y - b.y) < tol
        and fabs(a.z - b.z) < tol
    )


fn _find_vertex(vertices: List[Point], p: Point, tol: FType = 1e-10) -> Int:
    """Return 0-based index of p in vertices (by coordinate), or -1 if not found."""
    for i in range(len(vertices)):
        if _pts_equal(vertices[i], p, tol):
            return i
    return -1


fn export_obj(faces: List[Face]) -> String:
    """Export list of faces to OBJ format string.

    Format:
      # geokernel OBJ export
      v x y z       (one per unique vertex, deduplicated by coordinate)
      f i j k ...   (1-indexed face indices, no closing duplicate)
    """
    var vertices = List[Point]()
    var result: String = "# geokernel OBJ export\n"

    # First pass: collect unique vertices and build face lines
    var face_lines = List[String]()

    for fi in range(len(faces)):
        var face = faces[fi]
        var n = face.num_vertices()  # excludes closing duplicate
        var fline = String("f")
        for vi in range(n):
            var p = face.get_vertex(vi)
            var idx = _find_vertex(vertices, p)
            if idx == -1:
                vertices.append(p)
                idx = len(vertices) - 1
            fline += " " + String(idx + 1)  # 1-based
        face_lines.append(fline + "\n")

    for i in range(len(vertices)):
        var p = vertices[i]
        result += "v " + String(p.x) + " " + String(p.y) + " " + String(p.z) + "\n"

    for fi in range(len(face_lines)):
        result += face_lines[fi]

    return result


fn import_obj(content: String) raises -> List[Face]:
    """Parse OBJ format string into list of faces.

    Handles: v lines, f lines.
    Ignores: #, vn, vt, o, g, s, usemtl.
    f indices are 1-based in OBJ.
    """
    var vertices = List[Point]()
    var faces = List[Face]()
    var lines = content.splitlines()

    for li in range(len(lines)):
        var line = String(String(lines[li]).strip())
        if len(line) == 0:
            continue
        var tokens = _split_line(line)
        if len(tokens) == 0:
            continue

        if tokens[0] == "v" and len(tokens) >= 4:
            var x = FType(atof(tokens[1]))
            var y = FType(atof(tokens[2]))
            var z = FType(atof(tokens[3]))
            vertices.append(Point(x, y, z))

        elif tokens[0] == "f" and len(tokens) >= 4:
            var pts = List[Point]()
            for ti in range(1, len(tokens)):
                # Handle "v/vt/vn" format — take only the first part (before '/')
                var tok = tokens[ti]
                var idx_str = String("")
                for ci in range(len(tok)):
                    var ch = String(tok[byte=ci])
                    if ch == "/":
                        break
                    idx_str += ch
                var idx = Int(idx_str) - 1  # convert to 0-based
                if idx >= 0 and idx < len(vertices):
                    pts.append(vertices[idx])
            if len(pts) >= 3:
                faces.append(Face(pts))

    return faces^
