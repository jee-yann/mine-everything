"""Shared helpers for the ore theme boards: noise, isometric cubes, layout."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

N = 320  # face texture size
SS = 2  # supersampling
LIGHT = np.array([-0.55, -0.83])
LIGHT = LIGHT / np.linalg.norm(LIGHT)

FONT_DIR = "/System/Library/Fonts/"


def font(size, weight="bold"):
    idx = {"regular": 0, "bold": 1, "heavy": 8, "demi": 2, "medium": 5}.get(weight, 1)
    try:
        return ImageFont.truetype(FONT_DIR + "Avenir Next.ttc", size * SS, index=idx)
    except Exception:
        return ImageFont.truetype(FONT_DIR + "Helvetica.ttc", size * SS)


def hexrgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)])


def to255(c):
    c = np.clip(np.asarray(c), 0, 1)
    return tuple(int(round(x * 255)) for x in c)


def lerp(a, b, t):
    return a + (b - a) * t


def pal_at(pal, t):
    cols = [hexrgb(p) if isinstance(p, str) else np.asarray(p) for p in pal]
    t = float(np.clip(t, 0, 1)) * (len(cols) - 1)
    i = min(int(t), len(cols) - 2)
    return lerp(cols[i], cols[i + 1], t - i)


# ---------- noise ----------
def value_noise(n, cells, rng):
    g = rng.random((cells, cells))
    x = np.linspace(0, cells, n, endpoint=False)
    xi = np.floor(x).astype(int)
    xf = x - xi
    xf = xf * xf * (3 - 2 * xf)
    x0, x1 = xi % cells, (xi + 1) % cells
    a, b = g[np.ix_(x0, x0)], g[np.ix_(x0, x1)]
    c, d = g[np.ix_(x1, x0)], g[np.ix_(x1, x1)]
    fy, fx = xf[:, None], xf[None, :]
    return a * (1 - fx) * (1 - fy) + b * fx * (1 - fy) + c * (1 - fx) * fy + d * fx * fy


def fbm(n, base, octaves, rng, persistence=0.5):
    total, amp, norm = 0, 1.0, 0
    for o in range(octaves):
        total = total + amp * value_noise(n, base * 2**o, rng)
        norm += amp
        amp *= persistence
    return total / norm


def ridged(n, base, octaves, rng):
    return 1 - np.abs(fbm(n, base, octaves, rng) * 2 - 1)


def grid(n=N):
    y, x = np.mgrid[0:n, 0:n] / n
    return x, y


def emboss(height, strength=1.0):
    gy, gx = np.gradient(height)
    s = -(gx * LIGHT[0] + gy * LIGHT[1]) * strength * N
    return 1 + s


def voronoi(n, pts):
    x, y = grid(n)
    best = np.full((n, n), 9.0)
    second = np.full((n, n), 9.0)
    idx = np.zeros((n, n), int)
    for i, (px, py) in enumerate(pts):
        dx = np.abs(x - px)
        dy = np.abs(y - py)
        dx = np.minimum(dx, 1 - dx)
        dy = np.minimum(dy, 1 - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < best
        second = np.where(closer, best, np.minimum(second, d))
        idx = np.where(closer, i, idx)
        best = np.where(closer, d, best)
    return best, second, idx


# ---------- texture drawing (PIL, texture space) ----------
class Tex:
    """An RGB face texture plus an emissive layer, drawable with PIL."""

    def __init__(self, base, n=N):
        self.n = n
        if isinstance(base, np.ndarray) and base.ndim == 3:
            self.img = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8), "RGB")
        else:
            self.img = Image.new("RGB", (n, n), to255(base))
        self.em = Image.new("RGB", (n, n), (0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.e = ImageDraw.Draw(self.em)

    def P(self, pts):
        return [(float(x) * self.n, float(y) * self.n) for x, y in pts]

    def poly(self, pts, fill, outline=None, width=0, glow=None):
        self.d.polygon(self.P(pts), fill=to255(fill), outline=to255(outline) if outline is not None else None, width=width)
        if glow is not None:
            self.e.polygon(self.P(pts), fill=to255(glow))

    def line(self, pts, fill, width, glow=None, joint="curve"):
        self.d.line(self.P(pts), fill=to255(fill), width=int(width * self.n), joint=joint)
        if glow is not None:
            self.e.line(self.P(pts), fill=to255(glow), width=int(width * self.n * 1.6), joint=joint)

    def ellipse(self, c, r, fill, outline=None, width=0, glow=None):
        rx, ry = (r, r) if np.isscalar(r) else r
        box = [(c[0] - rx) * self.n, (c[1] - ry) * self.n, (c[0] + rx) * self.n, (c[1] + ry) * self.n]
        self.d.ellipse(box, fill=to255(fill) if fill is not None else None, outline=to255(outline) if outline is not None else None, width=width)
        if glow is not None:
            self.e.ellipse(box, fill=to255(glow))

    def facets(self, pts, pal, lift=0.35, jitter=0.06, rng=None, lo=0.12, hi=0.95, outline=None, width=0, glow=None):
        """Low-poly dome: fan of triangles from an apex nudged toward the light."""
        pts = np.asarray(pts, float)
        c = pts.mean(0)
        r = np.mean(np.linalg.norm(pts - c, axis=1))
        apex = c + LIGHT * lift * r
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            m = (a + b) / 2 - apex
            nrm = m / (np.linalg.norm(m) + 1e-9)
            t = 0.5 + 0.5 * float(np.dot(nrm, LIGHT))
            if rng is not None:
                t += rng.uniform(-jitter, jitter)
            self.poly([apex, a, b], pal_at(pal, lo + (hi - lo) * t), outline=outline, width=width, glow=glow)

    def sparkle(self, c, r, fill="FFFFFF", glow=None, outline=None, width=0):
        pts = []
        for i in range(8):
            ang = i * math.pi / 4 - math.pi / 2
            rr = r if i % 2 == 0 else r * 0.22
            pts.append((c[0] + rr * math.cos(ang), c[1] + rr * math.sin(ang)))
        self.poly(pts, hexrgb(fill) if isinstance(fill, str) else fill, outline=outline, width=width, glow=glow)

    def arrays(self):
        return np.asarray(self.img, float) / 255, np.asarray(self.em, float) / 255


def blob(c, r, k, rng, jitter=0.25, rot=0.0, aspect=1.0):
    pts = []
    for i in range(k):
        ang = rot + 2 * math.pi * i / k + rng.uniform(-0.25, 0.25) * (2 * math.pi / k)
        rr = r * (1 + rng.uniform(-jitter, jitter))
        pts.append((c[0] + rr * math.cos(ang) * aspect, c[1] + rr * math.sin(ang)))
    return pts


def chiselled(base, rng, cells=4, amount=0.06, n=N):
    """Flat colour broken into jittered low-poly triangles."""
    t = Tex(base, n)
    P = {}
    for i in range(cells + 1):
        for j in range(cells + 1):
            jx = 0 if i in (0, cells) else rng.uniform(-0.3, 0.3) / cells
            jy = 0 if j in (0, cells) else rng.uniform(-0.3, 0.3) / cells
            P[i, j] = (i / cells + jx, j / cells + jy)
    b = hexrgb(base) if isinstance(base, str) else np.asarray(base)
    for i in range(cells):
        for j in range(cells):
            a, bq, c, d = P[i, j], P[i + 1, j], P[i + 1, j + 1], P[i, j + 1]
            for tri in ([a, bq, c], [a, c, d]) if (i + j) % 2 == 0 else ([a, bq, d], [bq, c, d]):
                t.poly(tri, b * (1 + rng.uniform(-amount, amount)))
    return t


# ---------- isometric cube ----------
def cube_vectors(s):
    R = np.array([0.8660254 * s, -0.5 * s])
    L = np.array([-0.8660254 * s, -0.5 * s])
    D = np.array([0.0, s])
    return R, L, D


def sample(tex, u, v):
    n = tex.shape[0]
    x = np.clip(u * (n - 1), 0, n - 1)
    y = np.clip(v * (n - 1), 0, n - 1)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    x1, y1 = np.minimum(x0 + 1, n - 1), np.minimum(y0 + 1, n - 1)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    return (
        tex[y0, x0] * (1 - fx) * (1 - fy)
        + tex[y0, x1] * fx * (1 - fy)
        + tex[y1, x0] * (1 - fx) * fy
        + tex[y1, x1] * fx * fy
    )


def draw_cube(canvas, glow, H, s, faces, shade=(1.0, 0.8, 0.62)):
    """faces = [(rgb, em) for top, left, right]. H = front-top vertex, s = edge (canvas px)."""
    H = np.asarray(H, float)
    R, L, D = cube_vectors(s)
    specs = [(H + L + R, -L, -R), (H + L, -L, D), (H, R, D)]
    h, w = canvas.shape[:2]
    for (rgb, em), (O, A, B), k in zip(faces, specs, shade):
        cs = [O, O + A, O + B, O + A + B]
        x0 = max(int(math.floor(min(c[0] for c in cs))), 0)
        x1 = min(int(math.ceil(max(c[0] for c in cs))), w)
        y0 = max(int(math.floor(min(c[1] for c in cs))), 0)
        y1 = min(int(math.ceil(max(c[1] for c in cs))), h)
        yy, xx = np.mgrid[y0:y1, x0:x1] + 0.5
        Minv = np.linalg.inv(np.array([[A[0], B[0]], [A[1], B[1]]]))
        px, py = xx - O[0], yy - O[1]
        u = Minv[0, 0] * px + Minv[0, 1] * py
        v = Minv[1, 0] * px + Minv[1, 1] * py
        m = (u >= 0) & (u < 1) & (v >= 0) & (v < 1)
        col = sample(rgb, u, v) * k
        region = canvas[y0:y1, x0:x1]
        region[m] = col[m]
        if em is not None:
            g = sample(em, u, v)
            gr = glow[y0:y1, x0:x1]
            gr[m] = np.maximum(gr[m], g[m])
            region[m] = 1 - (1 - region[m]) * (1 - g[m])
    return H, R, L, D


def cube_outline(draw, H, s, color, width, inner=None, inner_width=None):
    R, L, D = cube_vectors(s)
    H = np.asarray(H)
    hexa = [H + L + R, H + R, H + R + D, H + D, H + L + D, H + L]
    draw.line([tuple(p) for p in hexa + [hexa[0]]], fill=color, width=width, joint="curve")
    ic = inner if inner is not None else color
    iw = inner_width or width
    for p in (H + L, H + R, H + D):
        draw.line([tuple(H), tuple(p)], fill=ic, width=iw)


def bloom(canvas, glow, radius, strength):
    g = Image.fromarray((np.clip(glow, 0, 1) * 255).astype(np.uint8))
    b1 = np.asarray(g.filter(ImageFilter.GaussianBlur(radius)), float) / 255
    b2 = np.asarray(g.filter(ImageFilter.GaussianBlur(radius * 3)), float) / 255
    return 1 - (1 - canvas) * (1 - np.clip((b1 * 0.9 + b2 * 0.8) * strength, 0, 1))


RARITY = {
    "Common": "A3A8B0",
    "Uncommon": "6BCB5E",
    "Rare": "4AA3FF",
    "Epic": "B26BFF",
    "Legendary": "FFB23F",
    "Mythic": "FF5C8A",
    "Celestial": "E7D3FF",
}


def chip(draw, x, y, text, color, fnt, text_color=(20, 20, 28)):
    tw = draw.textlength(text, font=fnt)
    pad = 10 * SS
    h = fnt.size + 8 * SS
    draw.rounded_rectangle([x - tw / 2 - pad, y, x + tw / 2 + pad, y + h], radius=h / 2, fill=to255(hexrgb(color)))
    draw.text((x, y + h / 2), text, font=fnt, fill=text_color, anchor="mm")


def wrap(draw, text, fnt, width):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        t = (cur + " " + wd).strip()
        if draw.textlength(t, font=fnt) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = wd
    if cur:
        lines.append(cur)
    return lines
