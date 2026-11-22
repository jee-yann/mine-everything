"""Draws the Storybook Ink face images the game puts on every open block face.

Run from the repo root:  python3 art/ore-looks/draw_faces.py
It rewrites art/ore-looks/faces/*.png (for uploading, if ever needed) and
src/client/OreDrawings/*.txt (what the game decodes). Needs numpy and Pillow.

Each face is drawn at 512 px, scaled to 256 px, reduced to a small palette and stored as
run-length rows (the same tape layout as BreakerDrawings in the Starfall opening).
"""
import base64
import json
import math
import struct
import sys
import numpy as np
from PIL import Image
from core import Tex, pal_at, hexrgb, LIGHT, to255, blob
from shapes import SHAPES, glowcol

INK = hexrgb("1A141F")
DRAW = 512
SIZE = 256
COLORS = 32
RANK = {"Common": 1, "Uncommon": 2, "Rare": 3, "Epic": 4, "Legendary": 5, "Mythic": 6, "Celestial": 7}


class Style:
    """Flat cel colour with a shadow rim, a highlight and a thick ink outline."""

    w = 0.018

    def ow(self, t, edge=True):
        return max(2, int((self.w if edge else self.w * 0.6) * t.n))

    def dome(self, t, pts, pal, rng, lift=0.35, glow=None):
        pts = np.asarray(pts, float)
        c = pts.mean(0)
        r = float(np.mean(np.linalg.norm(pts - c, axis=1)))
        t.poly(pts, pal_at(pal, 0.22), glow=glow)
        lit = c + (pts - c) * 0.84 + LIGHT * r * 0.12
        t.poly(lit, pal_at(pal, 0.55))
        hi = c + LIGHT * r * 0.42
        t.poly(blob(hi, r * 0.3, 7, rng, 0.2, aspect=1.35), pal_at(pal, 0.92))
        t.d.polygon(t.P(pts), outline=to255(INK), width=self.ow(t))

    def flat(self, t, pts, col, edge=True, glow=None):
        t.poly(pts, col, glow=glow)
        t.d.polygon(t.P(pts), outline=to255(INK), width=self.ow(t, edge))

    def wire(self, t, paths, pal):
        for path in paths:
            t.line(path, INK, 0.06)
        for path in paths:
            t.line(path, pal_at(pal, 0.5), 0.034)

    def spark(self, t, c, r, ore):
        if RANK[ore["rarity"]] >= 3:
            t.sparkle(c, r * 1.2, fill="FFFFFF", outline=to255(INK), width=4)

    def crack(self, t, pts, ore):
        t.line(pts, INK, 0.02)
        g = glowcol(ore)
        if g is not None:
            t.line(pts, g * 0.45 + 0.55, 0.008)

    def etch(self, t, pts, col, ore):
        t.line(pts, INK, 0.005)


STYLE = Style()


def ribbon(path, widths):
    path = np.asarray(path, float)
    left, right = [], []
    for i, p in enumerate(path):
        a = path[max(i - 1, 0)]
        b = path[min(i + 1, len(path) - 1)]
        d = b - a
        nrm = np.array([-d[1], d[0]]) / (np.linalg.norm(d) + 1e-9)
        left.append(p + nrm * widths[i])
        right.append(p - nrm * widths[i])
    return left + right[::-1], left, right


def vein(t, ore, rng, style):
    """A thick winding vein with nodules and a crust along its banks (Copper, Silver)."""
    pal = ore["pal"]
    path = [(0.06, 0.74), (0.24, 0.62), (0.4, 0.66), (0.55, 0.48), (0.7, 0.42), (0.82, 0.24), (0.95, 0.2)]
    path = [(x + rng.uniform(-0.02, 0.02), y + rng.uniform(-0.03, 0.03)) for x, y in path]
    widths = [0.065, 0.095, 0.085, 0.115, 0.095, 0.08, 0.06]
    poly, left, right = ribbon(path, widths)
    style.flat(t, poly, pal_at(pal, 0.45))
    t.line([(x + LIGHT[0] * 0.02, y + LIGHT[1] * 0.02) for x, y in path[1:-1]], pal_at(pal, 0.92), 0.016)
    t.line([(x - LIGHT[0] * 0.024, y - LIGHT[1] * 0.024) for x, y in path[1:-1]], pal_at(pal, 0.12), 0.012)
    if "extra" in ore:
        crust = ore["extra"]
        for i, side in ((1, left), (2, right), (4, left), (5, right)):
            c = side[i]
            style.flat(t, blob(c, 0.075, 8, rng, 0.3), pal_at(crust, 0.45), edge=False)
            t.ellipse((c[0] - 0.012, c[1] - 0.014), 0.018, pal_at(crust, 1.0))
    for (cx, cy), r in ((path[3], 0.17), (path[1], 0.11), (path[5], 0.1)):
        style.dome(t, blob((cx, cy), r, 8, rng, 0.16), pal, rng, lift=0.45)
    style.spark(t, (path[3][0] - 0.05, path[3][1] - 0.07), 0.05, ore)


def nugget(t, ore, rng, style):
    """One big shiny nugget with satellites and flecks (Gold)."""
    pal = ore["pal"]
    for _ in range(10):
        c = (rng.uniform(0.12, 0.88), rng.uniform(0.12, 0.88))
        t.ellipse(c, rng.uniform(0.006, 0.012), pal_at(pal, 0.75))
    for cx, cy, r in [(0.43, 0.45, 0.27), (0.79, 0.72, 0.1), (0.77, 0.25, 0.075), (0.18, 0.8, 0.07)]:
        pts = blob((cx, cy), r, 12, rng, 0.13)
        style.dome(t, pts, pal, rng, lift=0.55)
        hc = (cx + LIGHT[0] * r * 0.42, cy + LIGHT[1] * r * 0.42)
        t.poly(blob(hc, r * 0.26, 7, rng, 0.25, aspect=1.4), pal_at(pal, 1.0))
    style.spark(t, (0.33, 0.3), 0.075, ore)
    style.spark(t, (0.8, 0.62), 0.04, ore)


def chunks(t, ore, rng, style):
    """Angular steel chunks with rust stains, in flat cel colour."""
    pal = ore["pal"]
    rust = [hexrgb(c) for c in ore.get("rust", [])]
    for i, (cx, cy, r) in enumerate([(0.42, 0.45, 0.27), (0.78, 0.74, 0.12), (0.77, 0.24, 0.1), (0.17, 0.82, 0.075)]):
        pts = blob((cx, cy), r, 6, rng, 0.1, rot=rng.uniform(0, 1))
        t.poly(pts, pal_at(pal, 0.25))
        t.poly([(cx, cy)] + list(pts[4:6]) + [pts[0]], pal_at(pal, 0.45))
        t.poly([(cx + LIGHT[0] * r * 0.15, cy + LIGHT[1] * r * 0.15)] + list(pts[1:4]), pal_at(pal, 0.7))
        t.poly([(cx + LIGHT[0] * r * 0.15, cy + LIGHT[1] * r * 0.15), pts[3], pts[4]], pal_at(pal, 0.92))
        for k in range(3 if i == 0 else 1):
            off = -LIGHT * r * rng.uniform(0.15, 0.4) + rng.uniform(-0.4, 0.4, 2) * r * 0.5
            rc = (cx + off[0], cy + off[1])
            t.poly(blob(rc, r * rng.uniform(0.24, 0.34), 8, rng, 0.35), rust[k % len(rust)])
        t.d.polygon(t.P(pts), outline=to255(INK), width=style.ow(t))


def outlined_root(t, pts, width):
    """An outlined root: a tan line inside a thicker ink line."""
    t.line(pts, INK, width * 1.9)
    t.line(pts, hexrgb("C9A27A"), width)


def crumbs(t, host, rng, count):
    for _ in range(count):
        c = (rng.uniform(0.07, 0.93), rng.uniform(0.07, 0.93))
        t.ellipse(c, rng.uniform(0.006, 0.013), host * rng.choice([0.68, 0.78]))


def dirt(t, ore, rng, style):
    """Five clearly different dirt faces, so a dug wall doesn't repeat."""
    host = hexrgb(ore["host"])
    variant = ore["variant"]
    pal = ore["pal"]
    if variant == 1:  # a scatter of pebbles
        crumbs(t, host, rng, 24)
        for _ in range(5):
            c = (rng.uniform(0.15, 0.85), rng.uniform(0.15, 0.85))
            style.dome(t, blob(c, rng.uniform(0.04, 0.075), 7, rng, 0.2, aspect=1.35), pal, rng)
    elif variant == 2:  # roots reaching down from above
        crumbs(t, host, rng, 14)
        for x0 in (0.28, 0.66):
            x = x0 + rng.uniform(-0.05, 0.05)
            main = [(x, 0.0), (x + 0.04, 0.2), (x - 0.03, 0.42), (x + 0.02, 0.62)]
            outlined_root(t, main, 0.016)
            for k in (1, 2):
                a = main[k]
                side = 1 if k == 1 else -1
                outlined_root(t, [a, (a[0] + side * 0.12, a[1] + 0.07), (a[0] + side * 0.18, a[1] + 0.16)], 0.009)
        style.dome(t, blob((0.5, 0.82), 0.05, 7, rng, 0.2, aspect=1.4), pal, rng)
    elif variant == 3:  # a darker clay band with stones caught in it
        crumbs(t, host, rng, 16)
        xs = np.linspace(0, 1, 9)
        top = [(x, 0.44 + 0.03 * math.sin(x * 7 + 1)) for x in xs]
        bottom = [(x, 0.62 + 0.03 * math.sin(x * 6 + 2)) for x in xs]
        t.poly(top + bottom[::-1], host * 0.8)
        t.line(top, INK, 0.009)
        t.line(bottom, INK, 0.009)
        for x in (0.22, 0.55, 0.8):
            style.dome(t, blob((x, 0.53 + rng.uniform(-0.02, 0.02)), 0.04, 6, rng, 0.2, aspect=1.4), pal, rng)
    elif variant == 4:  # one big half-buried rock
        crumbs(t, host, rng, 18)
        style.dome(t, blob((0.62, 0.62), 0.2, 9, rng, 0.12, aspect=1.25), pal, rng)
        style.dome(t, blob((0.26, 0.3), 0.045, 6, rng, 0.2), pal, rng)
    else:  # a worm burrow and a crack
        crumbs(t, host, rng, 20)
        burrow = [(0.12, 0.3), (0.3, 0.38), (0.42, 0.3), (0.58, 0.42), (0.72, 0.36), (0.86, 0.5)]
        t.line(burrow, INK, 0.05)
        t.line(burrow, host * 0.62, 0.032)
        crack = [(0.7, 1.0), (0.66, 0.86), (0.72, 0.76), (0.68, 0.68)]
        t.line(crack, INK, 0.008)


def stone(t, ore, rng, style):
    for _ in range(2):
        p = np.array([rng.uniform(0.15, 0.85), rng.choice([0.03, 0.97])])
        pts = [tuple(p)]
        ang = -math.pi / 2 if p[1] > 0.5 else math.pi / 2
        for _ in range(3):
            ang += rng.uniform(-0.7, 0.7)
            p = np.clip(p + 0.1 * np.array([math.cos(ang), math.sin(ang)]), 0.04, 0.96)
            pts.append(tuple(p))
        t.line(pts, INK, 0.011)
    for _ in range(2):
        c = (rng.uniform(0.2, 0.8), rng.uniform(0.2, 0.8))
        style.dome(t, blob(c, rng.uniform(0.03, 0.05), 6, rng, 0.2), ore["pal"], rng)


def hexes(t, ore, rng, style):
    """Cut hexagonal emeralds seen end on, in flat cel colour."""
    pal = ore["pal"]
    for cx, cy, r, rot in [(0.4, 0.42, 0.21, 0.1), (0.72, 0.7, 0.13, 0.4), (0.24, 0.76, 0.09, 0.2), (0.76, 0.27, 0.08, 0.0)]:
        pts = [(cx + r * math.cos(rot + i * math.pi / 3), cy + r * math.sin(rot + i * math.pi / 3)) for i in range(6)]
        style.dome(t, pts, pal, rng)
    style.spark(t, (0.31, 0.3), 0.055, ore)


DRAWN = {"hex": hexes, "chunks": chunks, "dirt": dirt, "stone": stone, "vein": vein, "nugget": nugget}

# Warm, ore-coloured rock like the Storybook Ink concept. Stone is drawn light and neutral:
# the game tints it with the stone grade's colour.
FACES = [
    dict(name="Dirt", rarity="Common", host="9A6440", shape="dirt", pal=["5E544B", "8E8174", "BEB2A2", "ECE4D8"], variants=5, tones=[1.0, 0.96, 1.03, 0.98, 1.02]),
    dict(name="Stone", rarity="Common", host="E6E7EA", shape="stone", pal=["8C8E96", "B4B6BD", "D8D9DE", "FFFFFF"], variants=3),
    dict(name="Coal", rarity="Common", host="A3A6B0", shape="lumps", pal=["15161C", "2C2E37", "4C4F5A", "A9ADB8"]),
    dict(name="Copper", rarity="Uncommon", host="A9785B", shape="vein", pal=["6A2F14", "C2652F", "F0A266", "FFE1C2"], extra=["1F7A66", "48B496", "9BE6CC"]),
    dict(name="Iron", rarity="Uncommon", host="A79F96", shape="chunks", pal=["39414D", "6C7A8C", "AFBCCB", "F2F6FA"], rust=["A2501F", "D27C35"]),
    dict(name="Gold", rarity="Rare", host="8A6A45", shape="nugget", pal=["7A3F02", "D8921A", "FFD45A", "FFF7D6"]),
    dict(name="Diamond", rarity="Epic", host="7898A8", shape="octa", pal=["3A86A6", "8DE2F2", "D6FCFF", "FFFFFF"], glow="9FF3FF"),
    dict(name="Emerald", rarity="Legendary", host="5F8B70", shape="hex", pal=["0D5434", "238553", "4CCE72", "C0FFB8"], glow="7DFF95"),
    dict(name="Amethyst", rarity="Mythic", host="806894", shape="geode", pal=["43206F", "7943B4", "B37BE8", "F4DDFF"], glow="C98CFF", matrix="5D4A70"),
    dict(name="Sapphire", rarity="Mythic", host="6176A6", shape="barrel", pal=["16287A", "3050B0", "6A9DFF", "D6E5FF"], glow="7FA8FF"),
    dict(name="Emberglass", rarity="Mythic", host="7E5866", shape="shards", pal=["1E1219", "492F47", "BD5266", "FFC0A0"], glow="FF7A6B"),
    dict(name="Starfall", rarity="Celestial", host="6C5E98", shape="star", pal=["5A3FA0", "9577D4", "DDB4FF", "FFF7EC"], glow="EBCBFF"),
]


def draw(face, variant):
    rng = np.random.default_rng(sum(map(ord, face["name"])) * 7919 + variant * 104729)
    host = hexrgb(face["host"]) * face.get("tones", [1.0] * 5)[variant - 1]
    t = Tex(host, DRAW)
    # A cel shadow corner with hatching, as in the concept. Dirt and stone move it around
    # (or leave it out) so a dug wall doesn't show the same corner on every block.
    corner = ["bl", "tr", "br", None, "tl"][variant - 1] if face.get("variants", 1) > 1 else "bl"
    if corner:
        flip = lambda pts: [((1 - x) if "r" in corner else x, (1 - y) if "t" in corner else y) for x, y in pts]
        t.poly(flip([(0, 0.7), (0.3, 1.0), (0, 1.0)]), host * 0.86)
        for k in range(7):
            a = 0.62 + k * 0.055
            t.line(flip([(0.0, a), (min(a * 0.3, 0.3), min(1.0, a + a * 0.3))]), INK, 0.006)
    if face["shape"] not in ("dirt", "stone"):
        for _ in range(2):
            p = np.array([rng.uniform(0.08, 0.92), rng.choice([0.03, 0.97])])
            pts = [tuple(p)]
            ang = -math.pi / 2 if p[1] > 0.5 else math.pi / 2
            for _ in range(2):
                ang += rng.uniform(-0.7, 0.7)
                p = np.clip(p + 0.08 * np.array([math.cos(ang), math.sin(ang)]), 0.03, 0.97)
                pts.append(tuple(p))
            t.line(pts, INK, 0.009)
    shape = DRAWN.get(face["shape"]) or SHAPES[face["shape"]]
    face = dict(face, matrix=face.get("matrix", face["host"]), variant=variant)
    shape(t, face, rng, STYLE)
    t.d.rectangle([0, 0, DRAW - 1, DRAW - 1], outline=to255(INK), width=int(0.035 * DRAW))
    return t.img.resize((SIZE, SIZE), Image.LANCZOS)


def tape(img):
    """Palette + run-length rows: per row u16 y, u16 x, u8 count, then count x (u16 run, u8 index)."""
    q = img.quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    raw = q.getpalette()[: COLORS * 3]
    idx = np.asarray(q)
    used = sorted(set(idx.flatten().tolist()))
    remap = {old: new for new, old in enumerate(used)}
    palette = ["%02X%02X%02X" % tuple(raw[i * 3 : i * 3 + 3]) for i in used]
    out = bytearray()
    for y in range(idx.shape[0]):
        row = [remap[v] for v in idx[y].tolist()]
        runs, start = [], 0
        for x in range(1, len(row) + 1):
            if x == len(row) or row[x] != row[start]:
                runs.append((x - start, row[start]))
                start = x
        x = 0
        for i in range(0, len(runs), 255):
            chunk = runs[i : i + 255]
            out += struct.pack("<HHB", y, x, len(chunk))
            for length, color in chunk:
                out += struct.pack("<HB", length, color)
                x += length
    return q.convert("RGB"), {"width": idx.shape[1], "height": idx.shape[0], "palette": palette, "tape": base64.b64encode(bytes(out)).decode()}


if __name__ == "__main__":
    import os
    root = os.path.dirname(os.path.abspath(__file__))
    out_png = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "faces")
    out_txt = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, "..", "..", "src", "client", "OreDrawings")
    total = 0
    sheet = []
    for face in FACES:
        for v in range(1, face.get("variants", 1) + 1):
            img = draw(face, v)
            quant, data = tape(img)
            key = face["name"] + ("-%d" % v if face.get("variants", 1) > 1 else "")
            quant.save(f"{out_png}/{key}.png")
            text = json.dumps(data, separators=(",", ":"))
            open(f"{out_txt}/{key}.txt", "w").write(text)
            total += len(text)
            sheet.append((key, quant, len(data["palette"]), len(text)))
    cols = 6
    rows = math.ceil(len(sheet) / cols)
    board = Image.new("RGB", (cols * 270, rows * 290), (240, 232, 214))
    from PIL import ImageDraw
    d = ImageDraw.Draw(board)
    for i, (key, im, pc, n) in enumerate(sheet):
        r, c = divmod(i, cols)
        board.paste(im, (c * 270 + 7, r * 290 + 7))
        d.text((c * 270 + 10, r * 290 + 268), f"{key}  {pc} colours  {n // 1024} KB", fill=(30, 20, 20))
    board.save(os.path.join(root, "faces-sheet.jpg"), quality=90)
    print("faces", len(sheet), "total KB", total // 1024)
