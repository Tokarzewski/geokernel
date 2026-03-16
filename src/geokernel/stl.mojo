from geokernel import FType, Point, Face, Shell, Vector3
from geokernel.triangulation import Triangulation


fn shell_to_stl_ascii(shell: Shell) -> String:
    """Export a Shell to ASCII STL format.

    Faces are triangulated using fan triangulation before export.

    Output format:
        solid name
          facet normal nx ny nz
            outer loop
              vertex x y z
              vertex x y z
              vertex x y z
            endloop
          endfacet
        endsolid name
    """
    var result: String = "solid geokernel\n"

    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        var tris = Triangulation.triangulate_face(face)

        for ti in range(len(tris)):
            var tri = tris[ti]
            # Compute face normal
            var n = tri.normal()
            var nx = Float64(n.x)
            var ny = Float64(n.y)
            var nz = Float64(n.z)

            result += (
                "  facet normal "
                + String(nx)
                + " "
                + String(ny)
                + " "
                + String(nz)
                + "\n"
            )
            result += "    outer loop\n"

            for vi in range(tri.num_vertices()):
                var p = tri.get_vertex(vi)
                result += (
                    "      vertex "
                    + String(Float64(p.x))
                    + " "
                    + String(Float64(p.y))
                    + " "
                    + String(Float64(p.z))
                    + "\n"
                )

            result += "    endloop\n"
            result += "  endfacet\n"

    result += "endsolid geokernel\n"
    return result


fn export_stl_ascii(faces: List[Face], solid_name: String = "geokernel") -> String:
    """Export triangulated faces to ASCII STL format.
    Non-triangle faces are fan-triangulated first.

    Format:
      solid <name>
        facet normal nx ny nz
          outer loop
            vertex x y z
            vertex x y z
            vertex x y z
          endloop
        endfacet
      endsolid <name>
    """
    var result: String = "solid " + solid_name + "\n"

    for fi in range(len(faces)):
        var face = faces[fi]
        var tris = Triangulation.triangulate_face(face)

        for ti in range(len(tris)):
            var tri = tris[ti]
            var n = tri.normal()

            result += (
                "  facet normal "
                + String(Float64(n.x))
                + " "
                + String(Float64(n.y))
                + " "
                + String(Float64(n.z))
                + "\n"
            )
            result += "    outer loop\n"

            for vi in range(tri.num_vertices()):
                var p = tri.get_vertex(vi)
                result += (
                    "      vertex "
                    + String(Float64(p.x))
                    + " "
                    + String(Float64(p.y))
                    + " "
                    + String(Float64(p.z))
                    + "\n"
                )

            result += "    endloop\n"
            result += "  endfacet\n"

    result += "endsolid " + solid_name + "\n"
    return result


fn _parse_float(s: String) raises -> FType:
    """Parse a float from a string token."""
    return FType(atof(s.strip()))


fn import_stl_ascii(content: String) raises -> List[Face]:
    """Parse ASCII STL string into list of triangle faces.
    Each facet becomes one Face(3 points).
    """
    var faces = List[Face]()
    var lines = content.splitlines()

    var i = 0
    while i < len(lines):
        var line = String(lines[i]).strip()
        if line.startswith("facet normal"):
            # Read 3 vertices: skip "outer loop" line then read 3 vertex lines
            var v_count = 0
            var pts = List[Point]()
            var j = i + 2  # skip "outer loop"
            while j < len(lines) and v_count < 3:
                var vline = String(lines[j]).strip()
                if vline.startswith("vertex"):
                    var parts = vline.split(" ")
                    var x = _parse_float(String(parts[1]))
                    var y = _parse_float(String(parts[2]))
                    var z = _parse_float(String(parts[3]))
                    pts.append(Point(x, y, z))
                    v_count += 1
                j += 1
            if len(pts) == 3:
                faces.append(Face(pts))
        i += 1

    return faces^
