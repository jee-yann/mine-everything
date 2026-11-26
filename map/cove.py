"""The palette, the kept parts and the things the cove is built from."""

import functools
import math
import xml.etree.ElementTree as ET
from pathlib import Path

from kit import (GLASS, METAL, NEON, PLASTIC, SMOOTH, Builder, Frame, I3, apply, field, footprint, matmul, name, prop,
                 recolor, rx, ry, rz, stud_all, xyz)

HERE = Path(__file__).parent
core = ET.parse(HERE / "source/CoveCore.rbxmx").getroot().find("Item")
CORE = {}
for child in core.findall("Item"):
    CORE.setdefault(name(child), child)

P = dict(
    grass="70C24E", grass2="86D25C", grass3="5CAF45", moss="4A9741",
    sand="F2D79B", sand2="E6C583", path="DDB87A", path2="CFA768",
    amber="E79A52", clay="DA8749", rust="C0703F", umber="8C4A30", cream="F2B874",
    slate="746DA0", slate2="8B85B4", slate3="5B5488", ink="2C2748",
    stone="D9CCB2", stone2="BFB298", stone3="EADFC8",
    wood="A0683C", wood2="7C4D2C", wood3="C48B50", plank="B57B47",
    citrine="FFC02E", citrine2="FFDA5C", honey="FFA51F",
    violet="8E4DF5", lilac="C79BFF", plum="5B2FA0",
    coral="EF5B4C", teal="1FB5AE", navy="2E3B6B", cream2="FFF2D6", pink="F08DB4", leafgold="F2B63C", iron="3E4656", iron2="6B7486",
    water="3FC3E6", foam="E6FAFF", surf="BCE8F4",
)
b = Builder()
rng = b.rng
root = b.root


def group(*path):
    node = root
    for label in path:
        found = next((c for c in node.findall("Item") if name(c) == label and c.get("class") == "Model"), None)
        node = found if found is not None else b.model(node, label)
    return node


# ---------------------------------------------------------------- kept parts
GREEN = {"86CA67": P["grass"], "EBAD6A": P["clay"], "FFE098": P["sand"], "CC9C84": P["rust"], "66E1DE": P["water"], "418FA8": "2F9CC4"}


def keep(src, parent, only=None, studs=True, table=GREEN, solid=True):
    for c in src.findall("Item"):
        if only and name(c) not in only:
            continue
        it = b.adopt(parent, c)
        for p in it.iter("Item"):
            if p.get("class") in ("Part", "WedgePart", "SpawnLocation"):
                recolor(p, table)
                if studs and int(prop(p, "Material").text) in (PLASTIC, SMOOTH, 512, 800, 816, 788, 1088) and "ater" not in name(p) and name(p) != "Lagoon":
                    stud_all(p)
                if solid and prop(p, "CanCollide") is not None and prop(p, "CanCollide").text == "true":
                    b.solids.append(footprint(p))


def set_type(item, height, scale=0.8):
    """Fix the type size of a kept panel. Scaled type in the map can stay at its smallest."""
    for t in item.iter("Item"):
        if t.get("class") == "TextLabel":
            share = prop(t, "Size").find("YS").text
            field(t, "bool", "TextScaled", "false")
            field(t, "float", "TextSize", round(height * float(share or 1) * scale))


def move(item, pos, yaw=0):
    """Put a kept part somewhere else, children and all."""
    m = ry(yaw)
    cf = prop(item, "CFrame")
    for k, v in zip("XYZ", pos):
        cf.find(k).text = f"{v:.4f}"
    for r in range(3):
        for c in range(3):
            cf.find(f"R{r}{c}").text = f"{m[r][c]:.7f}"


origin = b.adopt(root, CORE["SiteOrigin"])
primary = ET.SubElement(root.find("Properties"), "Ref", name="PrimaryPart")
primary.text = origin.get("referent")

hall = group("Working gallery")
# The hall's old timbers stood on ground that can be dug away. Its new ones hang from the walls.
for p in list(CORE["Working gallery"].findall("Item")):
    if name(p) in ("Timber upright", "Timber foot", "Roof strut", "Roof bearing", "Wall rail"):
        CORE["Working gallery"].remove(p)
keep(CORE["Working gallery"], hall, table={"86CA67": P["grass"]})
for p in hall.findall("Item"):
    k = name(p)
    if k in ("Bluff turf", "Bank turf"):
        field(p, "Color3uint8", "Color3uint8", 0xFF000000 | int(P["grass3"], 16))
    if k == "Ridge footing":
        cf = prop(p, "CFrame").find("X")
        cf.text = f"{float(cf.text) * 1.002:.4f}"
    if k in ("Bluff turf", "Bank turf"):
        pass
    elif k in ("Bluff foundation", "Bank foundation", "Sloping bluff foundation", "Ridge footing", "Rear bluff foundation"):
        field(p, "Color3uint8", "Color3uint8", 0xFF000000 | int(P["clay"], 16))
edit = group("EditFace")
keep(CORE["EditFace"], edit, studs=False, solid=False)
isle = group("Island and lagoon")
keep(CORE["Island and lagoon"], isle)
for p in list(isle.findall("Item")):
    if name(p) == "Tide rock":
        isle.remove(p)
paths = group("Sand path and bridge")
STEP = {"86CA67": P["grass"]}
for p in list(CORE["Sand path and bridge"].findall("Item")):
    if name(p) == "Rail post":
        CORE["Sand path and bridge"].remove(p)
keep(CORE["Sand path and bridge"], paths)
for p in paths.findall("Item"):
    ink = {"Canal step": P["stone2"], "Canal landing": P["stone"], "Bridge decking": P["wood2"], "Bridge bearer": P["wood2"],
           "Rail post": P["wood2"], "Portal paving": P["stone"], "Mine path": P["path"]}.get(name(p))
    if name(p) == "Mine path":
        # From the square to the bridge.
        prop(p, "size").find("Z").text, prop(p, "CFrame").find("Z").text = "2.7", "26.79"
    if ink:
        field(p, "Color3uint8", "Color3uint8", 0xFF000000 | int(ink, 16))
high = group("Citrine Highlands")
keep(CORE["Outer meadows"], group("Citrine Highlands", "Outer meadows"))
for m in group("Citrine Highlands", "Outer meadows").findall("Item"):
    if name(m) == "Creek crossing":
        for p in m.findall("Item"):
            ink = {"Timber deck": P["wood2"], "Footboard": P["plank"], "Bridge pile": P["wood2"], "Painted cap": P["citrine"], "Handrail": P["wood"]}[name(p)]
            field(p, "Color3uint8", "Color3uint8", 0xFF000000 | int(ink, 16))
tram = group("Citrine Highlands", "Ridge tramway")
for p in list(CORE["Ridge tramway"].findall("Item")):
    if name(p) == "Receiving hopper cheek":
        CORE["Ridge tramway"].remove(p)
    elif name(p) == "Rail" and xyz(p, "size")[0] > 0.4:
        # Tower legs and rungs, thick enough for a stud.
        for k in "XY":
            prop(p, "size").find(k).text = "1.1" if xyz(p, "size")[2] > 20 else "0.96"
keep(CORE["Ridge tramway"], tram)
for p in tram.findall("Item"):
    if name(p) == "Receiving hopper floor":
        # A square-cornered bin. Its rim stays under the tipping bucket.
        x, y, z = xyz(p, "CFrame")
        for s in (-1, 1):
            b.part(tram, "Receiving hopper wall", [x + s * 2.95, y + 0.5, z], [0.5, 2.0, 4.2], P["wood"], solid=False)
            b.part(tram, "Receiving hopper wall", [x, y + 0.5, z + s * 1.85], [5.4, 2.0, 0.5], P["plank"], solid=False)
keep(CORE["Moving cabins"], group("Citrine Highlands", "Moving cabins"), solid=False)
trail = group("Citrine Highlands", "Cableway trail")
for p in list(CORE["Cableway trail"].findall("Item")):
    x, z = abs(xyz(p, "CFrame")[0]), xyz(p, "CFrame")[2]
    if name(p) in ("Survey trail", "Trail bend") and x < 108 and z < -42:
        # The old way led through the towers. A path round them replaces it.
        CORE["Cableway trail"].remove(p)
    elif name(p) == "Survey trail" and x < 112:
        # A little longer at the top, to meet it.
        cf = prop(p, "CFrame")
        up = 1 if float(cf.find("R12").text) > 0 else -1
        for k, row in zip("XYZ", ("R02", "R12", "R22")):
            cf.find(k).text = f"{float(cf.find(k).text) + up * 1.2 * float(cf.find(row).text):.4f}"
        prop(p, "size").find("Z").text = f"{xyz(p, 'size')[2] + 2.4:.4f}"
    elif name(p) == "Rear roof slope":
        prop(p, "size").find("X").text = "60.2"
keep(CORE["Cableway trail"], trail)
for p in trail.findall("Item"):
    lift = {"Survey trail": 0.3, "Trail bend": 0.42, "Cross-ridge trail": 0.3}.get(name(p), 0)
    cf = prop(p, "CFrame").find("Y")
    cf.text = f"{float(cf.text) + lift:.4f}"
    if lift:
        # Thick enough to reach the ground it lies on.
        deep = min((prop(p, "size").find(k) for k in "XYZ"), key=lambda e: float(e.text))
        deep.text = f"{float(deep.text) + 0.5:.4f}"
        cf.text = f"{float(cf.text) - 0.25:.4f}"
    ink = {"Ridgeline turf": P["grass3"], "Mine roof slope": P["grass"], "Rear roof slope": P["grass"], "Survey trail": P["path"],
           "Trail bend": P["path"], "Cross-ridge trail": P["path"], "Tower footing": P["slate2"]}[name(p)]
    field(p, "Color3uint8", "Color3uint8", 0xFF000000 | int(ink, 16))
rim = group("Citrine Highlands", "Rock rim")
keep(CORE["Rock rim"], rim, studs=False, solid=False)
# The invisible rim wall must stop above the mine. Its second layer begins at y 18, under the whole site.
MINE_TOP = 18.3
for p in rim.iter("Item"):
    if p.get("class") == "Part":
        size, cf = prop(p, "size"), prop(p, "CFrame")
        sy, y = float(size.find("Y").text), float(cf.find("Y").text)
        if y - sy / 2 < MINE_TOP:
            top = y + sy / 2
            size.find("Y").text, cf.find("Y").text = f"{top - MINE_TOP:.4f}", f"{(top + MINE_TOP) / 2:.4f}"
edge = [xyz(c, "CFrame") for c in CORE["Rock rim"].findall("Item")]


# ---------------------------------------------------------------- vocabulary
def thing(fn):
    """Everything one call draws belongs to one object."""
    @functools.wraps(fn)
    def draw(*a, **k):
        if b.owner:
            return fn(*a, **k)
        b.owners += 1
        b.owner = b.owners
        try:
            return fn(*a, **k)
        finally:
            b.owner = 0
    return draw


def fitted(reach=3.2, must=False):
    """A prop. It is placed after the island is built, where it fits."""
    def wrap(fn):
        @functools.wraps(fn)
        def later(*a, **k):
            if b.owner or b.trial is not None:
                return fn(*a, **k)
            b.owners += 1
            mine = b.owners

            def draw():
                b.owner = mine
                try:
                    fn(*a, **k)
                finally:
                    b.owner = 0
            b.place(fn.__name__, draw, reach, must)
            return True
        return later
    return wrap


@thing
def mesa(parent, x, z, w, d, y0, y1, corner=5, yaw=0, top="grass", warm=True, lip=0.7, label="Weathered sandstone", cap="Grass shelf", capy=1.6):
    """A terrace: two beds of rock, a pale seam, and a lid of turf that overhangs them."""
    h = y1 - y0
    beds = (P["rust"], P["clay"], P["amber"]) if warm else (P["slate3"], P["slate"], P["slate2"])
    cut = [y0, y0 + h * 0.52, y1 - capy]
    beds = (beds[0], beds[1]) if h > 10 else (beds[1], beds[2])
    f = Frame(x, 0, z, yaw)
    for i, grow in enumerate((0.8, -0.3)):
        if cut[i + 1] - cut[i] > 0.2:
            b.pad(parent, label, 0, 0, w + grow, d + grow, cut[i], cut[i + 1], beds[i], corner + grow / 2, f)
    b.pad(parent, cap, 0, 0, w + 2 * lip, d + 2 * lip, y1 - capy, y1, P[top], corner + lip, f)
    # A tall face is broken by a shelf or two on its long sides.
    if h > 10 and label == "Weathered sandstone":
        mine = b.owner
        for side in (1, -1):
            n = min(w, d) * rng.uniform(0.22, 0.34)
            along = rng.uniform(-0.16, 0.16) * w
            y = y0 + h * rng.uniform(0.34, 0.66)

            def shelf(side=side, n=n, along=along, y=y):
                b.owner = mine
                b.part(parent, "Cliff ledge", [along, y, side * (d / 2 + 0.5)], [n, 1.8, 2.6], beds[1] if side > 0 else beds[0], f)
                b.part(parent, "Ledge turf", [along, y + 1.15, side * (d / 2 + 0.55)], [n + 0.5, 0.7, 2.9], P["grass2"], f)
                b.owner = 0
            # Only where that face is in the open.
            b.place("ledge", shelf, 0)


@thing
def terrace(parent, x, z, w, d, y0, y1, corner=5, yaw=0, top="stone", wall="clay", label="Terrace wall", cap="Terrace paving"):
    f = Frame(x, 0, z, yaw)
    b.pad(parent, label, 0, 0, w, d, y0, y1 - 1.1, P[wall], corner, f)
    b.pad(parent, cap, 0, 0, w + 0.8, d + 0.8, y1 - 1.1, y1, P[top], corner + 0.4, f)


@fitted(3.2)
def rock(parent, x, y, z, s, tone=("rust", "clay", "umber"), n=3, solid=True):
    for i in range(n):
        k = s * (1 - 0.24 * i)
        b.part(parent, "Wild stone", [x + rng.uniform(-0.5, 0.5) * s * 0.9 * (i > 0), y + k * 0.30 + (0.1 * i), z + rng.uniform(-0.5, 0.5) * s * 0.9 * (i > 0)],
               [k * rng.uniform(0.9, 1.25), k * rng.uniform(0.75, 1.0), k * rng.uniform(0.85, 1.15)], P[tone[i % len(tone)]],
               rot=matmul(ry(rng.uniform(0, 90)), rz(rng.uniform(-9, 9))), solid=solid)


def crystal(parent, x, y, z, h, w, color, yaw=0, tilt=0, lean=0, glow=False, solid=False, fr=None):
    """A cut crystal: three crossed slabs and their points."""
    base = fr or Frame(x, y, z)
    tip = w * 0.95
    m = matmul(ry(yaw), matmul(rz(tilt), rx(lean)))
    f = Frame(0, 0, 0)
    f.o, f.m = base.at([0, 0, 0]) if fr is None else base.at([x, y, z]), matmul(base.m, m)
    mat = NEON if glow else SMOOTH
    # Small ones are two crossed slabs. Nobody sees the third.
    n = 3 if w > 1.3 else 2
    for i in range(n):
        g = Frame(0, 0, 0)
        g.o, g.m = f.o, matmul(f.m, ry(180 / n * i))
        t = w * (0.577 if n == 3 else 0.72)
        b.part(parent, "Crystal facet", [0, (h - tip) / 2, 0], [w, h - tip, t], color, g, mat=mat, solid=solid, shine=0 if glow else 0.12, studs=False, query=True)
        for s in (1, -1):
            b.part(parent, "Crystal point", [s * w / 4, h - tip / 2, 0], [t, tip, w / 2], color, g, ry(-90 * s), "WedgePart", mat=mat, solid=False, shine=0 if glow else 0.12, studs=False, query=True)


@fitted(3.2)
def cluster(parent, x, y, z, s, colors, n=4, glow=False, fr=None):
    for i in range(n):
        a = i * 2.4 + 0.4
        r = 0 if i == 0 else s * 0.42
        k = 1 if i == 0 else rng.uniform(0.45, 0.72)
        crystal(parent, x + math.cos(a) * r, y - 0.3 * s * 0.2, z + math.sin(a) * r, s * 1.7 * k, s * 0.52 * k, colors[i % len(colors)],
                yaw=rng.uniform(0, 60), tilt=0 if i == 0 else -math.cos(a) * 20, lean=0 if i == 0 else math.sin(a) * 20, glow=glow, fr=fr)


@fitted(3.2)
def leafy(parent, x, z, y=24, s=1.0, palette=("grass3", "grass", "moss"), yaw=None):
    yaw = rng.uniform(0, 90) if yaw is None else yaw
    h = 5.2 * s
    f = Frame(x, y, z, yaw)
    b.part(parent, "Trunk", [0, h / 2, 0], [1.5 * s, h, 1.5 * s], P["wood2"], f)
    for i, (dx, dy, dz, w, t) in enumerate(((0, 0.8, 0, 6.0, 3.0), (0.4, 3.0, -0.3, 4.6, 2.4), (-0.2, 4.8, 0.2, 2.9, 1.9), (2.3, 0.2, 1.6, 2.8, 2.0), (-2.2, 0.6, -1.4, 2.6, 2.0))):
        b.part(parent, "Leaf crown", [dx * s, h + dy * s, dz * s], [w * s, t * s, w * s], P[palette[i % len(palette)]], f, ry(i * 31), solid=False, query=True)
    return True


@fitted(3.2)
def pine(parent, x, z, y=24, s=1.0):
    h = 3.2 * s
    f = Frame(x, y, z, rng.uniform(0, 90))
    b.part(parent, "Pine trunk", [0, h / 2, 0], [1.2 * s, h, 1.2 * s], P["wood2"], f)
    for i, (w, dy) in enumerate(((5.4, 1.0), (4.4, 3.0), (3.3, 5.0), (2.0, 6.9))):
        b.part(parent, "Pine crown", [0, h + dy * s, 0], [w * s, 2.1 * s, w * s], P[("moss", "grass3")[i % 2]], f, ry(i * 22), solid=False, query=True)
    return True


@fitted(3.2)
def palm(parent, x, z, y=24, s=1.0, yaw=0):
    f = Frame(x, y, z, yaw)
    px, py = 0, 0
    for i in range(6):
        b.part(parent, "Palm trunk", [px + 0.12 * i * s, py + 0.9 * s, 0], [(1.35 - 0.08 * i) * s, 1.9 * s, (1.35 - 0.08 * i) * s], P["wood3" if i % 2 else "wood"], f, rz(-4 - 2 * i))
        px += 0.14 * i * s
        py += 1.75 * s
    b.part(parent, "Palm crown", [px + 0.7 * s, py + 0.57 * s, 0], [1.5 * s, 1.2 * s, 1.5 * s], P["grass"], f, solid=False)
    for i in range(6):
        g = f.sub(px + 0.7 * s, py + (0.44 + 0.09 * (i % 3)) * s, 0, i * 60)
        b.part(parent, "Palm leaf", [0, 0.05 * s, 1.7 * s], [1.7 * s, 0.4 * s, 3.4 * s], P["grass3"], g, rx(6), solid=False)
        b.part(parent, "Palm leaf", [0, -0.75 * s, 4.2 * s], [1.3 * s, 0.35 * s, 2.5 * s], P["grass"], g, rx(34), solid=False)


@fitted(3.2)
def bush(parent, x, y, z, s=1.0, tones=("grass3", "moss"), bloom=None):
    for i, (dx, dz, w) in enumerate(((0, 0, 2.4), (1.2, 0.5, 1.7), (-1.0, -0.6, 1.8))):
        b.part(parent, "Bush", [x + dx * s, y + w * s * 0.34, z + dz * s], [w * s, w * s * 0.8, w * s], P[tones[i % 2]], rot=ry(rng.uniform(0, 80)), solid=False)
    if bloom:
        for i in range(3):
            a = i * 2.2
            b.part(parent, "Bush bloom", [x + math.cos(a) * 1.0 * s, y + (1.72 + 0.23 * (i % 2)) * s, z + math.sin(a) * 0.9 * s], [0.5 * s] * 3, P[bloom], rot=ry(30 * i), solid=False, shadow=False, mat=SMOOTH)


@fitted(2.4)
def flowers(parent, x, y, z, n=6, r=1.8, tones=("citrine2", "coral", "cream2")):
    for i in range(n):
        a, q = rng.uniform(0, 6.28), r * math.sqrt(rng.random())
        px, pz, h = x + math.cos(a) * q, z + math.sin(a) * q, rng.uniform(0.7, 1.2)
        b.part(parent, "Flower", [px, y + h * 0.35, pz], [0.75, h * 0.7, 0.75], P[tones[i % len(tones)]], rot=ry(rng.uniform(0, 90)), solid=False, shadow=False, mat=SMOOTH)


@fitted(2.4)
def tuft(parent, x, y, z, s=1.0):
    for i in range(3):
        b.part(parent, "Grass tuft", [x + 0.4 * math.cos(i * 2.1) * s, y + 0.45 * s, z + 0.4 * math.sin(i * 2.1) * s], [0.35 * s, 1.0 * s, 0.35 * s],
               P[("grass2", "grass3", "moss")[i]], rot=matmul(ry(120 * i), rz(16)), solid=False, shadow=False, mat=SMOOTH)


lamps = 0


@fitted(3.2, must=True)
def lamp(parent, x, y, z, tone="FFD79A", tall=7.0, lit=True, yaw=0):
    global lamps
    f = Frame(x, y, z, yaw)
    b.part(parent, "Lamp foot", [0, 0.4, 0], [2.0, 0.8, 2.0], P["slate3"], f)
    b.part(parent, "Lamp post", [0, tall / 2 + 0.4, 0], [0.9, tall, 0.9], P["wood2"], f, studs=False)
    b.part(parent, "Lamp collar", [0, tall + 0.4, 0], [1.9, 0.5, 1.9], P["slate3"], f)
    glass = b.part(parent, "Lamp glass", [0, tall + 1.4, 0], [1.0, 1.5, 1.0], "FFC15E", f, mat=NEON, solid=False, shadow=False)
    b.part(parent, "Lamp roof", [0, tall + 2.4, 0], [1.9, 0.5, 1.9], P["honey"], f, studs=False)
    b.part(parent, "Lamp finial", [0, tall + 3.0, 0], [0.9, 0.7, 0.9], P["citrine"], f, solid=False, mat=SMOOTH)
    if lit:
        b.light(glass, tone, 22, 0.75)
        lamps += 1


@fitted(3.2, must=True)
def bench(parent, x, y, z, yaw=0):
    f = Frame(x, y, z, yaw)
    for s in (-1, 1):
        b.part(parent, "Bench leg", [s * 2.2, 0.7, 0], [1.0, 1.4, 1.8], P["slate3"], f)
    b.part(parent, "Bench seat", [0, 1.6, 0.1], [6.2, 0.5, 2.0], P["plank"], f)
    b.part(parent, "Bench back", [0, 2.65, -0.65], [6.2, 1.6, 0.5], P["wood"], f)


@fitted(3.2, must=True)
def crate(parent, x, y, z, s=2.4, yaw=0, tone="plank"):
    f = Frame(x, y, z, yaw)
    b.part(parent, "Crate", [0, s / 2, 0], [s, s, s], P[tone], f)
    for k in (0.12, 0.88):
        b.part(parent, "Crate band", [0, s * k, 0], [s + 0.2, s * 0.16, s + 0.2], P["wood2"], f, studs=False)


@fitted(3.2)
def barrel(parent, x, y, z, tone="wood", s=1.0):
    f = Frame(x, y, z, rng.uniform(0, 45))
    b.pad(parent, "Barrel", 0, 0, 2.2 * s, 2.2 * s, 0, 2.8 * s, P[tone], 0.6 * s, f)
    for k in (0.4, 2.05):
        b.pad(parent, "Barrel hoop", 0, 0, 2.4 * s, 2.4 * s, k * s, (k + 0.35) * s, P["iron"], 0.655 * s, f)


@fitted(3.2)
def sack(parent, x, y, z, yaw=0):
    f = Frame(x, y, z, yaw)
    b.part(parent, "Ore sack", [0, 0.8, 0], [1.9, 1.6, 1.5], P["sand2"], f, rz(5))
    b.part(parent, "Sack tie", [0, 1.75, 0], [0.8, 0.5, 0.7], P["rust"], f, studs=False)


@fitted(2.4)
def ore_pile(parent, x, y, z, s, tones, n=9):
    for i in range(n):
        a, q = i * 2.4, s * 0.5 * math.sqrt(i / n)
        k = s * rng.uniform(0.28, 0.44)
        b.part(parent, "Ore chunk", [x + math.cos(a) * q, y + k * 0.35 + max(0, (1 - i / n)) * s * 0.25, z + math.sin(a) * q], [k, k * 0.85, k], P[tones[i % len(tones)]],
               rot=matmul(ry(rng.uniform(0, 90)), rz(rng.uniform(-25, 25))), mat=SMOOTH, solid=i < 4, studs=False)


@thing
def cart(parent, x, y, z, yaw=0, load=("slate2", "citrine", "slate")):
    f = Frame(x, y, z, yaw)
    for sx in (-1, 1):
        for sz in (-1.15, 1.15):
            # The tread stands on the rail. The flange runs down inside it.
            b.part(parent, "Flanged wheel", [sx * 2.1, 0.75, sz], [0.4, 1.5, 1.5], P["iron"], f, mat=SMOOTH, shape=2)
            b.part(parent, "Wheel flange", [sx * 1.78, 0.75, sz], [0.2, 1.9, 1.9], P["ink"], f, mat=SMOOTH, shape=2)
        b.part(parent, "Axle", [0, 0.75, sx * 1.15], [3.3, 0.4, 0.4], P["ink"], f, mat=SMOOTH)
    b.part(parent, "Wagon frame", [0, 1.25, 0], [2.6, 0.6, 5.4], P["ink"], f)
    b.part(parent, "Wagon bed", [0, 1.85, 0], [3.8, 0.6, 5.4], P["iron"], f)
    for s in (-1, 1):
        b.part(parent, "Wagon side", [s * 1.95, 3.2, 0], [0.5, 2.1, 5.4], P["iron2"], f)
        b.part(parent, "Wagon end", [0, 3.2, s * 2.45], [3.4, 2.1, 0.5], P["iron2"], f)
        b.part(parent, "Wagon rim", [0, 4.4, s * 2.5], [4.6, 0.3, 0.7], P["citrine"], f)
        b.part(parent, "Wagon rim", [s * 1.95, 4.4, 0], [0.7, 0.3, 4.3], P["citrine"], f)
    b.part(parent, "Wagon load", [0, 2.8, 0], [3.4, 1.3, 4.4], P[load[0]], f)
    for i in range(7):
        k = rng.uniform(1.0, 1.4)
        b.part(parent, "Fractured stone", [rng.uniform(-0.75, 0.75), 3.7 + rng.uniform(0, 0.9), rng.uniform(-1.4, 1.4)], [k, k * 0.8, k], P[load[i % len(load)]], f,
               matmul(ry(rng.uniform(0, 90)), rz(rng.uniform(-20, 20))), mat=SMOOTH, solid=False, studs=False)


@thing
def fence(parent, pts, y, tone="wood"):
    for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, z1 - z0)
        yaw = math.degrees(math.atan2(x1 - x0, z1 - z0))
        n = max(1, round(L / 5))
        for i in range(0 if (x0, z0) == tuple(pts[0]) else 1, n + 1):
            x, z = x0 + (x1 - x0) * i / n, z0 + (z1 - z0) * i / n
            b.part(parent, "Fence post", [x, y + 1.5, z], [0.95, 3.0, 0.95], P["wood2"], rot=ry(yaw), studs=False)
            b.part(parent, "Fence cap", [x, y + 3.15, z], [1.25, 0.4, 1.25], P["citrine"], rot=ry(yaw), studs=False, solid=False)
        for h in (1.1, 2.3):
            b.part(parent, "Fence rail", [(x0 + x1) / 2, y + h, (z0 + z1) / 2], [0.4, 0.5, L], P[tone], rot=ry(yaw), studs=False)


@thing
def steps(parent, x, z, w, y0, y1, depth, yaw, tone="stone", label="Stone step"):
    """Broad steps rising along local -Z, each under a stud so nobody has to jump."""
    n = math.ceil((y1 - y0) / 0.72)
    run = depth / n
    f = Frame(x, 0, z, yaw)
    for i in range(n):
        top = y0 + (y1 - y0) * (i + 1) / n
        b.part(parent, label, [0, (y0 - 0.3 + top) / 2, depth / 2 - run * (i + 0.5)], [w, top - y0 + 0.3, run], P[tone if i % 2 else "stone2"], f)
    for s in (-1, 1):
        # A sloping kerb, with a block to finish it top and bottom.
        b.part(parent, "Step cheek", [s * (w / 2 + 0.6), (y0 + y1) / 2 + 0.25, 0], [1.2, y1 - y0 + 0.5, depth], P["slate2"], f, ry(180), "WedgePart")
        b.part(parent, "Step newel", [s * (w / 2 + 0.6), y1 + 0.75, -depth / 2 - 0.92], [1.8, 1.6, 1.8], P["slate2"], f)
        b.part(parent, "Step newel", [s * (w / 2 + 0.6), y0 + 0.6, depth / 2 + 0.9], [1.8, 1.8, 1.8], P["slate2"], f)


def climb(parent, x, z, yaw, side, half, w, y0, y1, depth, along=0):
    """Steps that end exactly at one side of a terrace. `half` is the reach of its turf on that side."""
    f = Frame(x, 0, z, yaw)
    g = f.sub(0, 0, 0, side).at([along, 0, half + depth / 2])
    steps(parent, g[0], g[2], w, y0, y1, depth, yaw + side)


laid = 0


@thing
def slab_path(parent, pts, w, y=24.0, tone="path", label="Path slab"):
    """Strips that stop short of each other, and a raised stone where they meet. Roads that cross
    lie at two heights."""
    global laid
    y += 0.055 * (laid % 2)
    laid += 1
    for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, z1 - z0)
        yaw = math.degrees(math.atan2(x1 - x0, z1 - z0))
        cut = w * 0.30
        b.part(parent, label, [(x0 + x1) / 2, y - 0.14, (z0 + z1) / 2], [w, 0.6, max(1, L - 2 * cut)], P[tone], rot=ry(yaw))
    for k, (x, z) in enumerate(pts):
        b.pad(parent, label, x, z, w * 1.12, w * 1.12, y - 0.44, y + 0.26, P[tone], w * 0.33, studs=True)


def station(tag):
    """The floating name of a service, at one readable size on every screen."""
    gui = tag.find("Item")
    field(gui, "float", "MaxDistance", 62)
    size = prop(gui, "Size")
    for k, v in zip(("XS", "XO", "YS", "YO"), (0, 150, 0, 28)):
        size.find(k).text = str(v)
    for t in gui.iter("Item"):
        if t.get("class") == "TextLabel":
            field(t, "bool", "TextScaled", "false")
            field(t, "float", "TextSize", 19)


@fitted(3.2, must=True)
def banner(parent, x, y, z, yaw, tone, mark):
    f = Frame(x, y, z, yaw)
    b.part(parent, "Banner foot", [0, 0.4, 0], [1.8, 0.8, 1.8], P["slate3"], f)
    b.part(parent, "Banner pole", [0, 5.6, 0], [0.7, 10.4, 0.7], P["wood2"], f, studs=False)
    b.part(parent, "Banner arm", [1.3, 10.2, 0], [3.4, 0.5, 0.5], P["wood2"], f, studs=False)
    b.part(parent, "Banner cloth", [1.55, 7.5, 0], [2.6, 5.0, 0.3], P[tone], f, studs=False, solid=False, mat=SMOOTH)
    for s in (-1, 1):
        # The point of the cloth: two wedges that meet under it.
        b.part(parent, "Banner tail", [1.55 - s * 0.65, 4.35, 0], [0.3, 1.3, 1.3], P[tone], f, [[0, 0, s], [0, -1, 0], [s, 0, 0]], "WedgePart", solid=False)
    b.part(parent, "Banner mark", [1.55, 7.7, 0], [1.2, 1.2, 0.5], P[mark], f, rz(45), studs=False, solid=False, mat=SMOOTH)
    b.part(parent, "Banner finial", [0, 11.1, 0], [1.0, 1.0, 1.0], P["citrine"], f, ry(45), studs=False, solid=False, mat=SMOOTH)
