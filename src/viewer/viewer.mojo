from std.python import PythonObject, Python
from std.time import perf_counter_ns
from geokernel import Shell, Face, Point, FType, import_obj
from geokernel.stl import import_stl_ascii
from .camera import Camera
from .rasterizer import Framebuffer, make_color, draw_text
from .renderer import Renderer
from .window import SDLWindow


def run_viewer(var shell: Shell, title: String = "geokernel viewer",
               width: Int = 800, height: Int = 600,
               watch_path: String = "") raises:
    """Open a window and interactively view a Shell.

    Controls:
      Left mouse drag: orbit
      Right mouse drag: pan
      Mouse wheel: zoom
      W: wireframe mode
      S: shaded mode
      Ctrl+D: toggle diagnostics overlay
      Q / ESC: quit

    If watch_path is set, the file is monitored for changes and
    geometry is reloaded automatically (hot-reload).
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

    # File watching (hot-reload)
    var os_mod = Python.import_module("os")
    var last_mtime: Float64 = 0.0
    var reload_counter = 0
    var reload_interval = 60  # check every 60 frames (~1s)
    if len(watch_path) > 0:
        last_mtime = Float64(py=os_mod.path.getmtime(watch_path))
        print("Watching:", watch_path, "(hot-reload enabled)")

    print("geokernel viewer started")
    print("  Left drag: orbit | Right drag: pan | Wheel: zoom")
    print("  W: wireframe | S: shaded | Ctrl+D: diagnostics | Q/ESC: quit")

    # Initial empty event list
    var builtins = Python.import_module("builtins")
    var py_events = builtins.list()

    while win.is_open:
        var num_events = Int(py=builtins.len(py_events))

        for i in range(num_events):
            var ev = py_events[i]
            # Each event is a tuple: (kind, key, mx, my, wheel_y, button, modifiers)
            var kind = Int(py=ev[0])
            var key = Int(py=ev[1])
            var mx = Int(py=ev[2])
            var my = Int(py=ev[3])
            var wheel_y = Int(py=ev[4])
            var button = Int(py=ev[5])
            var mods = Int(py=ev[6])

            if kind == 1:  # QUIT
                win.is_open = False

            elif kind == 2:  # KEYDOWN
                if key == SDL_SCANCODE_Q or key == SDL_SCANCODE_ESCAPE:
                    win.is_open = False
                elif key == SDL_SCANCODE_W:
                    renderer.set_wireframe()
                elif key == SDL_SCANCODE_S:
                    renderer.set_shaded()
                elif key == SDL_SCANCODE_D and (mods & 1) == 1:  # Ctrl+D
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

        # Hot-reload check
        if len(watch_path) > 0:
            reload_counter += 1
            if reload_counter >= reload_interval:
                reload_counter = 0
                var current_mtime = Float64(py=os_mod.path.getmtime(watch_path))
                if current_mtime != last_mtime:
                    last_mtime = current_mtime
                    print("File changed, reloading:", watch_path)
                    var content = open(watch_path, "r").read()
                    var new_faces: List[Face]
                    if watch_path.endswith(".obj"):
                        new_faces = import_obj(content)
                    elif watch_path.endswith(".stl"):
                        new_faces = import_stl_ascii(content)
                    else:
                        new_faces = List[Face]()
                    if len(new_faces) > 0:
                        shell = Shell(new_faces)
                        num_faces = len(shell.faces)
                        num_verts = 0
                        for fi in range(num_faces):
                            num_verts += shell.faces[fi].num_vertices()
                        print("Reloaded:", num_faces, "faces,", num_verts, "vertices")

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

        # Present frame + poll events in one Python call (minimizes interop overhead)
        py_events = win.present_and_poll(fb, 16)

    win.destroy()
    print("Viewer closed.")
