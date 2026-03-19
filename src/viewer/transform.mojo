from std.math import cos, sin, tan, sqrt, pi
from .camera import Camera, FType


struct Mat4(Copyable, Movable):
    """4x4 matrix stored in row-major order as 16 floats."""
    var m: List[FType]

    def __init__(out self):
        """Identity matrix."""
        self.m = List[FType]()
        for _ in range(16):
            self.m.append(0.0)
        self.m[0] = 1.0
        self.m[5] = 1.0
        self.m[10] = 1.0
        self.m[15] = 1.0

    def __init__(out self, *, copy: Self):
        self.m = copy.m.copy()

    def __init__(out self, *, deinit take: Self):
        self.m = take.m^

    def get(self, row: Int, col: Int) -> FType:
        return self.m[row * 4 + col]

    def set(mut self, row: Int, col: Int, val: FType):
        self.m[row * 4 + col] = val


def mat4_multiply(a: Mat4, b: Mat4) -> Mat4:
    """Multiply two 4x4 matrices."""
    var result = Mat4()
    for i in range(4):
        for j in range(4):
            var s: FType = 0.0
            for k in range(4):
                s += a.get(i, k) * b.get(k, j)
            result.set(i, j, s)
    return result^


def look_at(eye_x: FType, eye_y: FType, eye_z: FType,
            target_x: FType, target_y: FType, target_z: FType,
            up_x: FType, up_y: FType, up_z: FType) -> Mat4:
    """Compute a look-at view matrix."""
    # Forward vector (from eye to target)
    var fx = target_x - eye_x
    var fy = target_y - eye_y
    var fz = target_z - eye_z
    var f_len = sqrt(fx * fx + fy * fy + fz * fz)
    if f_len > 0.0:
        fx /= f_len; fy /= f_len; fz /= f_len

    # Right vector = forward x up
    var rx = fy * up_z - fz * up_y
    var ry = fz * up_x - fx * up_z
    var rz = fx * up_y - fy * up_x
    var r_len = sqrt(rx * rx + ry * ry + rz * rz)
    if r_len > 0.0:
        rx /= r_len; ry /= r_len; rz /= r_len

    # Recompute up = right x forward
    var ux = ry * fz - rz * fy
    var uy = rz * fx - rx * fz
    var uz = rx * fy - ry * fx

    var m = Mat4()
    m.set(0, 0, rx); m.set(0, 1, ry); m.set(0, 2, rz)
    m.set(0, 3, -(rx * eye_x + ry * eye_y + rz * eye_z))
    m.set(1, 0, ux); m.set(1, 1, uy); m.set(1, 2, uz)
    m.set(1, 3, -(ux * eye_x + uy * eye_y + uz * eye_z))
    m.set(2, 0, -fx); m.set(2, 1, -fy); m.set(2, 2, -fz)
    m.set(2, 3, fx * eye_x + fy * eye_y + fz * eye_z)
    m.set(3, 3, 1.0)
    return m^


def perspective(fov: FType, aspect: FType, near: FType, far: FType) -> Mat4:
    """Compute a perspective projection matrix."""
    var f = 1.0 / tan(fov / 2.0)
    var m = Mat4()
    # Zero out identity
    m.set(0, 0, f / aspect)
    m.set(1, 1, f)
    m.set(2, 2, (far + near) / (near - far))
    m.set(2, 3, 2.0 * far * near / (near - far))
    m.set(3, 2, -1.0)
    m.set(3, 3, 0.0)
    return m^


def view_matrix_from_camera(camera: Camera) -> Mat4:
    """Build view matrix from camera state."""
    return look_at(
        camera.eye_x(), camera.eye_y(), camera.eye_z(),
        camera.target_x, camera.target_y, camera.target_z,
        camera.up_x, camera.up_y, camera.up_z,
    )


def projection_matrix_from_camera(camera: Camera, width: Int, height: Int) -> Mat4:
    """Build perspective projection matrix from camera state."""
    var aspect = FType(width) / FType(height) if height > 0 else 1.0
    return perspective(camera.fov, aspect, camera.near, camera.far)


struct ScreenPoint(Copyable, Movable):
    var x: Int
    var y: Int
    var depth: FType

    def __init__(out self, x: Int, y: Int, depth: FType):
        self.x = x
        self.y = y
        self.depth = depth

    def __init__(out self, *, copy: Self):
        self.x = copy.x
        self.y = copy.y
        self.depth = copy.depth

    def __init__(out self, *, deinit take: Self):
        self.x = take.x
        self.y = take.y
        self.depth = take.depth


def project_point(px: FType, py: FType, pz: FType,
                  mvp: Mat4, width: Int, height: Int) -> ScreenPoint:
    """Project a 3D point to screen coordinates using MVP matrix."""
    # Multiply by MVP
    var cx = mvp.get(0, 0) * px + mvp.get(0, 1) * py + mvp.get(0, 2) * pz + mvp.get(0, 3)
    var cy = mvp.get(1, 0) * px + mvp.get(1, 1) * py + mvp.get(1, 2) * pz + mvp.get(1, 3)
    var cz = mvp.get(2, 0) * px + mvp.get(2, 1) * py + mvp.get(2, 2) * pz + mvp.get(2, 3)
    var cw = mvp.get(3, 0) * px + mvp.get(3, 1) * py + mvp.get(3, 2) * pz + mvp.get(3, 3)

    if cw == 0.0:
        return ScreenPoint(0, 0, -1.0)

    # Perspective divide
    var ndx = cx / cw
    var ndy = cy / cw
    var ndz = cz / cw

    # NDC to screen
    var sx = Int((ndx + 1.0) * 0.5 * FType(width))
    var sy = Int((1.0 - ndy) * 0.5 * FType(height))  # flip Y

    return ScreenPoint(sx, sy, ndz)
