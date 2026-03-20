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


def draw_char(mut fb: Framebuffer, cx: Int, cy: Int, ch: String, color: UInt32):
    """Draw a single character at (cx, cy) using a built-in 5x7 bitmap font."""
    # 5x7 font data — each character is 7 rows of 5-bit patterns (MSB left)
    # Space to ~, ASCII 32-126. We store as List[UInt8] per character (7 bytes).
    var code = 0
    if len(ch) > 0:
        code = Int(ord(ch))
    if code < 32 or code > 126:
        return  # unprintable

    # Minimal font: only define the chars we actually need for diagnostics
    # Each row is 5 bits packed into a UInt8 (bits 4..0, left to right)
    var glyph = List[UInt8]()
    for _ in range(7):
        glyph.append(UInt8(0))

    if ch == " ":
        pass  # all zeros
    elif ch == "0":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b10011
        glyph[3] = 0b10101; glyph[4] = 0b11001; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "1":
        glyph[0] = 0b00100; glyph[1] = 0b01100; glyph[2] = 0b00100
        glyph[3] = 0b00100; glyph[4] = 0b00100; glyph[5] = 0b00100; glyph[6] = 0b01110
    elif ch == "2":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b00001
        glyph[3] = 0b00110; glyph[4] = 0b01000; glyph[5] = 0b10000; glyph[6] = 0b11111
    elif ch == "3":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b00001
        glyph[3] = 0b00110; glyph[4] = 0b00001; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "4":
        glyph[0] = 0b00010; glyph[1] = 0b00110; glyph[2] = 0b01010
        glyph[3] = 0b10010; glyph[4] = 0b11111; glyph[5] = 0b00010; glyph[6] = 0b00010
    elif ch == "5":
        glyph[0] = 0b11111; glyph[1] = 0b10000; glyph[2] = 0b11110
        glyph[3] = 0b00001; glyph[4] = 0b00001; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "6":
        glyph[0] = 0b00110; glyph[1] = 0b01000; glyph[2] = 0b10000
        glyph[3] = 0b11110; glyph[4] = 0b10001; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "7":
        glyph[0] = 0b11111; glyph[1] = 0b00001; glyph[2] = 0b00010
        glyph[3] = 0b00100; glyph[4] = 0b01000; glyph[5] = 0b01000; glyph[6] = 0b01000
    elif ch == "8":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b01110; glyph[4] = 0b10001; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "9":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b01111; glyph[4] = 0b00001; glyph[5] = 0b00010; glyph[6] = 0b01100
    elif ch == ".":
        glyph[5] = 0b00000; glyph[6] = 0b00100
    elif ch == ":":
        glyph[2] = 0b00100; glyph[5] = 0b00100
    elif ch == "-":
        glyph[3] = 0b11111
    elif ch == "/":
        glyph[0] = 0b00001; glyph[1] = 0b00010; glyph[2] = 0b00100
        glyph[3] = 0b01000; glyph[4] = 0b10000
    elif ch == "x":
        glyph[2] = 0b10001; glyph[3] = 0b01010; glyph[4] = 0b00100
        glyph[5] = 0b01010; glyph[6] = 0b10001
    elif ch == "|":
        glyph[0] = 0b00100; glyph[1] = 0b00100; glyph[2] = 0b00100
        glyph[3] = 0b00100; glyph[4] = 0b00100; glyph[5] = 0b00100; glyph[6] = 0b00100
    elif ch == "(":
        glyph[0] = 0b00010; glyph[1] = 0b00100; glyph[2] = 0b01000
        glyph[3] = 0b01000; glyph[4] = 0b01000; glyph[5] = 0b00100; glyph[6] = 0b00010
    elif ch == ")":
        glyph[0] = 0b01000; glyph[1] = 0b00100; glyph[2] = 0b00010
        glyph[3] = 0b00010; glyph[4] = 0b00010; glyph[5] = 0b00100; glyph[6] = 0b01000
    elif ch == "A" or ch == "a":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b11111; glyph[4] = 0b10001; glyph[5] = 0b10001; glyph[6] = 0b10001
    elif ch == "C" or ch == "c":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b10000
        glyph[3] = 0b10000; glyph[4] = 0b10000; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "D" or ch == "d":
        glyph[0] = 0b11100; glyph[1] = 0b10010; glyph[2] = 0b10001
        glyph[3] = 0b10001; glyph[4] = 0b10001; glyph[5] = 0b10010; glyph[6] = 0b11100
    elif ch == "E" or ch == "e":
        glyph[0] = 0b11111; glyph[1] = 0b10000; glyph[2] = 0b10000
        glyph[3] = 0b11110; glyph[4] = 0b10000; glyph[5] = 0b10000; glyph[6] = 0b11111
    elif ch == "F" or ch == "f":
        glyph[0] = 0b11111; glyph[1] = 0b10000; glyph[2] = 0b10000
        glyph[3] = 0b11110; glyph[4] = 0b10000; glyph[5] = 0b10000; glyph[6] = 0b10000
    elif ch == "H" or ch == "h":
        glyph[0] = 0b10001; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b11111; glyph[4] = 0b10001; glyph[5] = 0b10001; glyph[6] = 0b10001
    elif ch == "I" or ch == "i":
        glyph[0] = 0b01110; glyph[1] = 0b00100; glyph[2] = 0b00100
        glyph[3] = 0b00100; glyph[4] = 0b00100; glyph[5] = 0b00100; glyph[6] = 0b01110
    elif ch == "M" or ch == "m":
        glyph[0] = 0b10001; glyph[1] = 0b11011; glyph[2] = 0b10101
        glyph[3] = 0b10101; glyph[4] = 0b10001; glyph[5] = 0b10001; glyph[6] = 0b10001
    elif ch == "N" or ch == "n":
        glyph[0] = 0b10001; glyph[1] = 0b11001; glyph[2] = 0b10101
        glyph[3] = 0b10011; glyph[4] = 0b10001; glyph[5] = 0b10001; glyph[6] = 0b10001
    elif ch == "O" or ch == "o":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b10001; glyph[4] = 0b10001; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "P" or ch == "p":
        glyph[0] = 0b11110; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b11110; glyph[4] = 0b10000; glyph[5] = 0b10000; glyph[6] = 0b10000
    elif ch == "R" or ch == "r":
        glyph[0] = 0b11110; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b11110; glyph[4] = 0b10100; glyph[5] = 0b10010; glyph[6] = 0b10001
    elif ch == "S" or ch == "s":
        glyph[0] = 0b01110; glyph[1] = 0b10001; glyph[2] = 0b10000
        glyph[3] = 0b01110; glyph[4] = 0b00001; glyph[5] = 0b10001; glyph[6] = 0b01110
    elif ch == "T" or ch == "t":
        glyph[0] = 0b11111; glyph[1] = 0b00100; glyph[2] = 0b00100
        glyph[3] = 0b00100; glyph[4] = 0b00100; glyph[5] = 0b00100; glyph[6] = 0b00100
    elif ch == "V" or ch == "v":
        glyph[0] = 0b10001; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b10001; glyph[4] = 0b01010; glyph[5] = 0b01010; glyph[6] = 0b00100
    elif ch == "W" or ch == "w":
        glyph[0] = 0b10001; glyph[1] = 0b10001; glyph[2] = 0b10001
        glyph[3] = 0b10101; glyph[4] = 0b10101; glyph[5] = 0b11011; glyph[6] = 0b10001
    elif ch == "Z" or ch == "z":
        glyph[0] = 0b11111; glyph[1] = 0b00001; glyph[2] = 0b00010
        glyph[3] = 0b00100; glyph[4] = 0b01000; glyph[5] = 0b10000; glyph[6] = 0b11111

    for row in range(7):
        for col in range(5):
            if (Int(glyph[row]) >> (4 - col)) & 1 == 1:
                fb.set_pixel_no_depth(cx + col, cy + row, color)


def draw_text(mut fb: Framebuffer, x: Int, y: Int, text: String, color: UInt32):
    """Draw a string at (x, y) using the built-in bitmap font. 6px char width."""
    var cursor_x = x
    for i in range(len(text)):
        draw_char(fb, cursor_x, y, String(text[byte=i]), color)
        cursor_x += 6


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
