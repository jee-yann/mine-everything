"""Face drawings for the ores added in the region expansion, in the same Storybook Ink style.

Each function draws one ore's pieces on a face texture `t` (coordinates 0..1, y down) with the
shared `style` (flat cel colour, a highlight and a thick ink outline). draw_faces.py registers
them by shape name.
"""
import math
import colorsys
import numpy as np
from core import blob, pal_at, hexrgb, LIGHT, to255

INK = hexrgb("1A141F")
# The usual layout: one big piece and three smaller ones, clear of the shadowed corner.
LAYOUT = [(0.42, 0.44, 0.22), (0.74, 0.72, 0.12), (0.76, 0.25, 0.09), (0.21, 0.77, 0.085)]


def _v(x, y):
    return np.array([x, y], float)


def _outline(t, style, pts, edge=True):
    t.d.polygon(t.P(pts), outline=to255(INK), width=style.ow(t, edge))


def points(t, ore, rng, style):
    """Quartz: clusters of clear six-sided points growing from one base."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT[:3]:
        n = 3 if r > 0.15 else 2
        for k in range(n):
            ang = math.radians(-90 + (k - (n - 1) / 2) * 30 + rng.uniform(-6, 6))
            d = _v(math.cos(ang), math.sin(ang))
            nrm = _v(-d[1], d[0])
            length = r * (1.7 if k == n // 2 else 1.2)
            w = r * 0.3
            base = _v(cx, cy + r * 0.55)
            shoulder, tip = base + d * length * 0.72, base + d * length
            body = [base + nrm * w, shoulder + nrm * w, tip, shoulder - nrm * w, base - nrm * w]
            style.flat(t, body, pal_at(pal, 0.5))
            t.poly([base + nrm * w, shoulder + nrm * w, tip, shoulder, base], pal_at(pal, 0.86))
            t.line([tuple(base), tuple(shoulder), tuple(tip)], INK, 0.006)
            _outline(t, style, body)


def sunburst(t, ore, rng, style):
    """Sunstone: warm feldspar cabochons full of glittering copper flecks."""
    pal, fleck = ore["pal"], hexrgb(ore["extra"][0])
    for cx, cy, r in LAYOUT[:3]:
        pts = blob((cx, cy), r, 14, rng, 0.06)
        style.dome(t, pts, pal, rng, lift=0.4)
        for _ in range(int(160 * r)):
            ang, rr = rng.uniform(0, 2 * math.pi), r * math.sqrt(rng.uniform(0, 0.7))
            c = (cx + rr * math.cos(ang), cy + rr * math.sin(ang))
            s = rng.uniform(0.006, 0.014)
            t.poly([(c[0] - s, c[1]), (c[0], c[1] - s * 0.5), (c[0] + s, c[1]), (c[0], c[1] + s * 0.5)], fleck)
        _outline(t, style, pts)
    style.spark(t, (0.33, 0.3), 0.07, ore)


def dodeca(t, ore, rng, style):
    """Garnet: rounded twelve-sided crystals, drawn as hexagons split into lit and shaded facets."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        rot = rng.uniform(0, 1)
        ring = [_v(cx + r * math.cos(rot + i * math.pi / 3), cy + r * math.sin(rot + i * math.pi / 3)) for i in range(6)]
        c = _v(cx, cy) + _v(*LIGHT) * r * 0.12
        for i in range(6):
            a, b = ring[i], ring[(i + 1) % 6]
            m = (a + b) / 2 - c
            lit = 0.5 + 0.5 * float(np.dot(m / (np.linalg.norm(m) + 1e-9), LIGHT))
            t.poly([c, a, b], pal_at(pal, 0.15 + 0.8 * lit))
        for p in ring[::2]:
            t.line([tuple(c), tuple(p)], INK, 0.005)
        _outline(t, style, ring)


def blades(t, ore, rng, style):
    """Selenite: short satin tablets, slanted rhombs with a soft sheen and fine striations."""
    pal = ore["pal"]
    for k, (cx, cy, r) in enumerate(LAYOUT):
        ang = math.radians(-60 + rng.uniform(-8, 8))
        d, nrm = _v(math.cos(ang), math.sin(ang)), _v(-math.sin(ang), math.cos(ang))
        half, w, lean = r * 0.82, r * 1.05, r * 0.34
        c = _v(cx, cy)
        body = [c - d * half + nrm * w / 2 + d * lean, c + d * half + nrm * w / 2,
                c + d * half - nrm * w / 2 - d * lean, c - d * half - nrm * w / 2]
        style.flat(t, body, pal_at(pal, 0.55))
        t.poly([body[0], body[1], c + d * half * 0.1, c - d * half * 0.9 + d * lean * 0.5], pal_at(pal, 0.86))
        for s in (-0.25, 0.05, 0.3):
            p = c + nrm * w * s
            t.line([tuple(p - d * half * 0.55), tuple(p + d * half * 0.55)], pal_at(pal, 0.4), 0.004)
        t.line([tuple(c - d * half * 0.3 + nrm * w * 0.18), tuple(c + d * half * 0.35 + nrm * w * 0.18)], pal_at(pal, 1.0), 0.008)
        _outline(t, style, body)


def pebbles(t, ore, rng, style):
    """Jade: smooth rounded nodules with darker mottling and a soft polish."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        pts = blob((cx, cy), r, 12, rng, 0.1, aspect=1.15)
        style.dome(t, pts, pal, rng, lift=0.25)
        for _ in range(int(40 * r) + 2):
            ang, rr = rng.uniform(0, 2 * math.pi), r * math.sqrt(rng.uniform(0, 0.55))
            c = (cx + rr * math.cos(ang), cy + rr * math.sin(ang))
            t.poly(blob(c, r * rng.uniform(0.08, 0.16), 7, rng, 0.35), pal_at(pal, 0.15))
        t.ellipse((cx + LIGHT[0] * r * 0.4, cy + LIGHT[1] * r * 0.45), (r * 0.28, r * 0.12), pal_at(pal, 1.0))
        _outline(t, style, pts)


def glowcaps(t, ore, rng, style):
    """Lumenite: little crystal mushrooms with glowing caps and spots."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        stem = [(cx - r * 0.18, cy), (cx + r * 0.18, cy), (cx + r * 0.24, cy + r * 0.9), (cx - r * 0.24, cy + r * 0.9)]
        style.flat(t, stem, pal_at(pal, 0.35))
        cap = [(cx + r * math.cos(a), cy - r * 0.62 * math.sin(a)) for a in np.linspace(0, math.pi, 14)]
        cap += [(cx - r * 0.9, cy + r * 0.08), (cx + r * 0.9, cy + r * 0.08)][::-1]
        style.flat(t, cap, pal_at(pal, 0.6))
        t.poly([(cx + r * 0.75 * math.cos(a), cy - r * 0.5 * math.sin(a)) for a in np.linspace(0.6, math.pi - 0.2, 10)] + [(cx - r * 0.3, cy - r * 0.1)], pal_at(pal, 0.85))
        for _ in range(3):
            c = (cx + rng.uniform(-0.55, 0.55) * r, cy - rng.uniform(0.15, 0.45) * r)
            t.ellipse(c, r * rng.uniform(0.07, 0.11), pal_at(pal, 1.0))
        _outline(t, style, cap)
        _outline(t, style, stem, edge=False)


def flakes(t, ore, rng, style):
    """Obsidian: chunky black glass shards with curved ripples, a glassy sheen and a bright lit edge."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        rot = rng.uniform(0, 2 * math.pi)
        pts = []
        for i in range(6):
            a = rot + i * math.pi / 3 + rng.uniform(-0.25, 0.25)
            rr = r * rng.uniform(0.7, 1.05)
            pts.append(_v(cx + rr * math.cos(a), cy + rr * 0.9 * math.sin(a)))
        style.flat(t, pts, pal_at(pal, 0.25))
        c = _v(cx, cy)
        # a broad glassy reflection toward the light, then a thin bright streak inside it
        sheen = [c + (p - c) * 0.62 + _v(*LIGHT) * r * 0.22 for p in pts]
        t.poly(sheen, pal_at(pal, 0.55))
        streak = [c + (p - c) * 0.3 + _v(*LIGHT) * r * 0.42 for p in pts]
        t.poly(streak, pal_at(pal, 0.85))
        corner = min(pts, key=lambda p: (p - c) @ np.array(LIGHT))
        for k in (0.5, 0.78):
            arc = [corner + (p - corner) * k for p in pts]
            t.line([tuple(q) for q in arc[1:5]], pal_at(pal, 0.45), 0.004)
        lit = sorted(range(6), key=lambda i: ((pts[i] + pts[(i + 1) % 6]) / 2 - c) @ np.array(LIGHT))[0]
        t.line([tuple(pts[lit]), tuple(pts[(lit + 1) % 6])], pal_at(pal, 1.0), 0.014)
        _outline(t, style, pts)


def cushion(t, ore, rng, style):
    """Ruby: cushion-cut stones, a rounded square with a star of facets."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        rot = rng.uniform(-0.3, 0.3)
        ring = []
        for i in range(8):
            a = rot + i * math.pi / 4 + math.pi / 8
            rr = r * (1.0 if i % 2 == 0 else 0.92)
            ring.append(_v(cx + rr * math.cos(a), cy + rr * math.sin(a)))
        table = [(_v(cx, cy) + (p - _v(cx, cy)) * 0.45) for p in ring]
        style.flat(t, ring, pal_at(pal, 0.35))
        for i in range(8):
            a, b = ring[i], ring[(i + 1) % 8]
            m = (a + b) / 2 - _v(cx, cy)
            lit = 0.5 + 0.5 * float(np.dot(m / (np.linalg.norm(m) + 1e-9), LIGHT))
            t.poly([a, b, table[(i + 1) % 8], table[i]], pal_at(pal, 0.2 + 0.7 * lit))
        t.poly(table, pal_at(pal, 0.75))
        t.poly(blob((cx + LIGHT[0] * r * 0.2, cy + LIGHT[1] * r * 0.2), r * 0.16, 6, rng, 0.2), pal_at(pal, 1.0))
        _outline(t, style, ring)
    style.spark(t, (0.32, 0.3), 0.06, ore)


def lattice(t, ore, rng, style):
    """Mithril: a shimmering honeycomb lattice of fine metal veins."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT[:2]:
        size = r * 0.42
        for q in range(-2, 3):
            for s in range(-2, 3):
                x = cx + size * 1.5 * q
                y = cy + size * math.sqrt(3) * (s + q / 2)
                if (x - cx) ** 2 + (y - cy) ** 2 > (r * 1.05) ** 2:
                    continue
                hexa = [(x + size * math.cos(i * math.pi / 3), y + size * math.sin(i * math.pi / 3)) for i in range(6)]
                lit = 0.5 + 0.5 * ((cx - x) * LIGHT[0] + (cy - y) * LIGHT[1]) / (r + 1e-9) * -1
                t.poly(hexa, pal_at(pal, 0.35 + 0.45 * lit))
                t.d.polygon(t.P(hexa), outline=to255(INK), width=max(2, style.ow(t) // 2))
                t.ellipse((x, y), size * 0.22, pal_at(pal, 0.95))
    for cx, cy, r in LAYOUT[2:]:
        style.dome(t, blob((cx, cy), r, 6, rng, 0.1), pal, rng)


def crust(t, ore, rng, style):
    """Brimstone: knobbly crusts of small sulphur globules."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        count = 9 if r > 0.15 else 4
        for _ in range(count):
            ang, rr = rng.uniform(0, 2 * math.pi), r * math.sqrt(rng.uniform(0, 0.8))
            c = (cx + rr * math.cos(ang), cy + rr * math.sin(ang))
            g = r * rng.uniform(0.22, 0.38)
            pts = blob(c, g, 9, rng, 0.12)
            style.dome(t, pts, pal, rng, lift=0.5)


def columns(t, ore, rng, style):
    """Aquamarine: stubby six-sided crystals, each showing its flat hexagonal end."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        ang = math.radians(-35 + rng.uniform(-12, 12))
        d, nrm = _v(math.cos(ang), math.sin(ang)), _v(-math.sin(ang), math.cos(ang))
        half, w = r * 0.5, r * 0.52
        a, b = _v(cx, cy) - d * half, _v(cx, cy) + d * half
        body = [a + nrm * w, b + nrm * w, b + d * w * 0.55 + nrm * w * 0.5, b + d * w * 0.55 - nrm * w * 0.5,
                b - nrm * w, a - nrm * w, a - d * w * 0.3]
        style.flat(t, body, pal_at(pal, 0.45))
        t.poly([a + nrm * w, b + nrm * w, b + nrm * w * 0.25, a + nrm * w * 0.25], pal_at(pal, 0.82))
        t.poly([a - nrm * w * 0.4, b - nrm * w * 0.4, b - nrm * w, a - nrm * w], pal_at(pal, 0.2))
        cap = [b + nrm * w, b + d * w * 0.55 + nrm * w * 0.5, b + d * w * 0.55 - nrm * w * 0.5, b - nrm * w,
               b - d * w * 0.25 - nrm * w * 0.5, b - d * w * 0.25 + nrm * w * 0.5]
        t.poly(cap, pal_at(pal, 0.95))
        t.d.polygon(t.P(cap), outline=to255(INK), width=style.ow(t, False))
        _outline(t, style, body)
    style.spark(t, (0.3, 0.32), 0.06, ore)


def pitted(t, ore, rng, style):
    """Meteorite: heavy pitted lumps of meteoric iron, etched with criss-cross bands."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT[:3]:
        pts = blob((cx, cy), r, 9, rng, 0.2)
        style.dome(t, pts, pal, rng, lift=0.3)
        for k in range(-2, 3):
            for dx, dy in ((1, 0.55), (0.55, -1), (1, -0.6)):
                n = np.hypot(dx, dy)
                ox, oy = cx + k * r * 0.18 * (-dy / n), cy + k * r * 0.18 * (dx / n)
                t.line([(ox - dx / n * r * 0.55, oy - dy / n * r * 0.55), (ox + dx / n * r * 0.55, oy + dy / n * r * 0.55)], pal_at(pal, 0.75), 0.003)
        for _ in range(4):
            c = (cx + rng.uniform(-0.5, 0.5) * r, cy + rng.uniform(-0.5, 0.5) * r)
            t.ellipse(c, r * rng.uniform(0.08, 0.14), pal_at(pal, 0.08))
        _outline(t, style, pts)


def prism(t, ore, rng, style):
    """Adamantite: hard angular crystals with bright cut edges."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        rot = rng.uniform(-0.4, 0.4)
        pts = [_v(cx + r * math.cos(rot + a), cy + r * 0.85 * math.sin(rot + a)) for a in (-2.6, -1.3, -0.2, 0.9, 2.2)]
        c = _v(cx, cy) + _v(*LIGHT) * r * 0.25
        for i in range(5):
            a, b = pts[i], pts[(i + 1) % 5]
            m = (a + b) / 2 - c
            lit = 0.5 + 0.5 * float(np.dot(m / (np.linalg.norm(m) + 1e-9), LIGHT))
            t.poly([c, a, b], pal_at(pal, 0.1 + 0.85 * lit))
            t.line([tuple(c), tuple(a)], pal_at(pal, 1.0), 0.005)
        _outline(t, style, pts)


def rings(t, ore, rng, style):
    """Resonite: a crystal orb ringed by ripples, as if it were humming."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT[:2]:
        for k in (1.55, 1.3):
            ring = [(cx + r * k * math.cos(a), cy + r * k * 0.8 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 28, endpoint=False)]
            t.d.polygon(t.P(ring), outline=to255(pal_at(pal, 0.7)), width=max(2, style.ow(t) // 2))
        pts = [(cx + r * math.cos(a), cy + r * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 7, endpoint=False)]
        style.dome(t, pts, pal, rng, lift=0.2)
        t.d.polygon(t.P([(cx + r * 0.55 * math.cos(a), cy + r * 0.55 * math.sin(a)) for a in np.linspace(0.4, 2 * math.pi + 0.4, 7, endpoint=False)]), outline=to255(pal_at(pal, 1.0)), width=max(2, style.ow(t) // 3))
    for cx, cy, r in LAYOUT[2:]:
        style.dome(t, [(cx + r * math.cos(a), cy + r * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 7, endpoint=False)], pal, rng)
    style.spark(t, (0.34, 0.33), 0.06, ore)


def void(t, ore, rng, style):
    """Voidshard: jagged black shards with a purple void core full of tiny stars."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT[:3]:
        n = 7
        pts = []
        for i in range(n):
            a = i * 2 * math.pi / n + rng.uniform(-0.2, 0.2)
            rr = r * (1.0 if i % 2 == 0 else 0.55)
            pts.append((cx + rr * math.cos(a), cy + rr * 1.15 * math.sin(a)))
        style.flat(t, pts, pal_at(pal, 0.05))
        core = blob((cx, cy), r * 0.42, 9, rng, 0.2)
        t.poly(core, pal_at(pal, 0.55))
        t.poly(blob((cx, cy), r * 0.22, 7, rng, 0.2), pal_at(pal, 0.85))
        for _ in range(6):
            c = (cx + rng.uniform(-0.3, 0.3) * r, cy + rng.uniform(-0.3, 0.3) * r)
            t.sparkle(c, r * rng.uniform(0.05, 0.1), fill="FFFFFF")
        t.line(pts[:3], pal_at(pal, 0.95), 0.006)
        _outline(t, style, pts)


def beads(t, ore, rng, style):
    """Silver: bubbly clusters of round metal beads, bright where they catch the light."""
    pal = ore["pal"]
    for cx, cy, r in LAYOUT:
        n = 3 if r > 0.1 else 2
        spots = [(cx, cy, r * 0.62)]
        for k in range(n - 1):
            a = rng.uniform(0, 2 * math.pi)
            spots.append((cx + math.cos(a) * r * 0.48, cy + math.sin(a) * r * 0.48, r * rng.uniform(0.38, 0.5)))
        spots.sort(key=lambda q: q[1])
        for bx, by, br in spots:
            pts = blob((bx, by), br, 12, rng, 0.05)
            style.dome(t, pts, pal, rng, lift=0.45)
            for _ in range(2):
                q = (bx + rng.uniform(-0.5, 0.5) * br, by + rng.uniform(0.0, 0.6) * br)
                t.ellipse(q, br * rng.uniform(0.07, 0.12), pal_at(pal, 0.12))
    style.spark(t, (0.34, 0.3), 0.05, ore)

NEW_SHAPES = {
    "beads": beads,
    "points": points,
    "sunburst": sunburst,
    "dodeca": dodeca,
    "blades": blades,
    "pebbles": pebbles,
    "glowcaps": glowcaps,
    "flakes": flakes,
    "cushion": cushion,
    "lattice": lattice,
    "crust": crust,
    "columns": columns,
    "pitted": pitted,
    "prism": prism,
    "rings": rings,
    "void": void,
}
