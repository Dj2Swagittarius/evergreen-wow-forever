# Generates Evergreen/arrow.tga: 64x64 32-bit TGA, white arrow pointing up with alpha, dark outline.
import struct, math
W = H = 64
px = [[(0,0,0,0) for _ in range(W)] for _ in range(H)]

def inside_arrow(x, y):
    # coordinates in 0..1, y down. Arrow head: triangle from (0.5,0.06) to (0.12,0.52)/(0.88,0.52). Shaft: 0.36..0.64 wide, y 0.50..0.94
    if y < 0.06: return False
    if y <= 0.52:
        half = (y - 0.06) / (0.52 - 0.06) * 0.38
        return abs(x - 0.5) <= half
    if y <= 0.94:
        return abs(x - 0.5) <= 0.14
    return False

def sample(x, y):
    # 4x4 supersampling for smooth edges
    hits = 0
    for i in range(4):
        for j in range(4):
            if inside_arrow(x + (i + 0.5) / 4 / W, y + (j + 0.5) / 4 / H): hits += 1
    return hits / 16.0

for yi in range(H):
    for xi in range(W):
        x, y = xi / W, yi / H
        a = sample(x, y)
        # outline: sample a slightly dilated shape
        o = 0
        for dx, dy in ((-1.5,0),(1.5,0),(0,-1.5),(0,1.5),(-1,-1),(1,-1),(-1,1),(1,1)):
            o = max(o, sample(x + dx / W, y + dy / H))
        if a > 0:
            v = int(255 * a)
            px[yi][xi] = (255, 255, 255, v)       # vertex color tints this
        elif o > 0:
            px[yi][xi] = (10, 12, 10, int(200 * o))

with open("Evergreen/arrow.tga", "wb") as f:
    f.write(struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, W, H, 32, 0x28))  # top-left origin, 8 alpha bits
    for row in px:
        for (r, g, b, a) in row:
            f.write(struct.pack("<BBBB", b, g, r, a))
print("ok")
