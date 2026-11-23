"""Draws the Storybook Ink face images the game puts on every open block face.

Run from the repo root:  python3 art/ore-looks/draw_faces.py
It rewrites art/ore-looks/faces/*.png (for uploading, if ever needed) and
src/client/OreDrawings/*.txt (what the game decodes). Every ore also gets a pieces image: just
its ore pieces on a clear background (art/ore-looks/pieces, src/client/OrePieces), which the game
raises a little off the face. Ores that glow (Gold and up) get a glow image too: the same pieces
with a neon filling and a soft halo (art/ore-looks/glow, src/client/OreGlow). The game shows it
self-lit over the raised pieces, so the glow comes from the ore and not the rock. Needs numpy
and Pillow.

Each face is drawn at 512 px, scaled to 256 px, reduced to a small palette and stored as
run-length rows (the same tape layout as BreakerDrawings in the Starfall opening).
"""
import base64
import colorsys
import json
import math
import struct
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from core import Tex, pal_at, hexrgb, LIGHT, to255, blob
from shapes import SHAPES, glowcol

INK = hexrgb("1A141F")
DRAW = 512
SIZE = 256
COLORS = 32
KEY = (255, 0, 255)  # background of a glow image while drawing; becomes transparent
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


class GlowStyle(Style):
    """For glow images: cracks stay in the rock, so only the ore pieces glow and stand out."""

    def crack(self, t, pts, ore):
        pass


GLOW_STYLE = GlowStyle()


def malachite(t, ore, rng, style):
    """Copper nuggets sitting in cradles of banded green malachite, the rock copper is found in."""
    pal, green = ore["pal"], ore["extra"]
    for cx, cy, r in [(0.43, 0.45, 0.2), (0.76, 0.74, 0.11), (0.75, 0.25, 0.085), (0.2, 0.78, 0.08)]:
        # the cradle sits a little toward the shadow side, so it shows as a crescent
        oc = np.array([cx - LIGHT[0] * r * 0.28, cy - LIGHT[1] * r * 0.28])
        outer = blob(tuple(oc), r * 1.32, 12, rng, 0.08)
        t.poly(outer, pal_at(green, 0.15))
        for scale, tone in ((1.18, 0.55), (1.06, 0.3), (0.95, 0.8)):
            band = [tuple(oc + (np.asarray(p) - oc) * (scale / 1.32) + rng.uniform(-0.006, 0.006, 2)) for p in outer]
            t.poly(band, pal_at(green, tone))
        t.d.polygon(t.P(outer), outline=to255(INK), width=style.ow(t))
        style.dome(t, blob((cx, cy), r, 10, rng, 0.13), pal, rng, lift=0.5)
        hc = (cx + LIGHT[0] * r * 0.42, cy + LIGHT[1] * r * 0.42)
        t.poly(blob(hc, r * 0.2, 7, rng, 0.25, aspect=1.4), pal_at(pal, 1.0))


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
    """Angular steel chunks in flat cel colour."""
    pal = ore["pal"]
    rust = [hexrgb(c) for c in ore.get("rust", [])]
    for i, (cx, cy, r) in enumerate([(0.42, 0.45, 0.27), (0.78, 0.74, 0.12), (0.77, 0.24, 0.1), (0.17, 0.82, 0.075)]):
        pts = blob((cx, cy), r, 6, rng, 0.1, rot=rng.uniform(0, 1))
        t.poly(pts, pal_at(pal, 0.25))
        t.poly([(cx, cy)] + list(pts[4:6]) + [pts[0]], pal_at(pal, 0.45))
        t.poly([(cx + LIGHT[0] * r * 0.15, cy + LIGHT[1] * r * 0.15)] + list(pts[1:4]), pal_at(pal, 0.7))
        t.poly([(cx + LIGHT[0] * r * 0.15, cy + LIGHT[1] * r * 0.15), pts[3], pts[4]], pal_at(pal, 0.92))
        for k in range(3 if i == 0 else 1) if rust else ():
            off = -LIGHT * r * rng.uniform(0.15, 0.4) + rng.uniform(-0.4, 0.4, 2) * r * 0.5
            rc = (cx + off[0], cy + off[1])
            t.poly(blob(rc, r * rng.uniform(0.24, 0.34), 8, rng, 0.35), rust[k % len(rust)])
        t.d.polygon(t.P(pts), outline=to255(INK), width=style.ow(t))


def crumbs(t, host, rng, count):
    for _ in range(count):
        c = (rng.uniform(0.07, 0.93), rng.uniform(0.07, 0.93))
        t.ellipse(c, rng.uniform(0.006, 0.013), host * rng.choice([0.68, 0.78]))


def dirt(t, ore, rng, style):
    """Plain dirt: flat colour with little dark specks, no stones or lines."""
    crumbs(t, hexrgb(ore["host"]), rng, 46)


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


DRAWN = {"hex": hexes, "chunks": chunks, "dirt": dirt, "stone": stone, "malachite": malachite, "nugget": nugget}

# Warm, ore-coloured rock like the Storybook Ink concept (Copper sits in cool grey-green rock so it
# stands apart from Dirt and Gold). Stone is drawn light and neutral:
# the game tints it with the stone grade's colour.
FACES = [
    dict(name="Dirt", rarity="Common", host="9A6440", shape="dirt", pal=["5E544B", "8E8174", "BEB2A2", "ECE4D8"], plain=True),
    dict(name="Stone", rarity="Common", host="E6E7EA", shape="stone", pal=["8C8E96", "B4B6BD", "D8D9DE", "FFFFFF"], variants=3),
    dict(name="Coal", rarity="Common", host="A3A6B0", shape="lumps", pal=["15161C", "2C2E37", "4C4F5A", "A9ADB8"]),
    dict(name="Copper", rarity="Uncommon", host="7D8C89", shape="malachite", pal=["5A1E10", "B5502E", "EA8862", "FFDCCB"], extra=["0B4A33", "1F7A52", "3FAE74", "8FE3AE"]),
    dict(name="Iron", rarity="Uncommon", host="A79F96", shape="chunks", pal=["39414D", "6C7A8C", "AFBCCB", "F2F6FA"]),
    dict(name="Gold", rarity="Rare", host="98784A", shape="nugget", pal=["7A3F02", "D8921A", "FFD45A", "FFF7D6"], glow="FFD27A"),
    dict(name="Diamond", rarity="Epic", host="7898A8", shape="octa", pal=["3A86A6", "8DE2F2", "D6FCFF", "FFFFFF"], glow="9FF3FF"),
    dict(name="Emerald", rarity="Legendary", host="5F8B70", shape="hex", pal=["0D5434", "238553", "4CCE72", "C0FFB8"], glow="7DFF95"),
    dict(name="Amethyst", rarity="Mythic", host="806894", shape="geode", pal=["43206F", "7943B4", "B37BE8", "F4DDFF"], glow="C98CFF", matrix="5D4A70"),
    dict(name="Sapphire", rarity="Mythic", host="6176A6", shape="barrel", pal=["16287A", "3050B0", "6A9DFF", "D6E5FF"], glow="7FA8FF"),
    dict(name="Emberglass", rarity="Mythic", host="7E5866", shape="shards", pal=["1E1219", "492F47", "BD5266", "FFC0A0"], glow="FF7A6B"),
    dict(name="Starfall", rarity="Celestial", host="6C5E98", shape="star", pal=["5A3FA0", "9577D4", "DDB4FF", "FFF7EC"], glow="EBCBFF"),
]


def draw(face, variant, layer=None):
    """A face drawing, or with `layer` "pieces" or "glow", just its ore pieces on a clear background."""
    rng = np.random.default_rng(sum(map(ord, face["name"])) * 7919 + variant * 104729)
    host = hexrgb(face["host"]) * face.get("tones", [1.0] * 5)[variant - 1]
    t = Tex(host, DRAW)
    # A cel shadow corner with hatching, as in the concept. Stone moves it around (or leaves
    # it out) so a dug wall doesn't show the same corner on every block. Plain dirt has none.
    corner = None if face.get("plain") else ["bl", "tr", "br", None, "tl"][variant - 1] if face.get("variants", 1) > 1 else "bl"
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
    if layer:
        # Same random draws as the face, but the ore pieces land on a key colour instead of rock.
        t.img = Image.new("RGB", (DRAW, DRAW), KEY)
        t.d = ImageDraw.Draw(t.img)
    shape = DRAWN.get(face["shape"]) or SHAPES[face["shape"]]
    face = dict(face, matrix=face.get("matrix", face["host"]), variant=variant)
    shape(t, face, rng, GLOW_STYLE if layer else STYLE)
    if layer == "pieces":
        return pieces_layer(t.img)
    if layer == "glow":
        return glow_layer(t.img, hexrgb(face["glow"]))
    t.d.rectangle([0, 0, DRAW - 1, DRAW - 1], outline=to255(INK), width=int(0.035 * DRAW))
    return t.img.resize((SIZE, SIZE), Image.LANCZOS)


def clear_image(rgb, alpha):
    rgba = (np.dstack([rgb, alpha]) * 255).round().astype(np.uint8)
    out = Image.fromarray(rgba).convert("RGBa").resize((SIZE, SIZE), Image.LANCZOS)
    return out.convert("RGBA")


def piece_mask(img):
    a = np.asarray(img).astype(int)
    return a, ~((a[..., 0] == KEY[0]) & (a[..., 1] == KEY[1]) & (a[..., 2] == KEY[2]))


def pieces_layer(img):
    """Keep only the ore pieces, in their drawn colours, and clear the rest."""
    a, piece = piece_mask(img)
    out = clear_image(a / 255, piece.astype(float))
    out.info["glints"] = glint_spots(a, piece)
    return out


def glint_spots(a, piece, count=4):
    """A few spots on the ore pieces that can catch a glint: the brightest highlights, spread out.

    Returned as [x, y] in 0..1 image space (x right, y down)."""
    lum = a.mean(-1) / 255
    ys, xs = np.nonzero(piece & (lum > 0.72))
    if len(xs) < count:
        ys, xs = np.nonzero(piece)
    if len(xs) == 0:
        return []
    pts = np.stack([xs, ys], 1).astype(float)
    order = np.argsort(-lum[ys, xs])
    chosen = [pts[order[0]]]
    while len(chosen) < count:
        d = np.min([np.linalg.norm(pts - c, axis=1) for c in chosen], axis=0)
        far = int(np.argmax(d))
        if d[far] < DRAW * 0.08:
            break
        chosen.append(pts[far])
    return [[round(float(x) / DRAW, 3), round(float(y) / DRAW, 3)] for x, y in chosen]


def glow_layer(img, color):
    """The ore pieces with a neon filling, ink outlines kept dark, and a soft halo around them."""
    a, piece = piece_mask(img)
    c = a / 255
    ink = np.abs(a - np.array(to255(INK))).sum(-1) < 40
    # Neon: fill the pieces with a vivid version of the glow colour, keeping the drawing's light
    # and shade inside each piece, and its brightest highlights white.
    h, sat, _ = colorsys.rgb_to_hsv(*color)
    vivid = np.array(colorsys.hsv_to_rgb(h, min(1.0, sat * 1.6 + 0.15), 1.0))
    lum = c.mean(-1, keepdims=True)
    fill = vivid * (0.45 + 0.55 * lum)
    fill = fill + (1 - fill) * np.clip((lum - 0.78) * 3, 0, 1)
    rgb = np.where((piece & ~ink)[..., None], fill, np.where(piece[..., None], c, color[None, None, :]))
    mask = Image.fromarray((piece * 255).astype(np.uint8))
    halo = np.asarray(mask.filter(ImageFilter.GaussianBlur(DRAW * 0.035)), float) / 255
    halo = np.clip(halo * 1.4, 0, 1) * 0.65
    return clear_image(rgb, np.where(piece, 1.0, halo))


def tape(img, colors=COLORS):
    """Palette + run-length rows: per row u16 y, u16 x, u8 count, then count x (u16 run, u8 index)."""
    clear = img.mode == "RGBA"
    method = Image.Quantize.FASTOCTREE if clear else Image.Quantize.MEDIANCUT
    q = img.quantize(colors=colors, method=method, dither=Image.Dither.NONE)
    n = 4 if clear else 3
    raw = q.getpalette("RGBA" if clear else "RGB")[: colors * n]
    idx = np.asarray(q)
    used = sorted(set(idx.flatten().tolist()))
    remap = {old: new for new, old in enumerate(used)}
    palette = [("%02X" * n) % tuple(raw[i * n : i * n + n]) for i in used]
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
    return q.convert("RGBA" if clear else "RGB"), {"width": idx.shape[1], "height": idx.shape[0], "palette": palette, "tape": base64.b64encode(bytes(out)).decode()}


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
    # Pieces images for every ore, glow images for the ores that glow.
    for layer, folder, game_folder, colors in (("pieces", "pieces", "OrePieces", 32), ("glow", "glow", "OreGlow", 64)):
        png_dir = os.path.join(root, folder)
        txt_dir = os.path.join(out_txt, "..", game_folder)
        os.makedirs(png_dir, exist_ok=True)
        os.makedirs(txt_dir, exist_ok=True)
        layer_total = 0
        for face in FACES:
            if face["shape"] in ("dirt", "stone") or (layer == "glow" and "glow" not in face):
                continue
            img = draw(face, 1, layer=layer)
            quant, data = tape(img, colors=colors)
            if "glints" in img.info:
                data["glints"] = img.info["glints"]
            quant.save(f"{png_dir}/{face['name']}.png")
            text = json.dumps(data, separators=(",", ":"))
            open(f"{txt_dir}/{face['name']}.txt", "w").write(text)
            layer_total += len(text)
        print(layer, "images total KB", layer_total // 1024)
