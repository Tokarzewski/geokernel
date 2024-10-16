from geokernel import Matrix4, Quaternion, Vector3


@value
struct Transform:
    var movement: Vector3
    var scale: Vector3
    var rotation: Quaternion

    def __init__(inout self, movement: Vector3, scale: Vector3, rotation: Quaternion):
        self.movement = movement
        self.scale = scale
        self.rotation = rotation

    def __init__(inout self, matrix4: Matrix4):
        self.movement = matrix4.movement()
        self.scale = matrix4.scale()
        self.rotation = matrix4.rotation()

    def inverse(self) -> Self:
        movement = self.movement.reverse()
        scale = self.scale.inverse()
        rotation = self.rotation.inverse()
        return Self(movement, scale, rotation)

    def combine(self, other: Self) -> Self:
        movement = self.movement + other.movement
        scale = self.scale + other.scale
        rotation = self.rotation * other.rotation
        return Self(movement, scale, rotation)

    # fn matrix4(self) -> Matrix4:
    #    return Matrix4()
