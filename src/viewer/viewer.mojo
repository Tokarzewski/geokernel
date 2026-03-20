from std.python import PythonObject, Python
from std.time import perf_counter_ns
from geokernel import Shell, Face, Point, FType
from .camera import Camera
from .rasterizer import Framebuffer, make_color, draw_text
from .renderer import Renderer
from .window import SDLWindow


def run_viewer(shell: Shell, title: String = "geokernel viewer",
               width: Int = 800, height: Int = 600) raises:
    """Open a window and interactively view a Shell.

    Controls:
      Left mouse drag: orbit
      Right mouse drag: pan
      Mouse wheel: zoom
      W: wireframe mode
      S: shaded mode
      Q / ESC: quit
    """
    # Compute bounding box center for initial camera target
    var min_x: FType = 1e30
    var min_y: FType = 1e30
    var min_z: FType = 1e30
    var max_x: FType = -1e30
    var max_y: FType = -1e30
    var max_z: FType = -1e30

    for fi in range(len(shell.faces)):
        var face = shell.faces[fi]
        for pi in range(face.num_vertices()):
            var p = face.get_vertex(pi)
            if p.x < min_x:
                min_x = p.x
            if p.y < min_y:
                min_y = p.y
            if p.z < min_z:
                min_z = p.z
            if p.x > max_x:
                max_x = p.x
            if p.y > max_y:
                max_y = p.y
            if p.z > max_z:
                max_z = p.z

    var cx = (min_x + max_x) / 2.0
    var cy = (min_y + max_y) / 2.0
    var cz = (min_z + max_z) / 2.0
    var ddx = max_x - min_x
    var ddy = max_y - min_y
    var ddz = max_z - min_z
    var extent = ddx
    if ddy > extent:
        extent = ddy
    if ddz > extent:
        extent = ddz
    if extent < 0.01:
        extent = 1.0

    var camera = Camera()
    camera.target_x = cx
    camera.target_y = cy
    camera.target_z = cz
    camera.distance = extent * 2.5

    var renderer = Renderer()
    renderer.set_shaded()

    var fb = Framebuffer(width, height)
    var win = SDLWindow(title, width, height)

    # SDL scancodes
    var SDL_SCANCODE_D = 7
    var SDL_SCANCODE_Q = 20
    var SDL_SCANCODE_W = 26
    var SDL_SCANCODE_S = 22
    var SDL_SCANCODE_ESCAPE = 41

    # Mouse button state tracking
    var left_button_down = False
    var right_button_down = False

    # Diagnostics
    var show_diag = False
    var frame_count = 0
    var fps_display: FType = 0.0
    var fps_timer = perf_counter_ns()
    var render_ms = FType(0)
    var num_faces = len(shell.faces)
    var num_verts = 0
    for fi in range(num_faces):
        num_verts += shell.faces[fi].num_vertices()

    print("geokernel viewer started")
    print("  Left drag: orbit | Right drag: pan | Wheel: zoom")
    print("  W: wireframe | S: shaded | D: diagnostics | Q/ESC: quit")

    while win.is_open:
        # Poll events via Python helper
        var py_events = win.poll_events()
        var builtins = Python.import_module("builtins")
        var num_events = Int(py=builtins.len(py_events))

        for i in range(num_events):
            var ev = py_events[i]
            # Each event is a tuple: (kind, key, mx, my, wheel_y, button)
            var kind = Int(py=ev[0])
            var key = Int(py=ev[1])
            var mx = Int(py=ev[2])
            var my = Int(py=ev[3])
            var wheel_y = Int(py=ev[4])
            var button = Int(py=ev[5])

            if kind == 1:  # QUIT
                win.is_open = False

            elif kind == 2:  # KEYDOWN
                if key == SDL_SCANCODE_Q or key == SDL_SCANCODE_ESCAPE:
                    win.is_open = False
                elif key == SDL_SCANCODE_W:
                    renderer.set_wireframe()
                elif key == SDL_SCANCODE_S:
                    renderer.set_shaded()
                elif key == SDL_SCANCODE_D:
                    show_diag = not show_diag

            elif kind == 5:  # MOUSEBUTTONDOWN
                if button == 1:
                    left_button_down = True
                elif button == 3:
                    right_button_down = True

            elif kind == 6:  # MOUSEBUTTONUP
                if button == 1:
                    left_button_down = False
                elif button == 3:
                    right_button_down = False

            elif kind == 3:  # MOUSEMOTION
                if left_button_down:
                    camera.orbit(FType(mx) * -0.01, FType(my) * 0.01)
                elif right_button_down:
                    camera.pan(FType(mx), FType(my))

            elif kind == 4:  # MOUSEWHEEL
                camera.zoom(FType(wheel_y))

        # Render
        fb.clear()
        var t_render_start = perf_counter_ns()
        renderer.render_shell(shell, camera, fb)
        var t_render_end = perf_counter_ns()
        render_ms = FType(t_render_end - t_render_start) / 1e6

        # FPS counter (update every 30 frames)
        frame_count += 1
        if frame_count >= 30:
            var now = perf_counter_ns()
            var elapsed = FType(now - fps_timer) / 1e9
            if elapsed > 0.0:
                fps_display = FType(frame_count) / elapsed
            fps_timer = now
            frame_count = 0

        # Diagnostics overlay
        if show_diag:
            var diag_color = make_color(0, 255, 0)  # green text

            # Semi-transparent background strip
            for py in range(2, 72):
                for px in range(2, 200):
                    fb.set_pixel_no_depth(px, py, UInt32(0xFF101010))

            # FPS
            var fps_int = Int(fps_display)
            draw_text(fb, 6, 5, "FPS: " + String(fps_int), diag_color)

            # Render time
            var ms_int = Int(render_ms * 100.0)
            var ms_str = String(ms_int / 100) + "." + String(ms_int % 100)
            draw_text(fb, 6, 15, "Render: " + ms_str + " ms", diag_color)

            # Mode
            var mode_str = "wireframe" if renderer.mode.value == 0 else "shaded"
            draw_text(fb, 6, 25, "Mode: " + mode_str, diag_color)

            # Geometry stats
            draw_text(fb, 6, 35, "Faces: " + String(num_faces), diag_color)
            draw_text(fb, 6, 45, "Verts: " + String(num_verts), diag_color)

            # Resolution
            draw_text(fb, 6, 55, String(width) + "x" + String(height), diag_color)

        win.update_texture(fb)

        # ~60fps cap
        win.delay(16)

    win.destroy()
    print("Viewer closed.")
