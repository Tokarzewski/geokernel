from std.math import cos, sin, sqrt, pi


comptime FType = Float64


struct Camera(Copyable, Movable):
    """Orbit camera using spherical coordinates around a target point."""
    var target_x: FType
    var target_y: FType
    var target_z: FType
    var distance: FType
    var azimuth: FType      # horizontal angle in radians
    var elevation: FType    # vertical angle in radians
    var up_x: FType
    var up_y: FType
    var up_z: FType
    var fov: FType          # field of view in radians
    var near: FType
    var far: FType

    def __init__(out self):
        self.target_x = 0.0
        self.target_y = 0.0
        self.target_z = 0.0
        self.distance = 5.0
        self.azimuth = 0.5      # ~30 degrees
        self.elevation = 0.5    # ~30 degrees
        self.up_x = 0.0
        self.up_y = 0.0
        self.up_z = 1.0
        self.fov = pi / 4.0    # 45 degrees
        self.near = 0.1
        self.far = 1000.0

    def __init__(out self, *, copy: Self):
        self.target_x = copy.target_x
        self.target_y = copy.target_y
        self.target_z = copy.target_z
        self.distance = copy.distance
        self.azimuth = copy.azimuth
        self.elevation = copy.elevation
        self.up_x = copy.up_x
        self.up_y = copy.up_y
        self.up_z = copy.up_z
        self.fov = copy.fov
        self.near = copy.near
        self.far = copy.far

    def __init__(out self, *, deinit take: Self):
        self.target_x = take.target_x
        self.target_y = take.target_y
        self.target_z = take.target_z
        self.distance = take.distance
        self.azimuth = take.azimuth
        self.elevation = take.elevation
        self.up_x = take.up_x
        self.up_y = take.up_y
        self.up_z = take.up_z
        self.fov = take.fov
        self.near = take.near
        self.far = take.far

    def eye_x(self) -> FType:
        return self.target_x + self.distance * cos(self.elevation) * cos(self.azimuth)

    def eye_y(self) -> FType:
        return self.target_y + self.distance * cos(self.elevation) * sin(self.azimuth)

    def eye_z(self) -> FType:
        return self.target_z + self.distance * sin(self.elevation)

    def orbit(mut self, d_azimuth: FType, d_elevation: FType):
        """Rotate the camera around the target."""
        self.azimuth += d_azimuth
        self.elevation += d_elevation
        # Clamp elevation to avoid gimbal lock
        if self.elevation > pi / 2.0 - 0.01:
            self.elevation = pi / 2.0 - 0.01
        if self.elevation < -pi / 2.0 + 0.01:
            self.elevation = -pi / 2.0 + 0.01

    def pan(mut self, dx: FType, dy: FType):
        """Pan the camera target in the screen plane."""
        # Compute right and up vectors in world space
        var right_x = -sin(self.azimuth)
        var right_y = cos(self.azimuth)
        var right_z: FType = 0.0

        var up_x = -sin(self.elevation) * cos(self.azimuth)
        var up_y = -sin(self.elevation) * sin(self.azimuth)
        var up_z = cos(self.elevation)

        var scale = self.distance * 0.002
        self.target_x += (right_x * dx + up_x * dy) * scale
        self.target_y += (right_y * dx + up_y * dy) * scale
        self.target_z += (right_z * dx + up_z * dy) * scale

    def zoom(mut self, delta: FType):
        """Zoom by changing distance to target."""
        self.distance *= 1.0 - delta * 0.1
        if self.distance < 0.1:
            self.distance = 0.1
        if self.distance > 500.0:
            self.distance = 500.0
