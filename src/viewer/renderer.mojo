from std.math import sqrt
from geokernel import Point, Face, Shell, Vector3, FType
from .camera import Camera
from .transform import Mat4, mat4_multiply, view_matrix_from_camera, projection_matrix_from_camera, project_point, ScreenPoint
from .rasterizer import Framebuffer, draw_line, fill_triangle, make_color


struct RenderMode(Copyable, Movable, ImplicitlyCopyable):
    """Render mode: wireframe or shaded."""
    var value: Int

    def __init__(out self, value: Int):
        self.value = value

    def __init__(out self, *, copy: Self):
        self.value = copy.value

    def __init__(out self, *, deinit take: Self):
        self.value = take.value


def wireframe_mode() -> RenderMode:
    return RenderMode(0)


def shaded_mode() -> RenderMode:
    return RenderMode(1)


struct Renderer(Copyable, Movable):
    """High-level renderer that takes Shell/faces and renders them."""
    var mode: RenderMode
    var light_x: FType
    var light_y: FType
    var light_z: FType
    var ambient: FType

    def __init__(out self):
        self.mode = wireframe_mode()
        # Directional light from upper-right
        var lx: FType = 1.0
        var ly: FType = 0.5
        var lz: FType = 1.0
        var ll = sqrt(lx * lx + ly * ly + lz * lz)
        self.light_x = lx / ll
        self.light_y = ly / ll
        self.light_z = lz / ll
        self.ambient = 0.2

    def __init__(out self, *, copy: Self):
        self.mode = copy.mode
        self.light_x = copy.light_x
        self.light_y = copy.light_y
        self.light_z = copy.light_z
        self.ambient = copy.ambient

    def __init__(out self, *, deinit take: Self):
        self.mode = take.mode^
        self.light_x = take.light_x
        self.light_y = take.light_y
        self.light_z = take.light_z
        self.ambient = take.ambient

    def set_wireframe(mut self):
        self.mode = wireframe_mode()

    def set_shaded(mut self):
        self.mode = shaded_mode()

    def toggle_mode(mut self):
        if self.mode.value == 0:
            self.mode = shaded_mode()
        else:
            self.mode = wireframe_mode()

    def render_shell(self, shell: Shell, camera: Camera, mut fb: Framebuffer):
        """Render all faces of a shell."""
        var width = fb.width
        var height = fb.height

        var view = view_matrix_from_camera(camera)
        var proj = projection_matrix_from_camera(camera, width, height)
        var mvp = mat4_multiply(proj, view)

        # Camera forward direction for back-face culling
        var cam_fx = camera.target_x - camera.eye_x()
        var cam_fy = camera.target_y - camera.eye_y()
        var cam_fz = camera.target_z - camera.eye_z()
        var cam_fl = sqrt(cam_fx * cam_fx + cam_fy * cam_fy + cam_fz * cam_fz)
        if cam_fl > 0.0:
            cam_fx /= cam_fl; cam_fy /= cam_fl; cam_fz /= cam_fl

        for fi in range(len(shell.faces)):
            var face = shell.faces[fi]

            if face.num_vertices() < 3:
                continue

            # Compute face normal
            var normal = face.normal()
            var nx = normal.x
            var ny = normal.y
            var nz = normal.z

            # Back-face culling (for shaded mode)
            if self.mode.value == 1:
                var dot = nx * cam_fx + ny * cam_fy + nz * cam_fz
                if dot < 0.0:
                    continue

            if self.mode.value == 0:
                self._render_face_wireframe(face, mvp, width, height, fb)
            else:
                self._render_face_shaded(face, nx, ny, nz, mvp, width, height, fb)

    def _render_face_wireframe(self, face: Face, mvp: Mat4, width: Int, height: Int, mut fb: Framebuffer):
        """Draw face edges as white lines."""
        var white = make_color(255, 255, 255)
        var n_edges = face.num_edges()
        for i in range(n_edges):
            var p1 = face.get_vertex(i)
            var p2 = face.get_vertex((i + 1) % face.num_vertices())
            var s1 = project_point(p1.x, p1.y, p1.z, mvp, width, height)
            var s2 = project_point(p2.x, p2.y, p2.z, mvp, width, height)
            # Clip: skip if both behind camera
            if s1.depth < -1.0 and s2.depth < -1.0:
                continue
            draw_line(fb, s1.x, s1.y, s2.x, s2.y, white)

    def _render_face_shaded(self, face: Face, nx: FType, ny: FType, nz: FType,
                            mvp: Mat4, width: Int, height: Int, mut fb: Framebuffer):
        """Flat-shade face with directional light + ambient."""
        # Compute lighting intensity
        var dot = nx * self.light_x + ny * self.light_y + nz * self.light_z
        if dot < 0.0:
            dot = 0.0
        var intensity = self.ambient + (1.0 - self.ambient) * dot

        # Light blue base color
        var base_r: FType = 120.0
        var base_g: FType = 180.0
        var base_b: FType = 230.0

        var r = Int(base_r * intensity)
        var g = Int(base_g * intensity)
        var b = Int(base_b * intensity)
        if r > 255: r = 255
        if g > 255: g = 255
        if b > 255: b = 255

        var color = make_color(r, g, b)

        # Triangulate and rasterize
        var triangles = face.triangulate()
        for ti in range(len(triangles)):
            var tri = triangles[ti]
            var p0 = tri.get_vertex(0)
            var p1 = tri.get_vertex(1)
            var p2 = tri.get_vertex(2)

            var s0 = project_point(p0.x, p0.y, p0.z, mvp, width, height)
            var s1 = project_point(p1.x, p1.y, p1.z, mvp, width, height)
            var s2 = project_point(p2.x, p2.y, p2.z, mvp, width, height)

            # Skip triangles behind camera
            if s0.depth < -1.0 and s1.depth < -1.0 and s2.depth < -1.0:
                continue

            fill_triangle(fb, s0.x, s0.y, s0.depth,
                         s1.x, s1.y, s1.depth,
                         s2.x, s2.y, s2.depth, color)

    def render_faces(self, faces: List[Face], camera: Camera, mut fb: Framebuffer):
        """Render a list of faces (convenience wrapper)."""
        var shell = Shell(faces)
        self.render_shell(shell, camera, fb)
