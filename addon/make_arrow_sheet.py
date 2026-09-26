# Generates Evergreen/arrow.tga: a TomTom-style sprite sheet of a shaded 3D arrow.
# 512x512, 9 columns x 12 rows of 56x42 cells = 108 frames, one per 1/108 turn.
# Frame k is the arrow rotated k * 360/108 degrees counter-clockwise (viewed from above),
# then tilted toward the viewer so it reads as a solid object. Rendered in software here.
# Neutral grey: the addon tints it in-game (green facing the target, red facing away).
import math, struct

W, H = 512, 512
CW, CH = 56, 42
COLS, ROWS = 9, 12
FRAMES = COLS * ROWS
SS = 3  # supersampling per axis

# arrow outline in the XY plane (units), pointing +Y (north). Extruded along Z by THICK.
HEAD = [(0.0, 1.0), (-0.75, 0.05), (-0.28, 0.05), (-0.28, -0.95), (0.28, -0.95), (0.28, 0.05), (0.75, 0.05)]
THICK = 0.55

TOP = (0.95, 0.95, 0.95)
SIDE = (0.42, 0.42, 0.42)
SHADOW = (18, 20, 18)
LIGHT = (-0.55, 0.45, 0.70)   # direction toward the light
TILT = math.radians(-58)      # camera above and behind: top face above the near edges
SCALE = 15.5
SHADOW_OFF = (1.6, 2.4)       # screen px, right and down
SHADOW_ALPHA = 0.55

def norm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1
    return tuple(c / l for c in v)

def rot_z(p, a):
    x, y, z = p
    c, s = math.cos(a), math.sin(a)
    return (x * c - y * s, x * s + y * c, z)

def project(p):
    x, y, z = p
    c, s = math.cos(TILT), math.sin(TILT)
    return (x, y * c - z * s, y * s + z * c)  # screen x, screen y (up), depth toward viewer

def triangulate(poly):
    head = [poly[0], poly[1], poly[6]]
    shaft = [poly[2], poly[3], poly[4], poly[5]]
    return [head, [shaft[0], shaft[1], shaft[2]], [shaft[0], shaft[2], shaft[3]]]

def faces_for(angle):
    faces = []
    top = [rot_z((x, y, THICK / 2), angle) for x, y in HEAD]
    bot = [rot_z((x, y, -THICK / 2), angle) for x, y in HEAD]
    for tri in triangulate(top):
        faces.append((tri, (0, 0, 1), TOP))
    n = len(HEAD)
    for i in range(n):
        a, b = HEAD[i], HEAD[(i + 1) % n]
        dx, dy = b[0] - a[0], b[1] - a[1]
        nrm = rot_z(norm((dy, -dx, 0)), angle)
        quad = [top[i], top[(i + 1) % n], bot[(i + 1) % n], bot[i]]
        faces.append(([quad[0], quad[1], quad[2]], nrm, SIDE))
        faces.append(([quad[0], quad[2], quad[3]], nrm, SIDE))
    return faces

def shade(color, nrm):
    x, y, z = nrm
    c, s = math.cos(TILT), math.sin(TILT)
    n2 = (x, y * c - z * s, y * s + z * c)
    lam = max(0.0, sum(a * b for a, b in zip(norm(n2), norm(LIGHT))))
    k = 0.22 + 0.78 * lam
    return tuple(min(255, int(255 * ch * k)) for ch in color)

def edge(a, b, p):
    return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])

def raster(cell, tris, hi, hj):
    for pts, color in tris:
        minx = max(0, int(min(p[0] for p in pts) * SS) - 1)
        maxx = min(hi - 1, int(max(p[0] for p in pts) * SS) + 1)
        miny = max(0, int(min(p[1] for p in pts) * SS) - 1)
        maxy = min(hj - 1, int(max(p[1] for p in pts) * SS) + 1)
        a, b, c = pts
        if abs(edge(a, b, c)) < 1e-9:
            continue
        for j in range(miny, maxy + 1):
            for i in range(minx, maxx + 1):
                p = ((i + 0.5) / SS, (j + 0.5) / SS)
                w0, w1, w2 = edge(b, c, p), edge(c, a, p), edge(a, b, p)
                if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
                    cell[j][i] = color

def render_frame(angle, buf, ox, oy):
    faces = faces_for(angle)
    proj = []
    for tri, nrm, color in faces:
        pts = [project(p) for p in tri]
        depth = sum(p[2] for p in pts) / 3
        proj.append((depth, pts, shade(color, nrm)))
    proj.sort(key=lambda f: f[0])  # far to near (painter's)
    cx, cy = CW / 2, CH / 2
    hi, hj = CW * SS, CH * SS
    cell = [[None] * hi for _ in range(hj)]

    def screen(pts, offx, offy):
        return [(cx + p[0] * SCALE + offx, cy - p[1] * SCALE * 0.9 + offy) for p in pts]

    # shadow pass, then the arrow
    raster(cell, [(screen(pts, *SHADOW_OFF), SHADOW) for _, pts, _ in proj], hi, hj)
    raster(cell, [(screen(pts, 0, 0), color) for _, pts, color in proj], hi, hj)

    for j in range(CH):
        for i in range(CW):
            r = g = b = 0
            cov = 0
            for sj in range(SS):
                for si in range(SS):
                    px = cell[j * SS + sj][i * SS + si]
                    if px:
                        r += px[0]; g += px[1]; b += px[2]; cov += 1
            if cov:
                a = int(255 * cov / (SS * SS))
                r //= cov; g //= cov; b //= cov
                if (r, g, b) == SHADOW:
                    a = int(a * SHADOW_ALPHA)
                elif cov < SS * SS:  # edge pixel: darken toward outline
                    r = r * 2 // 3; g = g * 2 // 3; b = b * 2 // 3
                buf[oy + j][ox + i] = (r, g, b, a)

buf = [[(0, 0, 0, 0) for _ in range(W)] for _ in range(H)]
for k in range(FRAMES):
    angle = 2 * math.pi * k / FRAMES
    col, row = k % COLS, k // COLS
    render_frame(angle, buf, col * CW, row * CH)

with open("Evergreen/arrow.tga", "wb") as f:
    # canonical bottom-left-origin TGA (descriptor 0x08): rows written bottom to top, so loaders
    # that ignore the origin bit still show the frames upright
    f.write(struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, W, H, 32, 0x08))
    for row in reversed(buf):
        for (r, g, b, a) in row:
            f.write(struct.pack("<BBBB", b, g, r, a))
print("wrote Evergreen/arrow.tga", W, "x", H, FRAMES, "frames")
