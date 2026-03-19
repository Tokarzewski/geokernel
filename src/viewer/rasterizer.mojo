from std.math import sqrt, abs
from .camera import FType


struct Framebuffer(Copyable, Movable):
    """CPU framebuffer with ARGB pixel buffer and Z-buffer."""
    var width: Int
    var height: Int
    var pixels: List[UInt32]
    var zbuffer: List[FType]

    def __init__(out self, width: Int, height: Int):
        self.width = width
        self.height = height
        self.pixels = List[UInt32]()
        self.zbuffer = List[FType]()
        var size = width * height
        for _ in range(size):
            self.pixels.append(UInt32(0xFF000000))  # black, opaque
            self.zbuffer.append(1e30)

    def __init__(out self, *, copy: Self):
        self.width = copy.width
        self.height = copy.height
        self.pixels = copy.pixels.copy()
        self.zbuffer = copy.zbuffer.copy()

    def __init__(out self, *, deinit take: Self):
        self.width = take.width
        self.height = take.height
        self.pixels = take.pixels^
        self.zbuffer = take.zbuffer^

    def clear(mut self):
        """Clear to black with infinite depth."""
        for i in range(self.width * self.height):
            self.pixels[i] = UInt32(0xFF000000)
            self.zbuffer[i] = 1e30

    def set_pixel(mut self, x: Int, y: Int, z: FType, color: UInt32):
        """Set pixel with Z-buffer test."""
        if x < 0 or x >= self.width or y < 0 or y >= self.height:
            return
        var idx = y * self.width + x
        if z < self.zbuffer[idx]:
            self.zbuffer[idx] = z
            self.pixels[idx] = color

    def set_pixel_no_depth(mut self, x: Int, y: Int, color: UInt32):
        """Set pixel without depth test (for wireframe)."""
        if x < 0 or x >= self.width or y < 0 or y >= self.height:
            return
        var idx = y * self.width + x
        self.pixels[idx] = color


def make_color(r: Int, g: Int, b: Int) -> UInt32:
    """Create ARGB color from RGB components (0-255)."""
    return UInt32(0xFF000000) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)


def draw_line(mut fb: Framebuffer, x0: Int, y0: Int, x1: Int, y1: Int, color: UInt32):
    """Bresenham's line algorithm."""
    var dx = x1 - x0
    var dy = y1 - y0
    var abs_dx = dx if dx >= 0 else -dx
    var abs_dy = dy if dy >= 0 else -dy
    var sx = 1 if x0 < x1 else -1
    var sy = 1 if y0 < y1 else -1
    var err = abs_dx - abs_dy
    var cx = x0
    var cy = y0

    while True:
        fb.set_pixel_no_depth(cx, cy, color)
        if cx == x1 and cy == y1:
            break
        var e2 = 2 * err
        if e2 > -abs_dy:
            err -= abs_dy
            cx += sx
        if e2 < abs_dx:
            err += abs_dx
            cy += sy


def fill_triangle(mut fb: Framebuffer,
                  x0: Int, y0: Int, z0: FType,
                  x1: Int, y1: Int, z1: FType,
                  x2: Int, y2: Int, z2: FType,
                  color: UInt32):
    """Rasterize a filled triangle with Z-buffer using scanline."""
    # Bounding box
    var min_x = x0
    if x1 < min_x: min_x = x1
    if x2 < min_x: min_x = x2
    var max_x = x0
    if x1 > max_x: max_x = x1
    if x2 > max_x: max_x = x2
    var min_y = y0
    if y1 < min_y: min_y = y1
    if y2 < min_y: min_y = y2
    var max_y = y0
    if y1 > max_y: max_y = y1
    if y2 > max_y: max_y = y2

    # Clip to framebuffer
    if min_x < 0: min_x = 0
    if min_y < 0: min_y = 0
    if max_x >= fb.width: max_x = fb.width - 1
    if max_y >= fb.height: max_y = fb.height - 1

    # Barycentric rasterization
    var denom = FType((y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2))
    if denom == 0.0:
        return

    var inv_denom = 1.0 / denom

    for py in range(min_y, max_y + 1):
        for px in range(min_x, max_x + 1):
            var w0 = FType((y1 - y2) * (px - x2) + (x2 - x1) * (py - y2)) * inv_denom
            var w1 = FType((y2 - y0) * (px - x2) + (x0 - x2) * (py - y2)) * inv_denom
            var w2 = 1.0 - w0 - w1

            if w0 >= 0.0 and w1 >= 0.0 and w2 >= 0.0:
                var z = w0 * z0 + w1 * z1 + w2 * z2
                fb.set_pixel(px, py, z, color)
