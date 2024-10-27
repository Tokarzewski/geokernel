from geokernel import AABB


@value
struct BVH:
    """Boundary Volume Hierarchy"""

    var aabbs: List[AABB]
    var objects: ...
