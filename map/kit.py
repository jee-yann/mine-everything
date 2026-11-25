"""Stud-built geometry for the cove. Every structural block is Plastic with studs on all its
faces, so the engine tiles one world-scale stud over the whole island and nothing stretches."""

import copy
import math
import random
import xml.etree.ElementTree as ET

PLASTIC, SMOOTH, NEON, GLASS, METAL = 256, 272, 288, 1568, 1088
FACES = ("TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface")
STUD = 3


def prop(item, key):
    return item.find(f'./Properties/*[@name="{key}"]')


def name(item):
    return prop(item, "Name").text


def field(item, kind, key, value):
    el = prop(item, key)
    if el is None:
        el = ET.SubElement(item.find("Properties"), kind, name=key)
    el.text = str(value)
    return el


def xyz(item, key):
    el = prop(item, key)
    return [float(el.find(a).text) for a in "XYZ"]


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def apply(m, v):
    return [sum(m[i][k] * v[k] for k in range(3)) for i in range(3)]


def rx(d):
    c, s = math.cos(math.radians(d)), math.sin(math.radians(d))
    return [[1, 0, 0], [0, c, -s], [0, s, c]]


def ry(d):
    c, s = math.cos(math.radians(d)), math.sin(math.radians(d))
    return [[c, 0, s], [0, 1, 0], [-s, 0, c]]


def rz(d):
    c, s = math.cos(math.radians(d)), math.sin(math.radians(d))
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


I3 = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]


# What stays bare: water, cut crystal, lettered boards, small inlays.
BARE = {"Falling water", "Falls lip", "Current", "Whitewater", "Spring run", "Falls bed", "Plunge pool", "Pool water", "Spill water", "Lagoon", "Surf line",
        "Lily pad", "Lily", "Reed", "Crystal facet", "Crystal point", "Compass needle", "Adit dark", "Shop sign", "Sign board", "Mine sign"}


class Frame:
    """A place to build from: a position and a turn. +Z is the front of whatever stands there."""

    def __init__(self, x=0, y=0, z=0, yaw=0, m=None):
        self.o, self.m = [x, y, z], m or ry(yaw)

    def at(self, p):
        q = apply(self.m, p)
        return [self.o[i] + q[i] for i in range(3)]

    def sub(self, x=0, y=0, z=0, yaw=0):
        f = Frame()
        f.o, f.m = self.at([x, y, z]), matmul(self.m, ry(yaw))
        return f


WORLD = Frame()


class Builder:
    def __init__(self, seed=4107):
        self.rng = random.Random(seed)
        self.doc = ET.Element("roblox", version="4")
        self.ref = 0
        self.root = self.model(self.doc, "CitrineCove")
        # Plan-view footprints of everything solid, for planting to keep clear of.
        self.solids = []
        # Every part with the object it belongs to, so a prop can be fitted among them.
        self.boxes, self.cells = [], {}
        self.owner, self.owners = 0, 0
        self.shift = [0.0, 0.0, 0.0]
        self.queue, self.trial = [], None
        self.dropped = {}

    def item(self, parent, cl, label):
        self.ref += 1
        it = ET.SubElement(parent, "Item", {"class": cl, "referent": f"M{self.ref}"})
        ET.SubElement(it, "Properties")
        field(it, "string", "Name", label)
        return it

    def model(self, parent, label):
        return self.item(parent, "Model", label)

    def part(self, parent, label, pos, size, color, fr=WORLD, rot=None, cl="Part", mat=PLASTIC, studs=None,
             solid=True, shadow=True, alpha=0, shine=0, shape=None, query=None):
        size = [max(0.05, s) for s in size]
        it = self.item(parent, cl, label)
        at, m = fr.at(pos), matmul(fr.m, rot) if rot else fr.m
        at = [at[i] + self.shift[i] for i in range(3)]
        field(it, "bool", "Anchored", "true")
        field(it, "bool", "CanCollide", "true" if solid else "false")
        if not solid:
            field(it, "bool", "CanTouch", "false")
            field(it, "bool", "CanQuery", "true" if query else "false")
        field(it, "bool", "CastShadow", "true" if shadow else "false")
        v = ET.SubElement(it.find("Properties"), "Vector3", name="size")
        for k, a in zip("XYZ", size):
            ET.SubElement(v, k).text = f"{a:.4f}"
        cf = ET.SubElement(it.find("Properties"), "CoordinateFrame", name="CFrame")
        for k, a in zip("XYZ", at):
            ET.SubElement(cf, k).text = f"{a:.4f}"
        for r in range(3):
            for c in range(3):
                ET.SubElement(cf, f"R{r}{c}").text = f"{m[r][c]:.7f}"
        field(it, "Color3uint8", "Color3uint8", 0xFF000000 | int(color, 16))
        x, y, z = size
        spans = {"TopSurface": (x, z), "BottomSurface": (x, z), "LeftSurface": (y, z), "RightSurface": (y, z),
                 "FrontSurface": (x, y), "BackSurface": (x, y)}
        # Anything built wears studs wherever a face can show one.
        on = label not in BARE and mat not in (NEON, GLASS) and shape is None and not alpha and max(min(v) for v in spans.values()) >= 0.95
        if on:
            mat = PLASTIC
        field(it, "token", "Material", mat)
        for face in FACES:
            # A face under one stud across cannot show a whole one.
            field(it, "token", face, STUD if on and min(spans[face]) >= 0.95 else 0)
        if alpha:
            field(it, "float", "Transparency", alpha)
        if shine:
            field(it, "float", "Reflectance", shine)
        if shape is not None:
            field(it, "token", "shape", shape)
        self.note(parent, it, label, at, m, size, cl, solid, alpha)
        if solid:
            hx = abs(m[0][0]) * x / 2 + abs(m[0][1]) * y / 2 + abs(m[0][2]) * z / 2
            hy = abs(m[1][0]) * x / 2 + abs(m[1][1]) * y / 2 + abs(m[1][2]) * z / 2
            hz = abs(m[2][0]) * x / 2 + abs(m[2][1]) * y / 2 + abs(m[2][2]) * z / 2
            self.solids.append((at[0] - hx, at[1] - hy, at[2] - hz, at[0] + hx, at[1] + hy, at[2] + hz))
        return it

    def box(self, parent, label, x0, x1, y0, y1, z0, z1, color, **k):
        return self.part(parent, label, [(x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2], [x1 - x0, y1 - y0, z1 - z0], color, **k)

    def note(self, parent, it, label, at, m, size, cl, solid, alpha=0):
        h = [s / 2 for s in size]
        e = [sum(abs(m[i][k]) * h[k] for k in range(3)) for i in range(3)]
        rec = dict(label=label, at=at, m=m, h=h, lo=[at[i] - e[i] for i in range(3)], hi=[at[i] + e[i] for i in range(3)], cl=cl, solid=solid,
                   owner=self.owner, item=it, parent=parent)
        if self.trial is not None:
            self.trial.append(rec)
        elif alpha < 0.9:
            self.settle(rec)

    def settle(self, rec):
        n = len(self.boxes)
        self.boxes.append(rec)
        for x in range(int(rec["lo"][0] // 8), int(rec["hi"][0] // 8) + 1):
            for z in range(int(rec["lo"][2] // 8), int(rec["hi"][2] // 8) + 1):
                self.cells.setdefault((x, z), []).append(n)

    def near(self, rec):
        seen = set()
        for x in range(int(rec["lo"][0] // 8), int(rec["hi"][0] // 8) + 1):
            for z in range(int(rec["lo"][2] // 8), int(rec["hi"][2] // 8) + 1):
                seen.update(self.cells.get((x, z), ()))
        return (self.boxes[n] for n in seen)

    def place(self, label, fn, reach=3.2, must=False):
        """Queue a prop. It is built last, moved a little if it would stand in something, and left out
        if there is nowhere for it."""
        self.queue.append((label, fn, reach, must))

    def finish(self):
        queue, self.queue = self.queue, []
        for label, fn, reach, must in queue:
            spots = [(0.0, 0.0)]
            for r in (0.8, 1.6, 2.4, reach) if reach else ():
                spots += [(r * math.cos(a * math.pi / 4), r * math.sin(a * math.pi / 4)) for a in range(8)]
            best = None
            for dx, dz in spots:
                kept, ref, state = len(self.solids), self.ref, self.rng.getstate()
                self.trial, self.shift = [], [dx, 0.0, dz]
                fn()
                made, self.trial, self.shift = self.trial, None, [0.0, 0.0, 0.0]
                if reach > 0:
                    # Stand it on whatever is really under it.
                    base = min(made, key=lambda q: q["lo"][1])
                    foot, ground = base["lo"][1], self.ground(base["at"][0], base["at"][2], base["lo"][1] + 1.2, base["owner"])
                    if ground is not None and 0.02 < abs(ground - foot) < 1.2 and not (0 < ground - foot < 0.45 and len(made) > 1 and label in ("rock", "bush", "cluster", "ore_pile")):
                        for rec in made:
                            rec["parent"].remove(rec["item"])
                        del self.solids[kept:]
                        self.rng.setstate(state)
                        self.trial, self.shift = [], [dx, ground - foot, dz]
                        fn()
                        made, self.trial, self.shift = self.trial, None, [0.0, 0.0, 0.0]
                bad = self.worst(made, dx != 0 or dz != 0, reach > 0)
                if bad is None and label in LEVEL and not self.level(made):
                    bad = 5.0
                if bad is None:
                    for rec in made:
                        self.settle(rec)
                    best = None
                    break
                if best is None or bad < best[0]:
                    best = (bad, dx, dz)
                for rec in made:
                    rec["parent"].remove(rec["item"])
                del self.solids[kept:]
                self.rng.setstate(state)
            if best is not None:
                self.dropped[label] = self.dropped.get(label, 0) + 1
                if must:
                    self.trial, self.shift = [], [0.0, 0.0, 0.0]
                    fn()
                    made, self.trial = self.trial, None
                    for rec in made:
                        self.settle(rec)
                    print("tight:", label, [round(v, 1) for v in made[0]["at"]], round(best[0], 2))

    def level(self, made):
        """True if every foot of a prop stands on something."""
        foot = min(r["lo"][1] for r in made)
        for r in made:
            if r["lo"][1] > foot + 0.1:
                continue
            for s in (-0.7, 0.7):
                for t in (-0.7, 0.7):
                    x, z = (r["at"][i] + r["m"][i][0] * r["h"][0] * s + r["m"][i][2] * r["h"][2] * t for i in (0, 2))
                    y = self.ground(x, z, foot + 0.6, r["owner"])
                    if y is None or abs(y - foot) > 0.2:
                        return False
        return True

    def ground(self, x, z, high, owner):
        """The top of the first solid thing below (x, high, z)."""
        best = None
        for n in self.cells.get((int(x // 8), int(z // 8)), ()):
            q = self.boxes[n]
            if not q["solid"] or q["owner"] == owner or q["lo"][1] > high:
                continue
            d = [x - q["at"][0], 400 - q["at"][1], z - q["at"][2]]
            ol = [sum(q["m"][i][k] * d[i] for i in range(3)) for k in range(3)]
            dl = [-q["m"][1][k] for k in range(3)]
            near, far = -1e9, 1e9
            planes = [(ol[k] - q["h"][k], dl[k]) for k in range(3)] + [(-ol[k] - q["h"][k], -dl[k]) for k in range(3)]
            if q["cl"] == "WedgePart":
                planes.append((ol[1] * q["h"][2] - ol[2] * q["h"][1], dl[1] * q["h"][2] - dl[2] * q["h"][1]))
            for a, c in planes:
                if abs(c) < 1e-9:
                    if a > 0:
                        far = -1e9
                elif c > 0:
                    far = min(far, -a / c)
                else:
                    near = max(near, -a / c)
            if near < far:
                y = 400 - near
                if y <= high and (best is None or y > best):
                    best = y
        return best

    def worst(self, made, moved, rooted=True):
        """How deep a prop stands in its neighbours. None if it fits and has ground under it."""
        deep = 0
        foot = min(r["lo"][1] for r in made)
        for p in made:
            for q in self.near(p):
                if q["owner"] == p["owner"]:
                    continue
                if any(p["lo"][k] >= q["hi"][k] + 0.02 or q["lo"][k] >= p["hi"][k] + 0.02 for k in range(3)):
                    continue
                # Rooted in the ground it stands on.
                if rooted and q["hi"][1] - foot < 0.8:
                    continue
                d = penetration(p, q)
                if d > -0.02:
                    deep = max(deep, d, 0.01)
        if deep == 0 and moved:
            base = min(made, key=lambda r: r["lo"][1])
            x, z = base["at"][0], base["at"][2]
            for dx, dz in ((0, 0), (0.8, 0), (-0.8, 0), (0, 0.8), (0, -0.8)):
                if not any(inside(q, (x + dx, base["lo"][1] - 0.15 + 0.5, z + dz)) or inside(q, (x + dx, base["lo"][1] - 0.35, z + dz)) for q in self.near(base) if q["solid"] and q["owner"] != base["owner"]):
                    return 9.0
        return deep or None

    def pad(self, parent, label, x, z, w, d, y0, y1, color, corner=3, fr=WORLD, yaw=0, **k):
        """A chamfered slab. Three boxes and four upright wedges."""
        f = fr.sub(x, 0, z, yaw)
        h, c = y1 - y0, min(corner, w / 2 - 0.5, d / 2 - 0.5)
        y = (y0 + y1) / 2
        self.part(parent, label, [0, y, 0], [w - 2 * c, h, d], color, f, **k)
        for s in (-1, 1):
            self.part(parent, label, [s * (w / 2 - c / 2), y, 0], [c, h, d - 2 * c], color, f, **k)
            for t in (-1, 1):
                # Upright wedge. Local Y points out along x, local Z in along z.
                ly, lz = [s, 0, 0], [0, 0, -t]
                lx = [ly[1] * lz[2] - ly[2] * lz[1], ly[2] * lz[0] - ly[0] * lz[2], ly[0] * lz[1] - ly[1] * lz[0]]
                rot = [[lx[i], ly[i], lz[i]] for i in range(3)]
                self.part(parent, label, [s * (w / 2 - c / 2), y, t * (d / 2 - c / 2)], [h, c, c], color, f, rot, "WedgePart", **k)

    def ramp(self, parent, label, x0, x1, y0, y1, z_low, z_high, color, fr=WORLD, **k):
        """A slope rising from z_low to z_high."""
        d = abs(z_high - z_low)
        # A wedge is tall at local +Z.
        rot = I3 if z_high > z_low else ry(180)
        return self.part(parent, label, [(x0 + x1) / 2, (y0 + y1) / 2, (z_low + z_high) / 2], [x1 - x0, y1 - y0, d], color, fr, rot, "WedgePart", **k)

    def light(self, part, color, reach, power, cl="PointLight", label="Warm light", **extra):
        it = self.item(part, cl, label)
        c = ET.SubElement(it.find("Properties"), "Color3", name="Color")
        for k, v in zip("RGB", (int(color[i:i + 2], 16) / 255 for i in (0, 2, 4))):
            ET.SubElement(c, k).text = f"{v:.4f}"
        field(it, "float", "Range", reach)
        field(it, "float", "Brightness", power)
        for key, (kind, value) in extra.items():
            field(it, kind, key, value)
        return it

    def lettering(self, part, text, face=2, color="FFF4D6", px=40, size=None, label="Lettering", stroke="2A1C3A"):
        """Fixed type on a fixed canvas. Scaled type can come up small while a part streams in."""
        gui = self.item(part, "SurfaceGui", label)
        field(gui, "token", "Face", face)
        field(gui, "token", "SizingMode", 1)
        field(gui, "float", "PixelsPerStud", px)
        field(gui, "float", "LightInfluence", 0)
        t = self.item(gui, "TextLabel", text.split("\n")[0])
        u = ET.SubElement(t.find("Properties"), "UDim2", name="Size")
        for k, v in zip(("XS", "XO", "YS", "YO"), (1, 0, 1, 0)):
            ET.SubElement(u, k).text = str(v)
        field(t, "float", "BackgroundTransparency", 1)
        field(t, "string", "Text", text)
        field(t, "float", "TextSize", size or 60)
        field(t, "bool", "TextScaled", "false")
        ff = ET.SubElement(t.find("Properties"), "Font", name="FontFace")
        fam = ET.SubElement(ff, "Family")
        ET.SubElement(fam, "url").text = "rbxasset://fonts/families/FredokaOne.json"
        ET.SubElement(ff, "Weight").text = "400"
        ET.SubElement(ff, "Style").text = "Normal"
        for key, ink in (("TextColor3", color), ("TextStrokeColor3", stroke)):
            c = ET.SubElement(t.find("Properties"), "Color3", name=key)
            for k, v in zip("RGB", (int(ink[i:i + 2], 16) / 255 for i in (0, 2, 4))):
                ET.SubElement(c, k).text = f"{v:.4f}"
        field(t, "float", "TextStrokeTransparency", 0.2)
        return gui

    def adopt(self, parent, item):
        it = copy.deepcopy(item)
        renamed = {}
        for i in it.iter("Item"):
            self.ref += 1
            renamed[i.get("referent")] = f"M{self.ref}"
            i.set("referent", f"M{self.ref}")
        # A model's PrimaryPart points at one of its own parts.
        for ref in it.iter("Ref"):
            if ref.text in renamed:
                ref.text = renamed[ref.text]
        parent.append(it)
        self.owners += 1
        for p in it.iter("Item"):
            if p.get("class") in ("Part", "WedgePart", "SpawnLocation") and self.owner == 0:
                cf = prop(p, "CFrame")
                m = [[float(cf.find(f"R{r}{c}").text) for c in range(3)] for r in range(3)]
                clear = prop(p, "Transparency")
                solid = prop(p, "CanCollide")
                self.owner = self.owners
                self.note(it, p, name(p), xyz(p, "CFrame"), m, xyz(p, "size"), p.get("class"), solid is None or solid.text == "true", float(clear.text) if clear is not None else 0)
                self.owner = 0
        return it

    def clear(self, x, z, r, y0, y1):
        """True if an upright cylinder is free of everything solid built so far."""
        for a in self.solids:
            if a[1] < y1 and a[4] > y0 and a[0] - r < x < a[3] + r and a[2] - r < z < a[5] + r:
                return False
        return True


def penetration(p, q):
    """How far two boxes overlap, by separating axes. Wedges count as their boxes. Below zero is clearance."""
    d = [q["at"][i] - p["at"][i] for i in range(3)]
    pa = [[p["m"][r][k] for r in range(3)] for k in range(3)]
    qa = [[q["m"][r][k] for r in range(3)] for k in range(3)]
    axes = pa + qa
    for a in pa:
        for c in qa:
            x = [a[1] * c[2] - a[2] * c[1], a[2] * c[0] - a[0] * c[2], a[0] * c[1] - a[1] * c[0]]
            n = math.sqrt(sum(v * v for v in x))
            if n > 1e-4:
                axes.append([v / n for v in x])
    best = 1e9
    for x in axes:
        depth = (sum(abs(sum(pa[k][i] * x[i] for i in range(3))) * p["h"][k] for k in range(3))
                 + sum(abs(sum(qa[k][i] * x[i] for i in range(3))) * q["h"][k] for k in range(3)) - abs(sum(d[i] * x[i] for i in range(3))))
        if depth <= -0.05:
            return depth
        best = min(best, depth)
    return best


def inside(q, pt):
    d = [pt[i] - q["at"][i] for i in range(3)]
    return all(abs(sum(q["m"][r][k] * d[r] for r in range(3))) <= q["h"][k] for k in range(3))


def recolor(item, table):
    """Give a kept part the new palette, and studs if it is a structural surface."""
    el = prop(item, "Color3uint8")
    if el is None:
        return
    ink = f"{int(el.text) & 0xFFFFFF:06X}"
    if ink in table:
        el.text = str(0xFF000000 | int(table[ink], 16))


def stud_all(item):
    size = xyz(item, "size")
    x, y, z = size
    field(item, "token", "Material", PLASTIC)
    spans = {"TopSurface": (x, z), "BottomSurface": (x, z), "LeftSurface": (y, z), "RightSurface": (y, z),
             "FrontSurface": (x, y), "BackSurface": (x, y)}
    for face in FACES:
        field(item, "token", face, STUD if min(spans[face]) >= 0.95 else 0)


LEVEL = {"bench", "crate", "barrel", "lamp", "banner", "sack"}


def footprint(item):
    el = prop(item, "CFrame")
    m = [[float(el.find(f"R{r}{c}").text) for c in range(3)] for r in range(3)]
    p, s = xyz(item, "CFrame"), xyz(item, "size")
    h = [sum(abs(m[i][k]) * s[k] / 2 for k in range(3)) for i in range(3)]
    return (p[0] - h[0], p[1] - h[1], p[2] - h[2], p[0] + h[0], p[1] + h[1], p[2] + h[2])
