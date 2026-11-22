"""Ore silhouettes drawn in face-texture space (0..1). Shared by the Gem Cut and Ink themes."""
import math
import colorsys
import numpy as np
from core import Tex, blob, pal_at, hexrgb, LIGHT


def _rot(pts, c, ang):
    ca, sa = math.cos(ang), math.sin(ang)
    return [(c[0] + (x - c[0]) * ca - (y - c[1]) * sa, c[1] + (x - c[0]) * sa + (y - c[1]) * ca) for x, y in pts]


def glowcol(ore, k=1.0):
    g = ore.get("glow")
    return None if g is None else hexrgb(g) * k


def lumps(t, ore, rng, style):
    pal = ore["pal"]
    for cx, cy, r in [(0.34, 0.4, 0.2), (0.68, 0.33, 0.14), (0.64, 0.7, 0.17), (0.28, 0.76, 0.1)]:
        c = (cx + rng.uniform(-0.03, 0.03), cy + rng.uniform(-0.03, 0.03))
        pts = blob(c, r, 7, rng, 0.2)
        style.dome(t, pts, pal, rng)
    if ore["shape"] == "glitter":
        g = hexrgb(ore["extra"][0])
        for _ in range(26):
            c = (rng.uniform(0.15, 0.85), rng.uniform(0.15, 0.88))
            t.sparkle(c, rng.uniform(0.01, 0.025), fill=g, glow=g * 0.8)
    else:
        t.poly([(0.27, 0.3), (0.33, 0.27), (0.3, 0.34)], pal_at(pal, 1))


def nuggets(t, ore, rng, style):
    pal = ore["pal"]
    for cx, cy, r in [(0.33, 0.38, 0.16), (0.64, 0.33, 0.12), (0.6, 0.66, 0.15), (0.28, 0.72, 0.1), (0.8, 0.82, 0.07)]:
        c = (cx + rng.uniform(-0.02, 0.02), cy + rng.uniform(-0.02, 0.02))
        style.dome(t, blob(c, r, 11, rng, 0.12), pal, rng, lift=0.5)
        t.ellipse((c[0] + LIGHT[0] * r * 0.45, c[1] + LIGHT[1] * r * 0.45), r * 0.18, pal_at(pal, 1))


def wires(t, ore, rng, style):
    pal = ore["pal"]
    paths = []
    p = np.array([0.14, 0.84])
    main = [tuple(p)]
    ang = -0.8
    for _ in range(6):
        ang += rng.uniform(-0.5, 0.5)
        p = p + 0.13 * np.array([math.cos(ang), math.sin(ang)])
        p = np.clip(p, 0.1, 0.9)
        main.append(tuple(p))
    paths.append(main)
    for k in (2, 4):
        q = np.array(main[k])
        br = [tuple(q)]
        a2 = ang + rng.choice([-1.3, 1.3])
        for _ in range(2):
            q = np.clip(q + 0.12 * np.array([math.cos(a2), math.sin(a2)]), 0.1, 0.9)
            br.append(tuple(q))
            a2 += rng.uniform(-0.4, 0.4)
        paths.append(br)
    style.wire(t, paths, pal)
    for path in paths:
        for q in path[1::2]:
            style.dome(t, blob(q, rng.uniform(0.035, 0.06), 8, rng, 0.15), pal, rng)
    if "extra" in ore:
        for _ in range(3):
            c = (rng.uniform(0.2, 0.8), rng.uniform(0.2, 0.8))
            style.dome(t, blob(c, rng.uniform(0.04, 0.07), 7, rng, 0.3), ore["extra"] + ore["extra"][-1:], rng)


def plates(t, ore, rng, style):
    pal = ore["pal"]
    for i, (cx, cy, w, h, a) in enumerate([(0.36, 0.34, 0.46, 0.15, -20), (0.6, 0.52, 0.5, 0.16, -14), (0.4, 0.72, 0.42, 0.13, -24), (0.7, 0.26, 0.28, 0.1, -8)]):
        c = (cx, cy)
        ang = math.radians(a + rng.uniform(-4, 4))
        body = _rot([(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), (cx - w / 2, cy + h / 2)], c, ang)
        top = _rot([(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2 - 0.02, cy - h / 4), (cx - w / 2 + 0.02, cy - h / 4)], c, ang)
        bot = _rot([(cx - w / 2 + 0.02, cy + h / 3), (cx + w / 2 - 0.02, cy + h / 3), (cx + w / 2, cy + h / 2), (cx - w / 2, cy + h / 2)], c, ang)
        style.flat(t, body, pal_at(pal, 0.45 + 0.1 * (i % 2)))
        style.flat(t, top, pal_at(pal, 0.85), edge=False)
        style.flat(t, bot, pal_at(pal, 0.12), edge=False)
        if ore["shape"] == "meteor":
            for k in range(-3, 4):
                for d in (0.0, 1.05, 2.1):
                    off = k * 0.05
                    p1 = _rot([(cx + off - 0.3 * math.cos(d), cy - 0.3 * math.sin(d)), (cx + off + 0.3 * math.cos(d), cy + 0.3 * math.sin(d))], c, ang)
                    style.etch(t, p1, pal_at(pal, 0.95 if d else 0.75), ore)
    if "extra" in ore and ore["shape"] == "plates":
        rust = hexrgb(ore["extra"][0])
        for _ in range(9):
            t.ellipse((rng.uniform(0.15, 0.85), rng.uniform(0.15, 0.85)), rng.uniform(0.008, 0.02), rust)


def octa(t, ore, rng, style):
    pal = ore["pal"]
    for cx, cy, r in [(0.4, 0.42, 0.22), (0.72, 0.7, 0.12), (0.22, 0.76, 0.08)]:
        cc = (cx + LIGHT[0] * 0.15 * r, cy + LIGHT[1] * 0.15 * r)
        top, right, bot, left = (cx, cy - 1.25 * r), (cx + r, cy), (cx, cy + 1.25 * r), (cx - r, cy)
        for tri, k in (([cc, top, left], 0.95), ([cc, top, right], 0.68), ([cc, left, bot], 0.5), ([cc, right, bot], 0.22)):
            style.flat(t, tri, pal_at(pal, k), glow=glowcol(ore, 0.18 * k))
    style.spark(t, (0.33, 0.27), 0.07, ore)


def hexes(t, ore, rng, style):
    pal = ore["pal"]
    for cx, cy, r, rot in [(0.4, 0.42, 0.2, 0.1), (0.7, 0.68, 0.13, 0.4), (0.24, 0.74, 0.09, 0.2), (0.74, 0.28, 0.08, 0.0)]:
        pts = [(cx + r * math.cos(rot + i * math.pi / 3), cy + r * math.sin(rot + i * math.pi / 3)) for i in range(6)]
        style.dome(t, pts, pal, rng, lift=0.0, glow=glowcol(ore, 0.12))
        inner = [(cx + 0.55 * r * math.cos(rot + i * math.pi / 3), cy + 0.55 * r * math.sin(rot + i * math.pi / 3)) for i in range(6)]
        style.flat(t, inner, pal_at(pal, 0.7), glow=glowcol(ore, 0.2))
    style.spark(t, (0.32, 0.3), 0.05, ore)


def geode(t, ore, rng, style):
    pal = ore["pal"]
    c = (0.5, 0.52)
    rind = hexrgb(ore["matrix"]) * 0.7
    style.flat(t, blob(c, 0.4, 16, rng, 0.06), rind)
    style.flat(t, blob(c, 0.33, 16, rng, 0.04), np.array([0.84, 0.8, 0.88]), edge=False)
    style.flat(t, blob(c, 0.29, 16, rng, 0.03), pal_at(pal, 0.0), edge=False)
    k = 13
    for i in range(k):
        a = 2 * math.pi * i / k + rng.uniform(-0.1, 0.1)
        b1 = (c[0] + 0.29 * math.cos(a - math.pi / k), c[1] + 0.29 * math.sin(a - math.pi / k))
        b2 = (c[0] + 0.29 * math.cos(a + math.pi / k), c[1] + 0.29 * math.sin(a + math.pi / k))
        rr = rng.uniform(0.08, 0.15)
        tip = (c[0] + rr * math.cos(a), c[1] + rr * math.sin(a))
        mid = ((b1[0] + b2[0]) / 2, (b1[1] + b2[1]) / 2)
        facing = 0.5 + 0.5 * -(math.cos(a) * LIGHT[0] + math.sin(a) * LIGHT[1])
        style.flat(t, [b1, mid, tip], pal_at(pal, 0.35 + 0.6 * facing), glow=glowcol(ore, 0.15), edge=False)
        style.flat(t, [mid, b2, tip], pal_at(pal, 0.15 + 0.5 * facing), glow=glowcol(ore, 0.1), edge=False)
    style.spark(t, (0.42, 0.4), 0.05, ore)


def barrels(t, ore, rng, style):
    pal = ore["pal"]
    for cx, cy, r, a in [(0.42, 0.46, 0.3, -0.35), (0.72, 0.62, 0.17, 0.4), (0.24, 0.78, 0.1, 0.2)]:
        w = 0.42 * r
        P = {
            "top": (0, -r), "ul": (-w, -0.4 * r), "ur": (w, -0.4 * r), "ll": (-w, 0.4 * r), "lr": (w, 0.4 * r), "bot": (0, r),
            "mu": (0.1 * w, -0.4 * r), "ml": (0.1 * w, 0.4 * r),
        }
        ca, sa = math.cos(a), math.sin(a)
        Q = {k: (cx + x * ca - y * sa, cy + x * sa + y * ca) for k, (x, y) in P.items()}
        for names, k in ((("top", "ul", "mu"), 0.98), (("top", "mu", "ur"), 0.66), (("ul", "ll", "ml", "mu"), 0.78),
                         (("mu", "ml", "lr", "ur"), 0.42), (("ll", "bot", "ml"), 0.5), (("ml", "bot", "lr"), 0.18)):
            style.flat(t, [Q[n] for n in names], pal_at(pal, k), glow=glowcol(ore, 0.15 * k))
    style.spark(t, (0.36, 0.28), 0.06, ore)


def shards(t, ore, rng, style):
    pal = ore["pal"]
    g = glowcol(ore)
    for cx, cy, r, a in [(0.4, 0.42, 0.26, -0.5), (0.68, 0.64, 0.2, 0.6), (0.3, 0.74, 0.13, 1.9)]:
        pts = _rot([(cx, cy - r), (cx + 0.38 * r, cy + 0.25 * r), (cx - 0.1 * r, cy + 0.6 * r), (cx - 0.42 * r, cy + 0.1 * r)], (cx, cy), a)
        style.flat(t, pts, pal_at(pal, 0.15))
        style.flat(t, [pts[0], pts[1], (cx, cy)], pal_at(pal, 0.4), edge=False)
        style.flat(t, [pts[0], pts[3], (cx + 0.05 * r, cy - 0.1 * r)], pal_at(pal, 0.75), edge=False)
    for _ in range(4):
        p = np.array([rng.uniform(0.3, 0.7), rng.uniform(0.3, 0.7)])
        crack = [tuple(p)]
        ang = rng.uniform(0, 2 * math.pi)
        for _ in range(5):
            ang += rng.uniform(-0.7, 0.7)
            p = np.clip(p + 0.08 * np.array([math.cos(ang), math.sin(ang)]), 0.05, 0.95)
            crack.append(tuple(p))
        style.crack(t, crack, ore)
    if ore["name"] == "Frostglass":
        for _ in range(10):
            t.ellipse((rng.uniform(0.2, 0.8), rng.uniform(0.2, 0.8)), rng.uniform(0.01, 0.025), None, outline=pal_at(pal, 1), width=2)


def star(t, ore, rng, style):
    pal = ore["pal"]
    c = (0.5, 0.5)
    pts = []
    for i in range(8):
        a = i * math.pi / 4 - math.pi / 2 + 0.12
        rr = 0.36 if i % 2 == 0 else 0.13
        pts.append((c[0] + rr * math.cos(a), c[1] + rr * math.sin(a)))
    style.dome(t, pts, pal, rng, lift=0.15, glow=glowcol(ore, 0.55))
    t.ellipse(c, 0.06, pal_at(pal, 1), glow=glowcol(ore))
    for cx, cy, r in [(0.2, 0.22, 0.05), (0.8, 0.3, 0.035), (0.76, 0.8, 0.05), (0.22, 0.78, 0.03)]:
        t.sparkle((cx, cy), r, fill=pal_at(pal, 1), glow=glowcol(ore, 0.9))


def cubes(t, ore, rng, style):
    pal = ore["pal"]
    fluor = ore["name"] == "Fluorite"
    for i, (cx, cy, a) in enumerate([(0.38, 0.44, 0.15), (0.66, 0.36, 0.1), (0.62, 0.7, 0.12), (0.28, 0.74, 0.08), (0.8, 0.6, 0.06)]):
        R, L, D = np.array([0.866 * a, -0.5 * a]), np.array([-0.866 * a, -0.5 * a]), np.array([0, a])
        c = np.array([cx, cy])
        p = pal if not fluor else (pal[:2] + [pal[1], "C7B0FF"] if i % 2 == 0 else ["1F6E58", pal[2], pal[3], pal[3]])
        style.flat(t, [c, c + R, c + R + L, c + L], pal_at(p, 0.95))
        style.flat(t, [c, c + L, c + L + D, c + D], pal_at(p, 0.6))
        style.flat(t, [c, c + D, c + D + R, c + R], pal_at(p, 0.25))
        if not fluor:
            for k in (0.3, 0.6):
                t.line([tuple(c + L * 0.1 + D * k), tuple(c + L * 0.9 + D * k)], pal_at(p, 0.4), 0.006)


def opal(t, ore, rng, style):
    pal = ore["pal"]
    for cx, cy, r in [(0.42, 0.44, 0.24), (0.7, 0.7, 0.13)]:
        pts = blob((cx, cy), r, 10, rng, 0.12)
        style.dome(t, pts, pal, rng, lift=0.3)
        for _ in range(int(140 * r)):
            ang, rr = rng.uniform(0, 2 * math.pi), r * math.sqrt(rng.uniform(0, 0.75))
            p = (cx + rr * math.cos(ang), cy + rr * math.sin(ang))
            h = rng.uniform(0, 1)
            col = np.array(colorsys.hsv_to_rgb(h, 0.75, 1.0))
            s = rng.uniform(0.012, 0.03)
            tri = [(p[0], p[1] - s), (p[0] + s, p[1] + s * 0.6), (p[0] - s, p[1] + s * 0.4)]
            t.poly(tri, col, glow=col * 0.35)


def cabochon(t, ore, rng, style):
    pal = ore["pal"]
    sheen = hexrgb(ore["extra"][0])
    for cx, cy, rx, ry in [(0.44, 0.44, 0.26, 0.21), (0.72, 0.74, 0.12, 0.1)]:
        style.flat(t, [(cx + rx * math.cos(a), cy + ry * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 24, endpoint=False)], pal_at(pal, 0.15))
        for k in range(6):
            f = 1 - k * 0.14
            t.ellipse((cx + LIGHT[0] * rx * 0.08 * k, cy + LIGHT[1] * ry * 0.08 * k), (rx * f, ry * f), pal_at(pal, 0.25 + k * 0.13))
        t.ellipse((cx + 0.04 * rx, cy - 0.15 * ry), (rx * 0.7, ry * 0.35), sheen * 0.6 + pal_at(pal, 0.8) * 0.4, glow=sheen * 0.35)
        t.ellipse((cx - 0.35 * rx, cy - 0.45 * ry), (rx * 0.12, ry * 0.1), pal_at(pal, 1))


SHAPES = {
    "lumps": lumps, "glitter": lumps, "nuggets": nuggets, "wires": wires, "plates": plates, "meteor": plates,
    "octa": octa, "hex": hexes, "geode": geode, "barrel": barrels, "shards": shards, "star": star,
    "cubes": cubes, "opal": opal, "cabochon": cabochon,
}
