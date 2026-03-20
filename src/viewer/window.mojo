from std.python import PythonObject, Python
from .rasterizer import Framebuffer
from .camera import FType


struct SDLWindow(Movable):
    """SDL2 window management via Python interop using sdl_helper.py."""
    var helper: PythonObject
    var width: Int
    var height: Int
    var is_open: Bool

    def __init__(out self, title: String, width: Int, height: Int) raises:
        self.width = width
        self.height = height
        self.is_open = True

        # Add viewer directory to Python path so we can import sdl_helper
        var sys = Python.import_module("sys")
        var os = Python.import_module("os")
        # Try multiple possible locations for the helper module
        var cwd = os.getcwd()
        _ = sys.path.insert(0, os.path.join(cwd, "src", "viewer"))
        _ = sys.path.insert(0, os.path.join(cwd, "viewer"))
        _ = sys.path.insert(0, cwd)

        var sdl_mod = Python.import_module("sdl_helper")
        self.helper = sdl_mod.SDLHelper(title, width, height)

    def __init__(out self, *, deinit take: Self):
        self.helper = take.helper^
        self.width = take.width
        self.height = take.height
        self.is_open = take.is_open

    def update_texture(mut self, fb: Framebuffer) raises:
        """Upload framebuffer pixels to SDL texture and present."""
        var ptr = fb.pixels.unsafe_ptr()
        var addr = Int(ptr)
        var n = self.width * self.height
        self.helper.update_pixels_ptr(addr, n)

    def present_and_poll(mut self, fb: Framebuffer, delay_ms: Int) raises -> PythonObject:
        """Combined upload + present + delay + poll in one Mojo↔Python call."""
        var ptr = fb.pixels.unsafe_ptr()
        var addr = Int(ptr)
        var n = self.width * self.height
        return self.helper.present_and_poll(addr, n, delay_ms)

    def poll_events(mut self) raises -> PythonObject:
        """Poll SDL events. Returns Python list of tuples."""
        return self.helper.poll_events()

    def delay(mut self, ms: Int) raises:
        self.helper.delay(ms)

    def destroy(mut self) raises:
        """Clean up SDL resources."""
        self.is_open = False
        self.helper.destroy()
