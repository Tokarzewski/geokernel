"""SDL2 helper for geokernel viewer - called via Mojo Python interop."""
import ctypes
import ctypes.util
import struct


class SDLHelper:
    """Wraps SDL2 via ctypes for easy use from Mojo."""

    def __init__(self, title: str, width: int, height: int):
        self.width = width
        self.height = height

        # Load SDL2
        sdl_path = ctypes.util.find_library("SDL2-2.0") or ctypes.util.find_library("SDL2")
        if sdl_path:
            self.sdl = ctypes.CDLL(sdl_path)
        else:
            # Try common paths
            for path in ["libSDL2-2.0.so.0", "libSDL2-2.0.so", "libSDL2.so"]:
                try:
                    self.sdl = ctypes.CDLL(path)
                    break
                except OSError:
                    continue
            else:
                raise RuntimeError("Cannot find SDL2 library. Install with: sudo apt install libsdl2-dev")

        # SDL_Init(SDL_INIT_VIDEO)
        self.sdl.SDL_Init(0x00000020)

        # Create window
        self.sdl.SDL_CreateWindow.restype = ctypes.c_void_p
        self.window = self.sdl.SDL_CreateWindow(
            title.encode("utf-8"),
            0x2FFF0000,  # SDL_WINDOWPOS_CENTERED
            0x2FFF0000,
            width,
            height,
            0x00000004,  # SDL_WINDOW_SHOWN
        )

        # Create renderer
        self.sdl.SDL_CreateRenderer.restype = ctypes.c_void_p
        self.renderer = self.sdl.SDL_CreateRenderer(
            ctypes.c_void_p(self.window), -1, 0x00000001  # SDL_RENDERER_SOFTWARE
        )

        # Create texture
        self.sdl.SDL_CreateTexture.restype = ctypes.c_void_p
        self.texture = self.sdl.SDL_CreateTexture(
            ctypes.c_void_p(self.renderer),
            372645892,  # SDL_PIXELFORMAT_ARGB8888
            1,          # SDL_TEXTUREACCESS_STREAMING
            width,
            height,
        )

        # Event buffer
        self._event_buf = (ctypes.c_uint8 * 56)()
        self._event_ptr = ctypes.cast(self._event_buf, ctypes.c_void_p)

        # Pixel buffer for updates
        self._pixel_arr = (ctypes.c_uint32 * (width * height))()

    def update_pixels(self, pixel_data: list):
        """Upload pixel data (list of uint32 ARGB) to screen."""
        n = self.width * self.height
        for i in range(n):
            self._pixel_arr[i] = pixel_data[i]

        self.sdl.SDL_UpdateTexture(
            ctypes.c_void_p(self.texture),
            None,
            ctypes.cast(self._pixel_arr, ctypes.c_void_p),
            self.width * 4,
        )
        self.sdl.SDL_RenderClear(ctypes.c_void_p(self.renderer))
        self.sdl.SDL_RenderCopy(
            ctypes.c_void_p(self.renderer),
            ctypes.c_void_p(self.texture),
            None, None,
        )
        self.sdl.SDL_RenderPresent(ctypes.c_void_p(self.renderer))

    def poll_events(self) -> list:
        """Poll SDL events. Returns list of (kind, key, mx, my, wheel_y, button) tuples.

        kind: 0=none, 1=quit, 2=keydown, 3=mousemotion, 4=mousewheel, 5=buttondown, 6=buttonup
        """
        events = []
        while self.sdl.SDL_PollEvent(self._event_ptr):
            raw = bytes(self._event_buf)
            event_type = struct.unpack_from("<I", raw, 0)[0]

            kind = 0
            key = 0
            mx = 0
            my = 0
            wheel_y = 0
            button = 0

            if event_type == 0x100:  # SDL_QUIT
                kind = 1
            elif event_type == 0x300:  # SDL_KEYDOWN
                scancode = struct.unpack_from("<I", raw, 16)[0]
                kind = 2
                key = scancode
            elif event_type == 0x400:  # SDL_MOUSEMOTION
                xrel = struct.unpack_from("<i", raw, 24)[0]
                yrel = struct.unpack_from("<i", raw, 28)[0]
                state = struct.unpack_from("<I", raw, 16)[0]
                kind = 3
                mx = xrel
                my = yrel
                button = state
            elif event_type == 0x401:  # SDL_MOUSEBUTTONDOWN
                btn = struct.unpack_from("<B", raw, 16)[0]
                kind = 5
                button = btn
            elif event_type == 0x402:  # SDL_MOUSEBUTTONUP
                btn = struct.unpack_from("<B", raw, 16)[0]
                kind = 6
                button = btn
            elif event_type == 0x403:  # SDL_MOUSEWHEEL
                wy = struct.unpack_from("<i", raw, 20)[0]
                kind = 4
                wheel_y = wy

            events.append((kind, key, mx, my, wheel_y, button))

        return events

    def delay(self, ms: int):
        self.sdl.SDL_Delay(ms)

    def destroy(self):
        self.sdl.SDL_DestroyTexture(ctypes.c_void_p(self.texture))
        self.sdl.SDL_DestroyRenderer(ctypes.c_void_p(self.renderer))
        self.sdl.SDL_DestroyWindow(ctypes.c_void_p(self.window))
        self.sdl.SDL_Quit()
