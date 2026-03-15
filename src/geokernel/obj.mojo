from geokernel import Face, Shell
from geokernel.triangulation import Triangulation


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
