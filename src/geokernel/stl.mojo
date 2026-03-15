from geokernel import Face, Shell, Vector3
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
