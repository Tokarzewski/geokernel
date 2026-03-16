from geokernel import FType, Point
from math import sqrt, inf


# ---------------------------------------------------------------------------
# KD-Tree — index-based flat-array implementation
# ---------------------------------------------------------------------------
# Uses a pre-allocated List[KDNode] where each node stores indices to its
# children instead of pointers, avoiding Mojo ownership issues with recursive
# self-referential structs.

alias KDTREE_NONE: Int = -1


struct KDNode(Copyable, Movable, ImplicitlyCopyable):
    """A single node in the KD-tree.

    Stores:
      - point_idx: index into the original points list
      - left / right: indices into KDTree.nodes (-1 = no child)
      - axis: split axis (0=x, 1=y, 2=z)
    """
    var point_idx: Int
    var left: Int
    var right: Int
    var axis: Int

    fn __init__(out self, point_idx: Int, left: Int, right: Int, axis: Int):
        self.point_idx = point_idx
        self.left = left
        self.right = right
        self.axis = axis

    fn __copyinit__(out self, copy: Self):
        self.point_idx = copy.point_idx
        self.left = copy.left
        self.right = copy.right
        self.axis = copy.axis

    fn __moveinit__(out self, deinit take: Self):
        self.point_idx = take.point_idx
        self.left = take.left
        self.right = take.right
        self.axis = take.axis


fn _coord(p: Point, axis: Int) -> FType:
    """Return the axis-th coordinate of a point."""
    if axis == 0:
        return p.x
    elif axis == 1:
        return p.y
    else:
        return p.z


fn _dist_sq(a: Point, b: Point) -> FType:
    """Squared Euclidean distance between two points."""
    var dx = a.x - b.x
    var dy = a.y - b.y
    var dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz


struct KDTree(Copyable, Movable, ImplicitlyCopyable):
    """3D KD-tree over a set of points.

    Build: O(n log^2 n)  — selection-sort median finding is O(n) per level.
    Query: O(log n) expected for nearest / k-nearest / radius.
    """

    var nodes: List[KDNode]
    var points: List[Point]
    var root: Int   # index of root node in self.nodes (-1 if empty)

    fn __init__(out self, points: List[Point]):
        self.nodes = List[KDNode]()
        self.points = points.copy()
        self.root = KDTREE_NONE
        var n = len(points)
        if n == 0:
            return
        # Build an index array [0, 1, ..., n-1]
        var indices = List[Int]()
        for i in range(n):
            indices.append(i)
        self.root = self._build(indices, 0)

    fn __copyinit__(out self, copy: Self):
        self.nodes = copy.nodes.copy()
        self.points = copy.points.copy()
        self.root = copy.root

    fn __moveinit__(out self, deinit take: Self):
        self.nodes = take.nodes^
        self.points = take.points^
        self.root = take.root

    # ------------------------------------------------------------------
    # Build helpers
    # ------------------------------------------------------------------

    fn _build(mut self, indices: List[Int], depth: Int) -> Int:
        """Recursively build the KD-tree. Returns the node index of the root."""
        var n = len(indices)
        if n == 0:
            return KDTREE_NONE

        var axis = depth % 3

        if n == 1:
            var node_idx = len(self.nodes)
            self.nodes.append(KDNode(indices[0], KDTREE_NONE, KDTREE_NONE, axis))
            return node_idx

        # Find median index by sorting a copy of indices by the current axis coordinate
        var sorted_indices = indices.copy()
        # Simple insertion sort (fine for small n; KD-tree build is O(n log²n) overall)
        var m = len(sorted_indices)
        for i in range(1, m):
            var key = sorted_indices[i]
            var j = i - 1
            while j >= 0 and _coord(self.points[sorted_indices[j]], axis) > _coord(self.points[key], axis):
                sorted_indices[j + 1] = sorted_indices[j]
                j -= 1
            sorted_indices[j + 1] = key

        var median = m // 2
        var median_pt_idx = sorted_indices[median]

        # Reserve a slot for this node (will fill in children after recursion)
        var node_idx = len(self.nodes)
        self.nodes.append(KDNode(median_pt_idx, KDTREE_NONE, KDTREE_NONE, axis))

        # Left subtree: indices before median
        var left_indices = List[Int]()
        for i in range(median):
            left_indices.append(sorted_indices[i])
        var left_child = self._build(left_indices, depth + 1)

        # Right subtree: indices after median
        var right_indices = List[Int]()
        for i in range(median + 1, m):
            right_indices.append(sorted_indices[i])
        var right_child = self._build(right_indices, depth + 1)

        # Patch children back (node_idx is stable since we reserved the slot)
        self.nodes[node_idx].left = left_child
        self.nodes[node_idx].right = right_child

        return node_idx

    # ------------------------------------------------------------------
    # Nearest neighbour
    # ------------------------------------------------------------------

    fn nearest(self, query: Point) -> Point:
        """Return the closest point to query."""
        if self.root == KDTREE_NONE:
            return query  # empty tree — return query as fallback
        var best_idx = self.nodes[self.root].point_idx
        var best_dist = _dist_sq(query, self.points[best_idx])
        self._nearest_search(self.root, query, best_idx, best_dist)
        return self.points[best_idx]

    fn _nearest_search(
        self,
        node_idx: Int,
        query: Point,
        mut best_idx: Int,
        mut best_dist: FType,
    ):
        """Recursive nearest-neighbour search."""
        if node_idx == KDTREE_NONE:
            return
        var node = self.nodes[node_idx]
        var pt = self.points[node.point_idx]
        var d = _dist_sq(query, pt)
        if d < best_dist:
            best_dist = d
            best_idx = node.point_idx

        var diff = _coord(query, node.axis) - _coord(pt, node.axis)
        # Visit the closer side first
        var near_child = node.left if diff <= 0 else node.right
        var far_child  = node.right if diff <= 0 else node.left

        self._nearest_search(near_child, query, best_idx, best_dist)
        # Only visit the far side if the splitting plane is within best distance
        if diff * diff < best_dist:
            self._nearest_search(far_child, query, best_idx, best_dist)

    # ------------------------------------------------------------------
    # k-nearest neighbours
    # ------------------------------------------------------------------

    fn k_nearest(self, query: Point, k: Int) -> List[Point]:
        """Return the k closest points to query (sorted nearest-first)."""
        if self.root == KDTREE_NONE or k <= 0:
            return List[Point]()

        # Max-heap implemented as parallel (dist, idx) lists, size capped at k
        var heap_dist = List[FType]()
        var heap_idx  = List[Int]()

        self._k_nearest_search(self.root, query, k, heap_dist, heap_idx)

        # Sort by distance (ascending) and return points
        var m = len(heap_idx)
        # Simple insertion sort
        for i in range(1, m):
            var ki = heap_idx[i]
            var di = heap_dist[i]
            var j = i - 1
            while j >= 0 and heap_dist[j] > di:
                heap_dist[j + 1] = heap_dist[j]
                heap_idx[j + 1]  = heap_idx[j]
                j -= 1
            heap_dist[j + 1] = di
            heap_idx[j + 1]  = ki

        var result = List[Point]()
        for i in range(m):
            result.append(self.points[heap_idx[i]])
        return result^

    fn _k_nearest_search(
        self,
        node_idx: Int,
        query: Point,
        k: Int,
        mut heap_dist: List[FType],
        mut heap_idx: List[Int],
    ):
        if node_idx == KDTREE_NONE:
            return
        var node = self.nodes[node_idx]
        var pt = self.points[node.point_idx]
        var d = _dist_sq(query, pt)

        # Maintain a max-heap of size k (we store it as an unsorted list and
        # track the max element manually — sufficient for small k)
        var worst: FType = 0.0
        var worst_pos: Int = -1
        var heap_size = len(heap_dist)
        if heap_size > 0:
            worst = heap_dist[0]
            worst_pos = 0
            for i in range(1, heap_size):
                if heap_dist[i] > worst:
                    worst = heap_dist[i]
                    worst_pos = i

        if heap_size < k:
            heap_dist.append(d)
            heap_idx.append(node.point_idx)
        elif d < worst:
            heap_dist[worst_pos] = d
            heap_idx[worst_pos] = node.point_idx

        # Updated worst for pruning
        var prune_dist: FType
        if len(heap_dist) < k:
            prune_dist = FType.MAX_FINITE
        else:
            prune_dist = heap_dist[0]
            for i in range(1, len(heap_dist)):
                if heap_dist[i] > prune_dist:
                    prune_dist = heap_dist[i]

        var diff = _coord(query, node.axis) - _coord(pt, node.axis)
        var near_child = node.left if diff <= 0 else node.right
        var far_child  = node.right if diff <= 0 else node.left

        self._k_nearest_search(near_child, query, k, heap_dist, heap_idx)
        if diff * diff < prune_dist:
            self._k_nearest_search(far_child, query, k, heap_dist, heap_idx)

    # ------------------------------------------------------------------
    # Points within radius
    # ------------------------------------------------------------------

    fn points_in_radius(self, center: Point, radius: Float64) -> List[Point]:
        """Return all points within the given Euclidean radius of center."""
        var result = List[Point]()
        if self.root == KDTREE_NONE:
            return result^
        var radius_sq = radius * radius
        self._radius_search(self.root, center, radius_sq, result)
        return result^

    fn _radius_search(
        self,
        node_idx: Int,
        center: Point,
        radius_sq: FType,
        mut result: List[Point],
    ):
        if node_idx == KDTREE_NONE:
            return
        var node = self.nodes[node_idx]
        var pt = self.points[node.point_idx]
        var d = _dist_sq(center, pt)
        if d <= radius_sq:
            result.append(pt)

        var diff = _coord(center, node.axis) - _coord(pt, node.axis)
        var near_child2 = node.left if diff <= 0 else node.right
        var far_child2  = node.right if diff <= 0 else node.left

        self._radius_search(near_child2, center, radius_sq, result)
        if diff * diff <= radius_sq:
            self._radius_search(far_child2, center, radius_sq, result)
