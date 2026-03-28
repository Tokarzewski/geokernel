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
        """Combine two transforms: apply self first, then other.
        Scales multiply component-wise. Movement applies rotation and scale
        of the first transform to the second's translation."""
        var new_scale = Vector3(
            self.scale.x * other.scale.x,
            self.scale.y * other.scale.y,
            self.scale.z * other.scale.z,
        )
        var rotated_other_movement = self.rotation.rotate_vector(other.movement)
        var scaled_movement = Vector3(
            rotated_other_movement.x * self.scale.x,
            rotated_other_movement.y * self.scale.y,
            rotated_other_movement.z * self.scale.z,
        )
        var new_movement = self.movement + scaled_movement
        var new_rotation = self.rotation * other.rotation
        return Self(new_movement, new_scale, new_rotation)

    # fn matrix4(self) -> Matrix4:
    #    return Matrix4()
