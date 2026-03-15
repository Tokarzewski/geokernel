from geokernel import AABB, Point


struct BVHNode(Copyable, Movable, ImplicitlyCopyable):
    """A node in the BVH tree."""

    var aabb: AABB
    var left: Int   # index into BVH.nodes, -1 if leaf
    var right: Int  # index into BVH.nodes, -1 if leaf
    var leaf_index: Int  # index into original aabbs list, -1 if internal node

    fn __init__(out self, aabb: AABB, left: Int, right: Int, leaf_index: Int):
        self.aabb = aabb
        self.left = left
        self.right = right
        self.leaf_index = leaf_index

    fn __copyinit__(out self, copy: Self):
        self.aabb = copy.aabb
        self.left = copy.left
        self.right = copy.right
        self.leaf_index = copy.leaf_index

    fn __moveinit__(out self, deinit take: Self):
        self.aabb = take.aabb
        self.left = take.left
        self.right = take.right
        self.leaf_index = take.leaf_index

    fn is_leaf(self) -> Bool:
        return self.leaf_index != -1


struct BVH(Copyable, Movable, ImplicitlyCopyable):
    """Boundary Volume Hierarchy for fast spatial queries."""

    var nodes: List[BVHNode]

    fn __init__(out self, aabbs: List[AABB]):
        self.nodes = List[BVHNode]()
        if len(aabbs) == 0:
            return
        var indices = List[Int]()
        for i in range(len(aabbs)):
            indices.append(i)
        _ = self._build(aabbs, indices)

    fn __copyinit__(out self, copy: Self):
        self.nodes = copy.nodes.copy()

    fn __moveinit__(out self, deinit take: Self):
        self.nodes = take.nodes^

    fn _compute_union_aabb(self, aabbs: List[AABB], indices: List[Int]) -> AABB:
        var combined = aabbs[indices[0]]
        for i in range(1, len(indices)):
            var b = aabbs[indices[i]]
            combined.p_min = Point.min(combined.p_min, b.p_min)
            combined.p_max = Point.max(combined.p_max, b.p_max)
        return combined

    fn _build(mut self, aabbs: List[AABB], indices: List[Int]) -> Int:
        """Recursively build BVH. Returns node index."""
        var node_aabb = self._compute_union_aabb(aabbs, indices)

        # Leaf node
        if len(indices) == 1:
            var node = BVHNode(node_aabb, -1, -1, indices[0])
            self.nodes.append(node)
            return len(self.nodes) - 1

        # Find longest axis of the combined AABB
        var dx = node_aabb.p_max.x - node_aabb.p_min.x
        var dy = node_aabb.p_max.y - node_aabb.p_min.y
        var dz = node_aabb.p_max.z - node_aabb.p_min.z

        var axis: Int = 0
        if dy >= dx and dy >= dz:
            axis = 1
        elif dz >= dx and dz >= dy:
            axis = 2

        # Midpoint on longest axis
        var mid: Float64 = 0.0
        if axis == 0:
            mid = (node_aabb.p_min.x + node_aabb.p_max.x) * 0.5
        elif axis == 1:
            mid = (node_aabb.p_min.y + node_aabb.p_max.y) * 0.5
        else:
            mid = (node_aabb.p_min.z + node_aabb.p_max.z) * 0.5

        # Split indices by centroid on the chosen axis
        var left_indices = List[Int]()
        var right_indices = List[Int]()

        for i in range(len(indices)):
            var idx = indices[i]
            var b = aabbs[idx]
            var centroid: Float64 = 0.0
            if axis == 0:
                centroid = (b.p_min.x + b.p_max.x) * 0.5
            elif axis == 1:
                centroid = (b.p_min.y + b.p_max.y) * 0.5
            else:
                centroid = (b.p_min.z + b.p_max.z) * 0.5

            if centroid < mid:
                left_indices.append(idx)
            else:
                right_indices.append(idx)

        # Avoid degenerate splits: if all items end up on one side, split evenly
        if len(left_indices) == 0 or len(right_indices) == 0:
            left_indices = List[Int]()
            right_indices = List[Int]()
            var half = len(indices) // 2
            for i in range(len(indices)):
                if i < half:
                    left_indices.append(indices[i])
                else:
                    right_indices.append(indices[i])

        var left_idx = self._build(aabbs, left_indices)
        var right_idx = self._build(aabbs, right_indices)

        var node = BVHNode(node_aabb, left_idx, right_idx, -1)
        self.nodes.append(node)
        return len(self.nodes) - 1

    fn query_point(self, p: Point) -> List[Int]:
        """Return indices of original AABBs that contain the point."""
        var result = List[Int]()
        if len(self.nodes) == 0:
            return result^

        var root = len(self.nodes) - 1
        var stack = List[Int]()
        stack.append(root)

        while len(stack) > 0:
            var node_idx = stack[len(stack) - 1]
            stack.resize(len(stack) - 1, 0)
            var node = self.nodes[node_idx]

            if not node.aabb.contains(p):
                continue

            if node.is_leaf():
                result.append(node.leaf_index)
            else:
                if node.left != -1:
                    stack.append(node.left)
                if node.right != -1:
                    stack.append(node.right)

        return result^

    fn _aabbs_overlap(self, a: AABB, b: AABB) -> Bool:
        """Check if two AABBs overlap."""
        return (
            a.p_min.x <= b.p_max.x and a.p_max.x >= b.p_min.x and
            a.p_min.y <= b.p_max.y and a.p_max.y >= b.p_min.y and
            a.p_min.z <= b.p_max.z and a.p_max.z >= b.p_min.z
        )

    fn query_aabb(self, q: AABB) -> List[Int]:
        """Return indices of original AABBs that overlap with q."""
        var result = List[Int]()
        if len(self.nodes) == 0:
            return result^

        var root = len(self.nodes) - 1
        var stack = List[Int]()
        stack.append(root)

        while len(stack) > 0:
            var node_idx = stack[len(stack) - 1]
            stack.resize(len(stack) - 1, 0)
            var node = self.nodes[node_idx]

            if not self._aabbs_overlap(node.aabb, q):
                continue

            if node.is_leaf():
                result.append(node.leaf_index)
            else:
                if node.left != -1:
                    stack.append(node.left)
                if node.right != -1:
                    stack.append(node.right)

        return result^
