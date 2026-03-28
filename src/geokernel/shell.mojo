from geokernel import FType, Point, Face, Cell, Plane, Vector3, Wire


struct Shell(Copyable, Movable, ImplicitlyCopyable):
    var faces: List[Face]

    def __init__(out self, faces: List[Face]):
        self.faces = faces.copy()


    def __init__(out self, *, copy: Self):
        self.faces = copy.faces.copy()

    def __init__(out self, *, deinit take: Self):
        self.faces = take.faces^

    def __repr__(self) -> String:
        var result: String = "Shell(\n"
        for i in range(len(self.faces)):
            if i > 0:
                result += ",\n"
            result += self.faces[i].__repr__()
        return result + ")"

    def area(self) -> FType:
        var area: FType = 0.0
        for i in range(len(self.faces)):
            area += self.faces[i].area()
        return area

    def open_edges(self) -> List[Tuple[Point, Point]]:
        """Return edges not shared by exactly 2 faces.
        Uses hash-based edge key for O(n) matching instead of O(n²)."""
        from std.collections import Dict
        var edge_counts = Dict[String, Int]()
        var edge_map = Dict[String, Tuple[Point, Point]]()

        for fi in range(len(self.faces)):
            var face = self.faces[fi]
            var n = face.num_edges()
            for ei in range(n):
                var edge = face.get_edge(ei)
                var p1 = edge.p1
                var p2 = edge.p2
                # Create canonical edge key (sorted by coordinates)
                var k1 = String(p1.x) + "," + String(p1.y) + "," + String(p1.z)
                var k2 = String(p2.x) + "," + String(p2.y) + "," + String(p2.z)
                var key: String
                if k1 < k2:
                    key = k1 + "|" + k2
                else:
                    key = k2 + "|" + k1
                if key in edge_counts:
                    edge_counts[key] = edge_counts[key] + 1
                else:
                    edge_counts[key] = 1
                    edge_map[key] = (p1, p2)

        var result = List[Tuple[Point, Point]]()
        for entry in edge_counts.items():
            if entry[].value != 2:
                result.append(edge_map[entry[].key])
        return result^

    def has_holes(self) -> Bool:
        """True if any edge is not shared by exactly 2 faces."""
        var open = self.open_edges()
        return len(open) > 0

    def slice(self, p: Plane) -> Tuple[Shell, Shell]:
        """Slice shell by plane.
        Faces whose centroid is on the positive side go to the first shell, negative to second.
        Faces straddling the plane are not split (stub for complex cases)."""
        var above = List[Face]()
        var below = List[Face]()
        for i in range(len(self.faces)):
            var face = self.faces[i]
            var c = face.centroid()
            var dist = p.distance_to_point(c)
            if dist >= 0:
                above.append(face)
            else:
                below.append(face)
        return (Shell(above), Shell(below))

    def boundary_wires(self) -> List[Wire]:
        """Assemble open edges into closed (or open) wires."""
        var open = self.open_edges()
        if len(open) == 0:
            return List[Wire]()

        # Build adjacency: each edge is (p1, p2)
        # Greedily chain edges into wires
        var used = List[Bool]()
        for _ in range(len(open)):
            used.append(False)

        var wires = List[Wire]()
        for start in range(len(open)):
            if used[start]:
                continue
            var chain = List[Point]()
            chain.append(open[start][0])
            chain.append(open[start][1])
            used[start] = True
            var extended = True
            while extended:
                extended = False
                var tail = chain[len(chain) - 1]
                for k in range(len(open)):
                    if used[k]:
                        continue
                    if open[k][0] == tail:
                        chain.append(open[k][1])
                        used[k] = True
                        extended = True
                        break
                    elif open[k][1] == tail:
                        chain.append(open[k][0])
                        used[k] = True
                        extended = True
                        break
            wires.append(Wire(chain))
        return wires^

    # fn cap(): #cap gaps

    # fn close() -> Cell: # if there are no gaps left then can be closed and return cell object

    # fn mesh, use face.triangulate()
