from geokernel import FType, Point, Face


struct Triangulation:
    @staticmethod
    fn triangulate(points: List[Point]) -> List[List[Int]]:
        """Fan triangulation for convex polygons.
        Returns list of triangles as index triples."""
        var result = List[List[Int]]()
        var n = len(points)
        if n < 3:
            return result.copy()
        for i in range(1, n - 1):
            var tri = List[Int]()
            tri.append(0)
            tri.append(i)
            tri.append(i + 1)
            result.append(tri.copy())
        return result.copy()

    @staticmethod
    fn triangulate_to_points(points: List[Point]) -> List[List[Point]]:
        """Returns triangles as point lists."""
        var result = List[List[Point]]()
        var n = len(points)
        if n < 3:
            return result.copy()
        for i in range(1, n - 1):
            var tri = List[Point]()
            tri.append(points[0])
            tri.append(points[i])
            tri.append(points[i + 1])
            result.append(tri.copy())
        return result.copy()

    @staticmethod
    fn triangulate_face(face: Face) -> List[Face]:
        """Fan triangulation from first vertex. Returns list of triangle Faces."""
        var result = List[Face]()
        var n = face.num_vertices()
        if n < 3:
            return result^
        for i in range(1, n - 1):
            var tri_pts = List[Point]()
            tri_pts.append(face.get_vertex(0))
            tri_pts.append(face.get_vertex(i))
            tri_pts.append(face.get_vertex(i + 1))
            result.append(Face(tri_pts))
        return result^
