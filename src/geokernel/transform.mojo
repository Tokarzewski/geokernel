from geokernel import Matrix4, Quaternion, Vector3


struct Transform(Copyable, Movable, ImplicitlyCopyable):
    var movement: Vector3
    var scale: Vector3
    var rotation: Quaternion

    def __init__(out self, movement: Vector3, scale: Vector3, rotation: Quaternion):
        self.movement = movement
        self.scale = scale
        self.rotation = rotation

    def __init__(out self, matrix4: Matrix4):
        self.movement = matrix4.movement()
        self.scale = matrix4.scale()
        self.rotation = matrix4.rotation()


    def __init__(out self, *, deinit take: Self):
        self.movement = take.movement
        self.scale = take.scale
        self.rotation = take.rotation

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
