from geokernel import AABB


struct BVH(Copyable, Movable, ImplicitlyCopyable):
    """Boundary Volume Hierarchy"""

    var aabbs: List[AABB]

    fn __init__(out self, aabbs: List[AABB]):
        self.aabbs = aabbs
