"""The places of the cove, in the order a player meets them."""

import math
import re

from cove import *  # noqa: F403

# ---------------------------------------------------------------- arrival plaza
plaza = group("Harbor Plaza", "Arrival court")
keep(CORE["Arrival court"], plaza, studs=False, solid=False, table={})
dials = [p for p in plaza.findall("Item") if name(p) == "Compass dial"]
for p, ink in zip(sorted(dials, key=lambda q: -max(xyz(q, "size")[1:])), (P["slate3"], "D89A33", "1E6E78", "2FA9A4")):
    field(p, "Color3uint8", "Color3uint8", 0xFF000000 | int(ink, 16))
    field(p, "token", "Material", SMOOTH)
for p in plaza.findall("Item"):
    if name(p).startswith("Compass"):
        cf = prop(p, "CFrame").find("Y")
        cf.text = f"{float(cf.text) + 0.07:.4f}"
b.pad(plaza, "Basalt rim", 0, 82, 112, 74, 23.4, 24.24, P["slate2"], 20)
b.pad(plaza, "Painted promenade", 0, 82, 109, 71, 23.6, 24.32, P["stone"], 18.5)
b.pad(plaza, "Promenade band", 0, 82, 99, 61, 23.8, 24.40, P["slate2"], 16)
b.pad(plaza, "Painted promenade", 0, 82, 96, 58, 23.8, 24.48, P["stone3"], 15)
b.pad(plaza, "Promenade inlay", 0, 93, 44, 42, 23.8, 24.57, P["stone"], 13)
# An eight-point star, long points to the cardinals.
for i in range(8):
    long = i % 2 == 0
    f = Frame(0, 25.0, 93, i * 45)
    L, w = (8.2, 1.5) if long else (4.8, 1.1)
    for s in (-1, 1):
        # Half a point: an upright wedge laid flat, right angle on the centre line.
        rot = [[0, s, 0], [1, 0, 0], [0, 0, 1]] if s < 0 else [[0, s, 0], [1, 0, 0], [0, 0, 1]]
        rot = [[0, float(s), 0], [float(-s), 0, 0], [0, 0, 1.0]]
        b.part(plaza, "Compass needle", [s * w / 2, 0.12 + (0 if long else -0.05), L / 2], [0.18, w, L], (P["cream2"] if s > 0 else P["citrine"]) if long else (P["citrine2"] if s > 0 else P["honey"]), f,
               matmul(rot, [[1, 0, 0], [0, -1, 0], [0, 0, -1]]), "WedgePart", studs=False, solid=False, mat=SMOOTH, shadow=False)
b.part(plaza, "Compass spindle", [0, 25.24, 93], [0.26, 1.6, 1.6], P["violet"], rot=rz(90), studs=False, solid=False, mat=SMOOTH, shape=2, shadow=False)
# The avenue: one lighter line from spawn to the bridge.
b.box(plaza, "Central concourse", -7, 7, 24.0, 24.58, 49.2, 71.7, P["sand"])
for s in (-1, 1):
    b.box(plaza, "Avenue kerb", s * 7.4 - 0.5, s * 7.4 + 0.5, 24.0, 24.78, 49.4, 71.4, P["honey"])
b.pad(plaza, "Bridge apron", 0, 46, 20, 6.2, 23.4, 24.5, P["stone"], 2.4)
for s in (-1, 1):
    for z, tone in ((51, "plum"), (66, "honey")):
        banner(plaza, s * 12.2, 24.5, z, 0 if s > 0 else 180, tone, "citrine2" if tone == "plum" else "violet")
    lamp(plaza, s * 12.2, 24.5, 58.5, lit=True)
    lamp(plaza, s * 17, 24.5, 104, lit=True)
    lamp(plaza, s * 30, 24.5, 108, lit=False)

# Four planters frame the compass. Benches face it.
for s in (-1, 1):
    for px, z, sz in ((41, 70.5, 1), (25, 110, -1)):
        f = Frame(s * px, 0, z, 0)
        b.pad(plaza, "Planter wall", 0, 0, 10, 8, 24.4, 26.0, P["slate2"], 2, f)
        b.pad(plaza, "Planter earth", 0, 0, 8.4, 6.4, 24.4, 26.2, P["umber"], 1.5, f)
        b.pad(plaza, "Planter turf", 0, 0, 8.0, 6.0, 26.0, 26.5, P["grass2"], 1.5, f)
        leafy(plaza, s * px, z, 26.5, 0.8, ("leafgold", "citrine", "honey") if sz > 0 else ("lilac", "violet", "lilac"))
        flowers(plaza, s * px + 2.4, 26.5, z + 1.2, 5, 1.2)
        flowers(plaza, s * px - 2.4, 26.5, z - 1.2, 5, 1.2, ("violet", "lilac", "cream2"))
    bench(plaza, s * 20.5, 24.5, 88, -90 * s)
    bench(plaza, s * 20.5, 24.5, 98, -90 * s)

# A signpost where the three roads part.
post = group("Harbor Plaza", "Signpost")
b.part(post, "Sign foot", [12.5, 25.1, 70], [2.4, 1.2, 2.4], P["slate3"])
b.part(post, "Sign post", [12.5, 29.4, 70], [1.0, 9.0, 1.0], P["wood2"], studs=False)
for y, text, yaw, tone in ((32.6, "MINE", 4, "honey"), (30.7, "LIGHTHOUSE", -34, "teal"), (28.8, "ORE YARD", 34, "coral")):
    f = Frame(12.5, y, 70, yaw)
    board = b.part(post, "Sign board", [0.6 if yaw < 0 else -0.6, 0, 0.75], [6.4, 1.5, 0.5], P[tone], f, studs=False)
    b.lettering(board, text, 2, "FFF8E6", 50, 46)

# ---------------------------------------------------------------- market
@thing
def stall(key, parent, x, z, yaw, y=24.5, tone="coral", tone2="cream2", title="", kind="", pad_name="Counter", pad_z=10.2, w=14.0, tag_h=13.0):
    f = Frame(x, y, z, yaw)
    m = parent
    d = 9.0
    b.pad(m, "Stall plinth", 0, 0, w + 3.0, d + 3.4, -0.6, 0.45, P["slate2"], 2.2, f)
    b.pad(m, "Stall floor", 0, 0, w + 1.6, d + 2.0, 0.2, 0.62, P["plank"], 1.6, f)
    b.part(m, "Stall wall", [0, 4.6, -d / 2 + 0.5], [w - 2.3, 8.0, 0.9], P["wood"], f)
    b.part(m, "Stall wainscot", [0, 2.0, -d / 2 + 1.15], [w - 1.2, 3.0, 0.4], P[tone], f)
    for s in (-1, 1):
        for zz in (-d / 2 + 0.6, d / 2 - 0.6):
            b.part(m, "Stall post foot", [s * (w / 2 - 0.4), 1.2, zz], [1.9, 1.6, 1.9], P["slate3"], f)
            b.part(m, "Stall post", [s * (w / 2 - 0.4), 5.2, zz], [1.25, 7.4, 1.25], P["wood2"], f, studs=False)
        b.part(m, "Stall side", [s * (w / 2 - 0.4), 2.2, 0], [0.7, 3.2, d - 3.3], P["plank"], f)
        b.part(m, "Roof beam", [s * (w / 2 - 0.4), 8.9, 0], [1.0, 0.9, d + 1.4], P["wood2"], f, studs=False)
    # Counter
    b.part(m, "Counter frame", [0, 1.9, d / 2 - 1.6], [w - 3.0, 2.6, 2.4], P["wood"], f)
    n = 5
    for i in range(n):
        b.part(m, "Painted counter board", [(i - (n - 1) / 2) * (w - 3.4) / n, 1.9, d / 2 - 0.32], [(w - 3.4) / n - 0.15, 2.2, 0.25], P[tone if i % 2 == 0 else tone2], f, studs=False)
    top = b.part(m, "Countertop", [0, 3.4, d / 2 - 1.5], [w - 2.2, 0.5, 3.0], P["stone3"], f)
    # Roof: a stepped gable in the stall's colour, with an awning toward the customer.
    for i, (rw, ry0) in enumerate(((1.0, 9.3), (0.72, 10.4), (0.44, 11.5))):
        b.part(m, "Roof tier", [0, ry0 + 0.1, -0.6], [w + 2.0 - i * 0.2, 1.1, (d + 2.2) * rw], P[tone if i != 1 else tone2], f)
    b.part(m, "Roof ridge", [0, 12.5, -0.6], [w + 2.4, 0.8, 2.0], P["wood2"], f, studs=False)
    for s in (-1, 1):
        b.part(m, "Ridge finial", [s * (w / 2 + 1.2), 12.7, -0.6], [1.1, 1.5, 1.5], P["citrine"], f, rx(45), studs=False, solid=False, mat=SMOOTH)
    n = 7
    for i in range(n):
        sx = (i - (n - 1) / 2) * (w + 1.4) / n
        b.part(m, "Canvas stripe", [sx, 8.35, d / 2 + 1.35], [(w + 1.4) / n, 0.4, 3.8], P[tone if i % 2 == 0 else tone2], f, rx(16), studs=False, solid=False, mat=SMOOTH)
        b.part(m, "Scalloped valance", [sx, 7.15, d / 2 + 3.15], [(w + 1.4) / n - 0.12, 1.1, 0.35], P[tone if i % 2 == 0 else tone2], f, studs=False, solid=False, mat=SMOOTH)
    # Sign
    b.part(m, "Sign frame", [0, 10.2, d / 2 + 1.0], [w - 1.6, 2.9, 0.6], P["wood2"], f, studs=False)
    board = b.part(m, "Shop sign", [0, 10.2, d / 2 + 1.2], [w - 2.2, 2.3, 0.6], P["navy"], f, studs=False, mat=SMOOTH)
    b.lettering(board, title, 2, "FFE9B0", 40, 64)
    # Two lanterns under the awning, one lit for the counter.
    for s in (-1, 1):
        b.part(m, "Lantern cord", [s * (w / 2 - 2.4), 7.6, d / 2 + 0.4], [0.16, 1.2, 0.16], P["iron"], f, solid=False, mat=SMOOTH, studs=False)
        g = b.part(m, "Glass lamp", [s * (w / 2 - 2.4), 6.7, d / 2 + 0.4], [0.9, 1.0, 0.9], "FFE0A0", f, solid=False, shadow=False, mat=NEON)
        if s < 0:
            b.light(g, "FFCE8C", 15, 0.42)
    # The service pad keeps its prompt. Only its place changes.
    src = next(c for c in CORE[key].findall("Item") if name(c) == pad_name)
    mat = b.adopt(m, src)
    move(mat, f.at([0, 0.18, pad_z]), yaw)
    field(mat, "Color3uint8", "Color3uint8", 0xFF000000 | int(P[tone], 16))
    for c in list(mat.findall("Item")):
        if c.get("class") == "PointLight":
            mat.remove(c)
    s = xyz(mat, "size")
    b.part(m, "Pad rim", [0, 0.02, pad_z], [s[0] + 0.9, 0.2, s[2] + 0.9], P["citrine2"], f, studs=False, solid=True, mat=SMOOTH)
    tag = b.adopt(m, next(c for c in CORE[key].findall("Item") if name(c) == "Name tag"))
    move(tag, f.at([0, tag_h + 6.2, 0]))
    station(tag)
    return f, m


# Sell and Upgrades stand at the mouth of the mine: dig, sell, upgrade, dig.
square = group("Sand path and bridge")
b.pad(square, "Market square", 0, 15.5, 61, 18, 23.4, 24.24, P["stone"], 5)
b.pad(square, "Forecourt ring", 0, 15.5, 20, 16, 23.4, 24.34, P["sand"], 5)
f, m = stall("Sell", group("Shore market", "Sell"), -19.5, 10.6, 0, 24.24, "coral", "cream2", "SELL ORE", pad_name="Service mat", pad_z=9.05, w=13)
for i, (x, y, z) in enumerate(((-2.2, 3.65, 3.0), (0, 3.65, 3.2), (2.2, 3.65, 3.0), (-1.1, 4.75, 3.1), (1.1, 4.75, 3.1), (0, 5.85, 3.1))):
    b.part(m, "Gold ingot", [x, y + 0.5, z], [2.0, 1.0, 1.3], P["citrine" if i % 2 else "citrine2"], f, mat=SMOOTH, studs=False, shine=0.1)
for i, (dx, dy, r) in enumerate(((-1.7, 14.1, 1.9), (1.6, 14.0, 1.7), (0, 16.2, 2.2))):
    b.part(m, "Bullion emblem", [dx, dy, 0.6], [0.8, r * 2, r * 2], P["citrine"], f, ry(90), mat=SMOOTH, studs=False, shape=2, solid=False)
    b.part(m, "Bullion shine", [dx, dy, 1.02], [0.3, r * 1.35, r * 1.35], P["citrine2"], f, ry(90), mat=SMOOTH, studs=False, shape=2, solid=False)
for x, z in ((-8.9, 3.2), (-9.4, 0.2)):
    sack(m, *f.at([x, 0, z]), yaw=20 * x)
g = f.at([9.6, 0, 2.2])
ore_pile(m, g[0] - 0.3, 24.24, g[2], 2.6, (P["slate2"] and "slate2", "citrine", "honey"), 8)

f, m = stall("Upgrades", group("Shore market", "Upgrades"), 19.5, 10.6, 0, 24.24, "teal", "cream2", "UPGRADES", pad_name="Service mat", pad_z=9.05, w=13)
b.part(m, "Anvil foot", [2.6, 4.1, 3.0], [1.6, 1.0, 1.2], P["iron"], f, mat=SMOOTH)
b.part(m, "Anvil", [2.6, 5.0, 3.0], [3.4, 0.9, 1.5], P["iron2"], f, mat=SMOOTH, studs=False)
b.part(m, "Forge", [-3.6, 3.0, -2.2], [3.6, 4.6, 2.6], P["slate3"], f)
fire = b.part(m, "Forge fire", [-3.6, 4.0, -0.8], [2.2, 1.4, 0.4], "FF9A3C", f, mat=NEON, solid=False)
b.light(fire, "FF9A4A", 11, 0.5)
b.part(m, "Chimney", [-3.6, 13.6, -2.2], [2.6, 5.4, 2.6], P["slate2"], f)
b.part(m, "Chimney cap", [-3.6, 16.5, -2.2], [3.3, 0.8, 3.3], P["slate3"], f)
b.part(m, "Pick emblem haft", [1.8, 15.3, 0.6], [0.9, 6.6, 0.9], P["wood3"], f, rz(-34), mat=SMOOTH, studs=False, solid=False)
for s, a in ((-1, 34), (1, -2)):
    pass
b.part(m, "Pick emblem head", [3.4, 17.9, 0.6], [6.2, 1.2, 1.2], "9FE8EE", f, rz(-34), mat=SMOOTH, studs=False, solid=False, shine=0.1)
barrel(m, *f.at([8.9, 0, 1.0]), tone="teal")

# The four services stand in an arc and face spawn.
SHOPS = (
    ("Jobs", -27.5, 59.0, 46, "honey", "cream2", "JOBS"),
    ("Store", 27.5, 59.0, -46, "pink", "cream2", "OUTFITTERS"),
    ("Supplies", -44.0, 86.0, 90, "leafgold", "wood3", "SUPPLIES"),
    ("Book", 44.0, 86.0, -90, "grass3", "cream2", "ORE INDEX"),
)
shops = {}
for key, x, z, yaw, t1, t2, title in SHOPS:
    shops[key] = stall(key, group("Harbor Plaza", key), x, z, yaw, 24.48, t1, t2, title)

f, m = shops["Jobs"]
board = b.part(m, "Notice cork", [0, 5.2, -3.3], [9.4, 4.4, 0.4], P["wood3"], f)
for i, (x, y, r) in enumerate(((-3.2, 5.6, 4), (-0.9, 4.9, -5), (1.5, 5.8, 3), (3.4, 4.8, -3))):
    b.part(m, "Work order", [x, y, -3.02], [1.7, 2.1, 0.16], P["cream2"], f, rz(r), mat=SMOOTH, studs=False, solid=False)
    b.part(m, "Wax seal", [x, y - 0.6, -2.9], [0.5, 0.5, 0.1], P[("coral", "violet", "teal", "citrine")[i]], f, rz(45), mat=SMOOTH, studs=False, solid=False)
b.part(m, "Scroll emblem", [0, 14.9, 0.4], [5.6, 3.2, 0.7], P["cream2"], f, mat=SMOOTH, studs=False, solid=False)
for s in (-1, 1):
    b.part(m, "Scroll roll", [s * 3.0, 14.9, 0.4], [1.2, 3.9, 1.2], P["sand2"], f, mat=SMOOTH, studs=False, solid=False)
for k in (-0.8, 0, 0.8):
    b.part(m, "Scroll line", [0, 14.9 + k, 0.8], [3.8, 0.3, 0.1], P["wood2"], f, mat=SMOOTH, studs=False, solid=False)
crate(m, *f.at([9.6, 0, 0.6]), 2.6, 20)

f, m = shops["Store"]
for i, (x, c) in enumerate(((-3.6, "violet"), (-1.2, "teal"), (1.2, "coral"), (3.6, "citrine"))):
    b.part(m, "Display hat", [x, 4.1, 3.0], [1.9, 0.35, 1.9], P[c], f, mat=SMOOTH, studs=False)
    b.part(m, "Display hat", [x, 4.6, 3.0], [1.2, 1.0, 1.2], P[c], f, mat=SMOOTH, studs=False)
b.part(m, "Hat emblem", [0, 14.0, 0.4], [6.2, 0.9, 6.2], P["coral"], f, mat=SMOOTH, studs=False, solid=False)
b.part(m, "Hat emblem", [0, 15.6, 0.4], [3.8, 2.6, 3.8], P["coral"], f, mat=SMOOTH, studs=False, solid=False)
b.part(m, "Hat band", [0, 14.9, 0.4], [4.0, 0.8, 4.0], P["citrine"], f, mat=SMOOTH, studs=False, solid=False)
cluster(m, 8.8, 0.2, 1.6, 1.6, (P["violet"], P["lilac"]), 3, fr=f)

f, m = shops["Supplies"]
for i in range(3):
    b.part(m, "Survey flare", [-3.8 + i * 1.1, 4.7, 3.0], [0.5, 2.0, 0.5], P["coral"], f, mat=SMOOTH, studs=False)
    b.part(m, "Signal lens", [-3.8 + i * 1.1, 5.8, 3.0], [0.56, 0.3, 0.56], "FFE7A8", f, mat=NEON, studs=False, solid=False)
for i in range(3):
    b.part(m, "Fuel coal", [1.4 + i * 1.3, 4.2, 3.0], [1.1, 1.0, 1.1], P["ink"], f, ry(25 * i), mat=SMOOTH, studs=False)
b.part(m, "Lantern emblem", [0, 15.4, 0.4], [2.6, 3.0, 2.6], "FFE0A0", f, mat=NEON, studs=False, solid=False)
for y, s in ((13.6, 3.6), (17.2, 3.6), (18.0, 1.8)):
    b.part(m, "Lantern cap", [0, y, 0.4], [s, 0.7, s], P["iron"], f, mat=SMOOTH, studs=False, solid=False)
for x, z in ((9.4, 1.8), (9.6, -1.4), (-9.4, 0.8)):
    barrel(m, *f.at([x, 0, z]), tone="wood3")
crate(m, *f.at([-9.6, 0, -2.6]), 2.4, 8)

f, m = shops["Book"]
for s in (-1, 1):
    b.part(m, "Book cover", [s * 2.0, 15.0, 0.4], [4.0, 4.6, 0.5], P["grass3"], f, ry(-s * 24), mat=SMOOTH, studs=False, solid=False)
    b.part(m, "Book page", [s * 1.9, 15.0, 0.75], [3.6, 4.1, 0.5], P["cream2"], f, ry(-s * 24), mat=SMOOTH, studs=False, solid=False)
# One chunk per ore that is not secret, in the ore's own colour.
text = (HERE.parent / "src/shared/Ores.luau").read_text(encoding="utf8")
found = []
for entry in re.findall(r"\n\t\{\n(.*?)\n\t\},", text, re.S):
    title, ink = re.search(r'name = "([A-Za-z]+)"', entry), re.search(r"\tcolor = (?:Color3\.from)?(?:rgb|RGB)\((\d+), (\d+), (\d+)\)", entry)
    if title and ink and "host = true" not in entry and "secret" not in entry:
        found.append((title.group(1), "%02X%02X%02X" % tuple(int(v) for v in ink.groups())))
assert len(found) >= 15, "Ores.luau has changed shape"
for i, (ore, ink) in enumerate(found[:24]):
    row = i // 9
    k = i % 9
    b.part(m, ore + " chunk", [-4.4 + k * 1.1 + 0.3 * row, 4.15 + row * 0.7, 3.4 - row * 0.5], [0.95, 0.85, 0.95], ink, f, matmul(ry(17 * i), rz(8)), mat=SMOOTH, studs=False)
for i, c in enumerate(("coral", "teal", "violet", "citrine", "navy", "leafgold", "grass3")):
    b.part(m, "Index volume", [-4.2 + i * 0.75, 5.3, -3.0], [0.62, 2.0 + 0.2 * (i % 3), 1.4], P[c], f, mat=SMOOTH, studs=False)
b.part(m, "Index shelf", [0, 4.1, -2.9], [10.5, 0.4, 2.0], P["wood2"], f, studs=False)
cluster(m, 9.2, 0.2, 0.8, 1.4, (P["citrine"], P["citrine2"]), 3, fr=f)

# ---------------------------------------------------------------- canal
main = group("Sand path and bridge")
for i in range(12):
    z = 28.6 + i * 1.29
    y = 24.42 + 0.42 * math.sin((i + 0.5) / 12 * math.pi)
    b.part(main, "Bridge plank", [0, y, z], [11.4, 0.45, 1.2], P["plank" if i % 2 else "wood3"])
for s in (-1, 1):
    for z in (28.6, 35.7, 42.8):
        b.part(main, "Bridge post", [s * 5.9, 25.2, z], [1.4, 4.4, 1.4], P["slate2"])
        b.part(main, "Post cap", [s * 5.9, 27.6, z], [1.9, 0.6, 1.9], P["citrine"])
    for z in (32.1, 39.3):
        for y in (25.6, 26.6):
            b.part(main, "Handrail", [s * 5.9, y, z], [0.5, 0.5, 6.0], P["wood"], studs=False)
# Stone coping where the banks meet the water, broken by the bridges and stairs.
bank = group("Canal banks")
for side, z, top in ((1, 33.4, 22.7), (-1, 37.6, 22.7)):
    x = -60.0
    while x < 60:
        w = rng.uniform(3.6, 6.4)
        if not any(abs(x + w / 2 - c) < 5.6 for c in (0, -41, 41, -28, 28, -15, 15, -50, -58, 54)):
            b.part(bank, "Bank stone", [x + w / 2, top - 0.9 + rng.uniform(0, 0.4), z + rng.uniform(-0.3, 0.3)], [w, 2.4, 2.2], P[("stone2", "slate2", "stone")[rng.randrange(3)]], rot=ry(rng.uniform(-4, 4)))
        x += w + 0.3
for i in range(26):
    x = rng.uniform(-58, 58)
    z = rng.choice((33.0, 38.0)) + rng.uniform(-0.6, 0.6)
    if any(abs(x - c) < 5.4 for c in (0, -41, 41, -28, 28, -15, 15, -50, -58, 54)):
        continue
    for j in range(4):
        b.part(bank, "Reed", [x + 0.35 * j, 22.3 + rng.uniform(0, 0.5), z + rng.uniform(-0.3, 0.3)], [0.22, 3.0 + rng.uniform(0, 1), 0.22], P["grass3" if j % 2 else "moss"], rot=rz(rng.uniform(-7, 7)), solid=False, shadow=False, mat=SMOOTH)
for i in range(16):
    x, z = rng.uniform(-56, 56), rng.uniform(34.4, 36.6)
    if abs(x) < 7 or abs(abs(x) - 41) < 5:
        continue
    b.part(bank, "Lily pad", [x, 20.5, z], [0.16, 1.9, 1.9], P["grass3"], rot=rz(90), solid=False, shadow=False, mat=SMOOTH, shape=2)
    if i % 2:
        b.part(bank, "Lily", [x, 20.8, z], [0.8, 0.5, 0.8], P["pink" if i % 4 else "cream2"], rot=ry(40), solid=False, shadow=False, mat=SMOOTH)

# ---------------------------------------------------------------- the Star Gate
gate = group("Citrine Mine")
keep(CORE["Citrine Mine"], gate, studs=False, solid=False, table={})
for s in (-1, 1):
    b.part(gate, "Cave jamb", [s * 12.4, 29.6, 4.4], [6.4, 12.4, 6.4], P["slate3"])
    b.part(gate, "Cave jamb", [s * 14.6, 27.0, 5.6], [6.8, 7.2, 8.0], P["slate"], rot=ry(s * 9))
    b.part(gate, "Cave shoulder", [s * 11.2, 38.2, 4.2], [9.0, 6.4, 7.6], P["slate"], rot=rz(-s * 10))
    b.part(gate, "Cave shoulder", [s * 16.4, 34.0, 4.8], [7.4, 7.6, 7.0], P["slate2"], rot=matmul(ry(s * 14), rz(-s * 8)))
    b.part(gate, "Portal footing", [s * 10.6, 24.9, 8.4], [4.8, 1.8, 4.8], P["slate2"])
    for y, w in ((27.4, 3.4), (30.6, 3.0), (33.6, 3.4)):
        b.part(gate, "Cut basalt pier", [s * 10.4, y, 8.4], [w, 3.1, 3.0], P["slate"])
    b.part(gate, "Arch voussoir", [s * 9.1, 36.1, 8.5], [4.0, 3.8, 2.9], P["slate2"], rot=rz(-s * 36))
    b.part(gate, "Arch voussoir", [s * 5.9, 38.0, 8.62], [4.2, 3.8, 2.9], P["slate"], rot=rz(-s * 17))
    b.part(gate, "Brass reveal", [s * 8.55, 29.6, 9.3], [0.35, 10.2, 0.35], P["citrine"], studs=False, solid=False, mat=SMOOTH)
    # Timber sets just inside, so the way in reads as a working mine.
    b.part(gate, "Pit prop", [s * 8.3, 29.6, 2.6], [1.3, 11.0, 1.3], P["wood"], studs=False)
    b.part(gate, "Sconce base", [s * 10.4, 29.2, 10.2], [1.7, 0.6, 1.5], P["iron"], studs=False, mat=SMOOTH)
    # Starfall in the stone either side.
    cluster(gate, s * 17.6, 24.2, 9.6, 2.3, (P["violet"], P["lilac"], P["plum"]), 5)
    cluster(gate, s * 13.6, 24.2, 10.8, 1.3, (P["lilac"], P["violet"]), 3)
    for i, (x, y, w, h, r) in enumerate(((14.4, 26.6, 0.5, 4.6, 16), (13.9, 30.4, 0.42, 4.2, -20), (15.2, 33.6, 0.42, 4.6, 26), (17.2, 36.0, 0.34, 3.2, -14), (10.6, 37.2, 0.3, 3.0, 40))):
        b.part(gate, "Starfall vein", [s * x, y, 8.6], [w, h, 2.2 if y < 31 else 1.6], "A86BFF", rot=rz(-s * r), studs=False, solid=False, shadow=False, mat=NEON)
b.part(gate, "Capstone", [0, 41.8, 4.7], [21.0, 5.6, 7.4], P["slate3"])
b.part(gate, "Capstone", [0, 44.9, 3.6], [16.0, 2.2, 7.6], P["slate"])
b.part(gate, "Capstone", [0, 46.4, 3.2], [11.0, 1.6, 6.6], P["slate2"])
b.part(gate, "Cap beam", [0, 35.6, 2.6], [18.4, 1.4, 1.6], P["wood2"], studs=False)
b.part(gate, "Painted edge", [0, 42.6, 10.2], [17.4, 4.9, 0.8], P["honey"], studs=False)
sign = b.part(gate, "Mine sign", [0, 42.6, 10.55], [16.4, 4.0, 0.6], P["ink"], studs=False, mat=SMOOTH)
b.lettering(sign, "CITRINE MINE", 2, "FFD76A", 30, 70)
for s in (-1, 1):
    b.part(gate, "Sign bracket", [s * 6.4, 44.2, 8.9], [1.0, 1.0, 2.4], P["iron"], studs=False, solid=False, mat=SMOOTH)
for s in (-1, 1):
    g = b.part(gate, "Starfall heart", [s * 17.4, 26.6, 10.6], [0.4, 0.4, 0.4], "C79BFF", studs=False, solid=False, mat=SMOOTH, alpha=1, shadow=False)
    b.light(g, "9A5CFF", 14, 0.6)
crown = group("Citrine Mine", "Citrine outcrop")
g = b.part(crown, "Crown heart", [0, 50.0, 9.0], [0.6, 0.6, 0.6], "FFE08A", studs=False, solid=False, mat=SMOOTH, alpha=1, shadow=False)
b.light(g, "FFC44A", 18, 0.5)
for x, z, h, w, tilt, ink in ((0, 3.4, 17, 5.2, 0, "citrine"), (-5.0, 3.0, 11.5, 3.8, 14, "honey"), (5.0, 3.2, 12.5, 3.8, -13, "citrine2"), (-8.4, 3.8, 7, 2.8, 26, "citrine2"),
                              (8.6, 3.6, 7.4, 2.8, -25, "honey"), (-2.4, 6.0, 7.5, 2.4, 8, "citrine2"), (2.8, 5.8, 6.4, 2.2, -10, "honey")):
    crystal(crown, x, 45.4, z, h, w, P[ink], yaw=13 * x, tilt=tilt, solid=False)
# The terraces that carry the gate. Nothing here enters the hall behind it.
front = group("Honey bluffs")
for s in (-1, 1):
    mesa(front, s * 24.6, 4.6, 17.4, 6.6, 23.2, 38.2, 1.6)
    mesa(front, s * 43.0, 1.2, 22.0, 17.0, 23.0, 34.0, 4)
    mesa(front, s * 46.2, -19.0, 28.0, 32.0, 23.0, 40.0, 4)
    mesa(front, s * 49.6, -42.0, 34.0, 21.0, 23.0, 46.6, 4)
    mesa(front, s * 69.0, -27.0, 26.0, 30.0, 23.0, 37.8, 5)
    mesa(front, s * 88.0, -24.0, 18.0, 22.0, 23.0, 31.0, 4)
    mesa(front, s * 60.5, -6.5, 17.0, 17.0, 23.0, 30.0, 4) if s < 0 else None
    # A shoulder of rock closes the corner between the hall, the gate and the hill.
    b.box(front, "Weathered sandstone", min(s * 31.5, s * 36.5), max(s * 31.5, s * 36.5), 23.0, 35.6, -12, 5.0, P["clay"])
    b.box(front, "Grass shelf", min(s * 31.2, s * 37.0), max(s * 31.2, s * 37.0), 35.6, 37.0, -12.2, 5.4, P["grass2"])
for s in (-1, 1):
    b.box(front, "Weathered sandstone", min(s * 31.45, s * 34.2), max(s * 31.45, s * 34.2), 23.0, 37.9, -64, -12.1, P["clay"])
# Over the hall. It starts above the stone canopy.
b.pad(front, "Weathered sandstone", 0, -24.2, 66, 52.0, 38.02, 41.9, P["amber"], 2)
b.pad(front, "Grass shelf", 0, -24.2, 67, 53.0, 41.9, 43.4, P["grass"], 2.4)
mesa(front, -15, -31, 23, 24, 43.0, 50.6, 5)
mesa(front, 17, -29, 19, 22, 43.0, 48.0, 5)
mesa(front, -14, -33, 12, 13, 50.2, 56, 3)
b.part(front, "Rear roof ramp", [0, 39.9, -54.6], [13.0, 7.2, 9.0], P["grass"], cl="WedgePart")
# Bank of rock behind the hall keeps the back wall closed.
b.box(front, "Weathered sandstone", -36, 36, 23.2, 35.62, -74.2, -64.4, P["clay"])

look = group("Gate overlook")
fence(look, [(-32, 0.6), (-14, 0.6)], 43.4)
fence(look, [(14, 0.6), (32, 0.6)], 43.4)
for s in (-1, 1):
    bench(look, s * 24, 43.4, -6, 0)
    lamp(look, s * 30, 43.4, -3, lit=False)
    leafy(look, s * 28, -14, 43.4, 0.95)
slab_path(look, [(0, -50), (0, -42), (4, -18), (22, -8)], 5, 43.4, "path")
slab_path(look, [(2, -18), (-22, -8)], 5, 43.38, "path")

# ---------------------------------------------------------------- northern mesas
north = group("Citrine Highlands", "Northern mesas")
PEAKS = ((-106, -92, 40, 28, 56), (-70, -93, 38, 32, 78), (-35, -94, 38, 30, 94), (3, -96, 44, 36, 112), (41, -94, 38, 31, 86), (76, -95, 38, 34, 100), (109, -92, 34, 28, 58))
for k, (x, z, w, d, top) in enumerate(PEAKS):
    h = top - 24
    falls_peak = k == 5
    lab = "Falls cliff" if falls_peak else "Weathered sandstone"
    z += (0.0, -0.5, 0.37, -0.2, 0.6, 0.0, -0.4)[k]
    mesa(north, x, z, w, d, 23 + 0.11 * k, 24 + h * 0.46, 6, label=lab)
    mesa(north, x, z - 4, w * 0.80, d * 0.74, 24 + h * 0.42, 24 + h * 0.76, 6, label=lab)
    mesa(north, x, z - 7, w * 0.54, d * 0.48, 24 + h * 0.72, top, 4, label=lab)
for x, z, y in ((-70, -80.5, 48.84), (41, -82, 52.52), (-106, -82, 38.72), (3, -82, 64.48), (-35, -82.5, 56.2)):
    for k in range(3):
        pine(north, x + (k - 1) * 6, z + (k % 2) * 3, y, rng.uniform(1.0, 1.4))
cluster(north, 16, 64.48, -82, 4.2, (P["citrine"], P["honey"], P["citrine2"]), 5)
cluster(north, -24, 56.2, -82.5, 3.2, (P["violet"], P["lilac"], P["plum"]), 4)

# The corners are closed by stepped bluffs that run from the shore up to the peaks, outside the
# ridge trail.
for s in (-1, 1):
    for x, z, w, d, top, c in ((130, -8, 13, 22, 36, 3), (131, -27, 14, 24, 45, 4), (130, -50, 16, 26, 53.5, 5), (126, -72, 24, 22, 49, 5), (136, -62, 14, 20, 60, 4)):
        mesa(north, s * x, z, w, d, 23, top, c)
    for x, z, w, d, top in ((114.5, -68, 10, 10, 41, ), (121.5, -60, 7, 9, 45.5)):
        mesa(north, s * x, z, w, d, 24, top, 3)
    mesa(north, s * 88, -44, 20, 16, 24, 42, 4)
    for x, z, y, kind in ((130, -24, 45, pine), (131, -33, 45, pine), (130, -48, 53.5, leafy), (124, -74, 49, pine), (131, -76, 49, pine), (130, -6, 36, leafy), (88, -44, 42, pine), (114.5, -69, 41, pine)):
        kind(north, s * x, z, y, rng.uniform(0.9, 1.15))

# The ridge trail keeps its line. Posts and planting mark it.
ridge = group("Citrine Highlands", "Ridge dressing")
for s in (-1, 1):
    for x, z, y in ((110.5, -12, 27.8), (104, -62, 35.9), (92, -71, 35.9)):
        pine(ridge, s * x, z, y - 0.1, rng.uniform(0.85, 1.15))
    for x, z in ((54, -62), (14, -63), (76, -60)):
        rock(ridge, s * x, 35.9, z, rng.uniform(2.2, 3.2), ("stone2", "slate2", "stone"))
    for x, z, y in ((109.6, -2, 25.4), (109.4, -24, 29.6), (96, -52, 35.2), (44, -64, 36.0), (30, -63.4, 36.0), (84, -58, 36.0)):
        bush(ridge, s * x, y, z, rng.uniform(0.9, 1.3), bloom=("lilac", "citrine2", "coral")[int(x) % 3])
        flowers(ridge, s * x + 2.2, y, z + 1.6, 4, 1.0)
    lamp(ridge, s * 66, 36.0, -64.5, lit=True)
    lamp(ridge, s * 110.6, 25.1, 5, lit=True)
    bench(ridge, s * 20, 36.0, -64.2, 0)

# ---------------------------------------------------------------- falls and spring
falls = group("Highland falls")
# Two drops down the front of the eastern peak. Each starts in water and lands in water.
FX, T1, T2 = 76.0, 24 + 76 * 0.46, 24 + 76 * 0.76
Z2, Z1 = -95 - 4 + 34 * 0.37 + 0.75, -95 + 17 + 0.75


def sheet(parent, x, z, y0, y1, w, foam=3):
    """Falling water: a lip that bends over the edge, the sheet, and streaks laid on its face."""
    b.part(parent, "Falling water", [x, (y0 + y1) / 2, z + 0.45], [w, y1 - y0, 0.7], P["water"], mat=SMOOTH, solid=False, studs=False)
    b.part(parent, "Falls lip", [x, y1 + 0.05, z + 0.1], [w, 0.7, 1.7], P["water"], mat=SMOOTH, solid=False, studs=False)
    for k in range(foam):
        h = (y1 - y0) * (0.72 - 0.16 * (k % 2))
        b.part(parent, "Current", [x + (k - (foam - 1) / 2) * w / foam + 0.3, y1 - 0.6 - h / 2 - 1.1 * (k % 3), z + 0.84], [0.55 + 0.25 * (k % 2), h, 0.16], P["foam"],
               mat=SMOOTH, solid=False, studs=False, shadow=False)


def foam_line(parent, x, z, y, w):
    for k in range(int(w / 1.5)):
        b.part(parent, "Whitewater", [x - w / 2 + 0.9 + k * 1.5, y + 0.25 + 0.14 * (k % 2), z + 1.4 + 0.35 * (k % 2)], [1.35, 0.7, 1.2], P["foam"], rot=ry(17 * k), mat=SMOOTH, solid=False, studs=False, shadow=False)


# The source: a pool set into the middle tier.
b.pad(falls, "Spring rim", FX, Z2 - 4.4, 12.6, 6.0, T2 - 0.4, T2 + 0.9, P["slate2"], 2)
b.pad(falls, "Spring run", FX, Z2 - 4.0, 9.4, 4.6, T2 - 0.2, T2 + 1.05, P["water"], 1.2, mat=SMOOTH, studs=False, solid=False)
b.box(falls, "Falls bed", FX - 4.6, FX + 4.6, T2 - 0.2, T2 + 0.5, Z2 - 3, Z2 - 0.1, P["water"], mat=SMOOTH, solid=False, studs=False)
sheet(falls, FX, Z2 - 0.4, T1 + 0.3, T2 + 0.6, 8.2, 3)
b.pad(falls, "Ledge rim", FX, (Z2 + Z1) / 2 - 0.3, 13.0, Z1 - Z2 - 1.2, T1 - 0.4, T1 + 0.75, P["slate2"], 1.6)
b.box(falls, "Falls bed", FX - 4.9, FX + 4.9, T1 - 0.2, T1 + 0.95, Z2 + 0.7, Z1 - 0.1, P["water"], mat=SMOOTH, solid=False, studs=False)
foam_line(falls, FX, Z2 - 0.4, T1 + 0.9, 8.0)
sheet(falls, FX, Z1 - 0.4, 36.4, T1 + 1.0, 8.8, 4)
b.pad(falls, "Plunge rim", FX, Z1 + 3.6, 14.0, 7.0, 34.6, 36.9, P["slate2"], 2.2)
b.pad(falls, "Plunge pool", FX, Z1 + 3.2, 11.4, 5.6, 35.4, 37.0, P["water"], 1.6, solid=False, mat=SMOOTH, studs=False)
foam_line(falls, FX, Z1 - 0.4, 36.9, 8.4)
# The garden spring: its own bluff, a pool in the turf, one drop to a basin, and a run to the canal.
lower = group("Garden falls")
mesa(lower, 65.0, -4.5, 17.0, 19.0, 23.0, 32.4, 3, label="Falls cliff")
GZ = -4.5 + 9.5 + 0.75
b.pad(lower, "Spring rim", 65.0, 1.8, 10.4, 6.0, 31.6, 33.1, P["slate2"], 1.8)
b.box(lower, "Spring run", 65.0 - 3.6, 65.0 + 3.6, 31.8, 33.2, 0.2, GZ - 0.1, P["water"], mat=SMOOTH, solid=False, studs=False)
sheet(lower, 65.0, GZ - 0.4, 24.4, 33.2, 6.6, 3)
b.pad(lower, "Pool rim", 65.0, GZ + 5.2, 14.0, 10.6, 23.2, 24.8, P["slate2"], 2.6)
b.pad(lower, "Pool water", 65.0, GZ + 4.9, 11.2, 8.6, 23.6, 24.95, P["water"], 2.0, solid=False, mat=SMOOTH, studs=False)
foam_line(lower, 65.0, GZ - 0.4, 24.8, 6.6)
b.box(lower, "Spill trough", 62.2, 67.8, 23.0, 24.4, GZ + 10.6, 28.4, P["slate2"])
b.box(lower, "Spill water", 63.2, 66.8, 24.0, 24.56, GZ + 9.6, 28.5, P["water"], mat=SMOOTH, solid=False, studs=False)
sheet(lower, 65.0, 28.4, 20.4, 24.4, 3.6, 2)
for x, z in ((57.0, 11), (73.2, 12), (57.4, 17), (60.0, 24), (70.6, 24)):
    rock(lower, x, 23.9, z, rng.uniform(1.6, 2.4), ("stone2", "slate2", "stone"))
for x, z in ((56.4, 14), (74.6, 8), (60.0, 21)):
    flowers(lower, x, 24.0, z, 5, 1.1, ("lilac", "cream2", "pink"))

# ---------------------------------------------------------------- west: the ore yard
yard = group("Citrine Highlands", "Ore siding")
terrace(yard, -87, 21, 34, 46, 23.0, 29.0, 6, 0, "stone2", "clay")
b.pad(yard, "Yard floor", -87, 21, 30, 42, 28.4, 29.12, P["path2"], 5)
steps(yard, -68.2, 14, 9, 24.0, 29.1, 7.4, 90)
steps(yard, -87, 46.6, 9, 24.0, 29.1, 7.2, 0)
fence(yard, [(-70.6, 20), (-70.6, 37), (-75, 43), (-81, 43.4)], 29.1)
fence(yard, [(-93, 43.4), (-99, 43.2), (-103.4, 38), (-103.4, 4)], 29.1)
# The adit: rails come out of the hill and end at the tipple over the dock.
mesa(front, -93, -8.6, 34, 13.2, 23.0, 41.0, 3)
for s in (-1, 1):
    b.part(yard, "Adit prop", [-92 + s * 4.6, 33.2, -1.4], [1.5, 8.4, 1.5], P["wood"], studs=False)
    b.part(yard, "Adit stone", [-92 + s * 6.8, 32.4, -1.8], [3.4, 7.2, 3.4], P["slate2"], rot=ry(s * 12))
b.part(yard, "Adit lintel", [-92, 38.0, -1.4], [12.4, 1.8, 2.0], P["wood2"], studs=False)
b.part(yard, "Adit stone", [-92, 39.4, -1.6], [15.0, 2.2, 3.4], P["slate"])
b.part(yard, "Adit dark", [-92, 33.0, -2.25], [7.8, 8.2, 0.4], "1B1626", studs=False, mat=SMOOTH)
g = b.part(yard, "Adit lamp", [-92, 36.4, -0.8], [1.0, 1.1, 1.0], "FFDFA0", studs=False, mat=NEON, solid=False)
b.light(g, "FFC987", 17, 0.6)
RAILZ = (-2.0, 36.0)
for s in (-1, 1):
    b.part(yard, "Rail", [-92 + s * 2.1, 29.62, sum(RAILZ) / 2], [0.4, 0.5, RAILZ[1] - RAILZ[0]], P["iron2"], studs=False, mat=METAL)
z = RAILZ[0] + 0.8
while z < RAILZ[1]:
    b.part(yard, "Sleeper", [-92, 29.24, z], [6.4, 0.4, 1.1], P["wood2"], studs=False)
    z += 2.0
for z, load in ((6, ("slate2", "citrine", "slate")), (12.4, ("slate", "honey", "citrine2")), (31.6, ("slate2", "violet", "slate"))):
    cart(yard, -92, 29.36, z, 0, load)
b.part(yard, "Rail stop", [-92, 30.4, 35.6], [6.4, 1.7, 1.2], P["coral"])
# Headframe over the sorting floor.
hx, hz = -80, 10
for sx in (-1, 1):
    for sz in (-1, 1):
        b.part(yard, "Headframe leg", [hx + sx * 3.2, 37.6, hz + sz * 3.2], [1.2, 17.2, 1.2], P["wood2"], rot=matmul(rz(sx * 6), rx(-sz * 6)), studs=False)
        b.part(yard, "Headframe foot", [hx + sx * 4.2, 29.6, hz + sz * 4.2], [2.2, 1.4, 2.2], P["slate2"])
for y, w in ((34, 9.0), (40, 7.6), (45.6, 6.6)):
    for k in (-1, 1):
        b.part(yard, "Headframe brace", [hx, y, hz + k * w * 0.40], [w, 0.8, 0.8], P["wood"], studs=False)
        b.part(yard, "Headframe brace", [hx + k * w * 0.40, y, hz], [0.8, 0.8, w], P["wood"], studs=False)
b.part(yard, "Headframe deck", [hx, 46.3, hz], [8.4, 0.7, 8.4], P["plank"])
b.part(yard, "Headframe roof", [hx, 51.2, hz], [9.6, 1.1, 9.6], P["coral"])
b.part(yard, "Headframe roof", [hx, 52.2, hz], [6.4, 1.1, 6.4], P["cream2"])
b.part(yard, "Headframe roof", [hx, 53.2, hz], [3.2, 1.1, 3.2], P["coral"])
for sx in (-1, 1):
    for sz in (-1, 1):
        b.part(yard, "Headframe post", [hx + sx * 3.2, 48.8, hz + sz * 3.2], [0.8, 4.4, 0.8], P["wood2"], studs=False)
for t in (0, 45, 90, 135):
    b.part(yard, "Winding wheel", [hx, 48.9, hz], [0.6, 4.2, 0.6], P["citrine"], rot=rz(t), studs=False, mat=SMOOTH, solid=False)
b.part(yard, "Winding wheel", [hx, 48.9, hz], [0.5, 1.6, 1.6], P["iron"], rot=ry(90), studs=False, mat=SMOOTH, shape=2, solid=False)
b.part(yard, "Hoist cable", [hx, 39.4, hz], [0.2, 14, 0.2], P["iron"], studs=False, mat=SMOOTH, solid=False)
b.part(yard, "Hoist bucket", [hx, 31.6, hz], [3.0, 2.6, 3.0], P["iron2"], studs=False)
ore_pile(yard, hx, 32.6, hz, 2.6, ("slate2", "citrine", "honey"), 7)
for x, z, s, t in ((-76, 24, 4.4, ("slate2", "slate", "citrine")), (-76.5, 32, 3.6, ("rust", "honey", "amber")), (-99, 26, 4.2, ("slate", "violet", "slate2"))):
    b.part(yard, "Ore bay", [x, 29.6, z], [s + 2.4, 1.0, s + 2.4], P["wood2"])
    ore_pile(yard, x, 30.0, z, s, t, 11)
for x, z, s, r in ((-99.6, 10, 2.8, 10), (-99.4, 13.4, 2.2, 40), (-99.8, 10.2, 2.0, 24), (-74.4, 4.0, 2.6, 14), (-77.4, 3.2, 2.2, 50)):
    crate(yard, x, 29.1 if (x, z) != (-99.8, 10.2) else 31.9, z, s, r)
for x, z in ((-73.6, 7.2), (-101, 18), (-101, 20.4), (-82, 39.8)):
    barrel(yard, x, 29.1, z)
lamp(yard, -73.4, 29.1, 18.6, lit=True)
lamp(yard, -101.2, 29.1, 33, lit=True)
lamp(yard, -84, 29.1, 41, lit=False)
# Dock and crane at the canal's west end.
dock = group("Harbor Plaza", "Loading dock")
b.pad(dock, "Wharf piling", -62, 29.6, 16, 16, 20.6, 23.8, P["wood2"], 3)
b.pad(dock, "Wharf deck", -62, 29.6, 17, 17, 23.6, 24.4, P["plank"], 3)
b.part(dock, "Crane foot", [-64, 25.2, 29], [4.6, 1.8, 4.6], P["slate2"])
b.part(dock, "Crane mast", [-64, 33.4, 29], [1.8, 15.6, 1.8], P["citrine"])
b.part(dock, "Crane jib", [-58.4, 41.0, 29], [15.4, 1.2, 1.4], P["citrine"])
b.part(dock, "Crane stay", [-60.8, 37.4, 29], [0.8, 9.0, 0.8], P["honey"], rot=rz(-42), studs=False)
b.part(dock, "Crane counterweight", [-67.4, 41.0, 29], [3.0, 2.8, 2.8], P["slate3"])
b.part(dock, "Hoist cable", [-52.2, 35.8, 29], [0.25, 9.8, 0.25], P["iron"], studs=False, mat=SMOOTH, solid=False)
b.part(dock, "Lift crate", [-52.2, 29.4, 29], [3.2, 3.0, 3.2], P["plank"])
b.part(dock, "Cargo strap", [-52.2, 29.4, 29], [3.4, 0.5, 3.4], P["wood2"], studs=False)
for x, z, s in ((-67.4, 34.4, 2.6), (-64.4, 35.2, 2.2), (-57.4, 35.0, 2.4)):
    crate(dock, x, 24.4, z, s, 17 * s)
barrel(dock, -68, 24.4, 24.6)
b.part(dock, "Ore barge", [-52.5, 21.1, 35.6], [13.0, 1.7, 4.4], P["wood"])
for s in (-1, 1):
    b.part(dock, "Barge side", [-52.5, 22.2, 35.6 + s * 2.2], [13.4, 1.6, 0.5], P["wood2"], studs=False)
    b.part(dock, "Barge end", [-52.5 + s * 6.7, 22.2, 35.6], [0.6, 1.9, 4.8], P["citrine"], studs=False)
ore_pile(dock, -52.5, 21.9, 35.6, 3.4, ("slate2", "citrine", "honey"), 9)

# ---------------------------------------------------------------- east: gardens and lighthouse
east = group("Citrine Highlands", "Compass gardens")
terrace(east, 89, 24, 34, 40, 23.0, 29.0, 6, 0, "grass", "clay", cap="Grass shelf")
b.pad(east, "Garden walk", 82, 24, 12, 34, 28.4, 29.14, P["path"], 4)
steps(east, 70.2, 36, 9, 24.0, 29.1, 7.4, -90)
steps(east, 89, 46.8, 9, 24.0, 29.1, 7.2, 0)
fence(east, [(72.6, 30), (72.6, 8), (77, 4.6), (100, 4.6)], 29.1)
fence(east, [(98, 43.8), (102, 42), (105.6, 37), (105.6, 12)], 29.1)
beacon = group("Harbor Plaza", "Beacon Point")
mesa(beacon, 95.2, 24, 18, 20, 28.6, 35.0, 4)
steps(beacon, 81.6, 24, 8, 29.1, 35.0, 9.0, -90)
for i in range(6):
    w = 10.4 - i * 0.75
    b.pad(beacon, "Beacon tower", 97, 24, w, w, 34.8 + i * 4.6, 34.8 + (i + 1) * 4.6, P["cream2" if i % 2 else "coral"], w * 0.28)
b.part(beacon, "Beacon door", [91.9, 37.8, 24], [0.6, 5.0, 3.0], P["wood2"], studs=False)
b.pad(beacon, "Beacon gallery", 97, 24, 10.6, 10.6, 62.4, 63.4, P["slate3"], 3)
for a in range(8):
    t = math.radians(a * 45)
    b.part(beacon, "Gallery post", [97 + math.cos(t) * 4.7, 64.4, 24 + math.sin(t) * 4.7], [0.4, 2.0, 0.4], P["citrine"], studs=False, solid=False, mat=SMOOTH)
lens = b.pad(beacon, "Beacon light", 97, 24, 5.0, 5.0, 63.4, 67.6, "FFF0B8", 1.5, mat=NEON, studs=False, solid=False)
bulb = b.part(beacon, "Beacon lamp", [97, 65.4, 24], [1, 1, 1], "FFF0B8", mat=SMOOTH, alpha=1, shadow=False, studs=False, solid=False)
b.light(bulb, "FFE3A0", 44, 0.9)
b.pad(beacon, "Beacon roof", 97, 24, 7.6, 7.6, 67.6, 68.8, P["coral"], 2.2)
b.pad(beacon, "Beacon roof", 97, 24, 5.0, 5.0, 68.8, 70.0, P["coral"], 1.4)
b.part(beacon, "Beacon finial", [97, 70.9, 24], [1.4, 1.8, 1.4], P["citrine"], rot=ry(45), studs=False, mat=SMOOTH)
bench(beacon, 91.5, 35.0, 31.2, 200)
lamp(beacon, 88.8, 35.0, 15.6, lit=True)
# Garden room: a small pavilion, beds and an orchard.
b.pad(east, "Pavilion floor", 82, 12, 11, 11, 29.0, 29.7, P["stone3"], 3)
for sx in (-1, 1):
    for sz in (-1, 1):
        b.part(east, "Pavilion post", [82 + sx * 3.8, 33.2, 12 + sz * 3.8], [1.1, 7.2, 1.1], P["cream2"], studs=False)
b.pad(east, "Pavilion roof", 82, 12, 12, 12, 36.6, 37.6, P["plum"], 3.4)
b.pad(east, "Pavilion roof", 82, 12, 8.4, 8.4, 37.6, 38.6, P["violet"], 2.4)
b.pad(east, "Pavilion roof", 82, 12, 4.6, 4.6, 38.6, 39.6, P["plum"], 1.3)
crystal(east, 82, 39.5, 12, 3.4, 1.4, P["lilac"])
cluster(east, 82, 29.7, 12, 1.7, (P["citrine"], P["citrine2"], P["honey"]), 4)
for x, z in ((75.6, 16), (75.6, 33), (87.4, 34), (87, 40), (78, 41)):
    b.pad(east, "Flower bed", x, z, 4.4, 5.0, 29.0, 29.6, P["umber"], 1.2)
    flowers(east, x, 29.5, z, 9, 1.7, (("citrine2", "honey", "cream2"), ("violet", "lilac", "pink"), ("coral", "pink", "cream2"))[int(x + z) % 3])
leafy(east, 101, 9, 29.0, 1.0, ("pink", "pink", "cream2"))
leafy(east, 92, 9, 29.0, 0.85, ("lilac", "violet", "lilac"))
leafy(east, 101, 39.5, 29.0, 0.95, ("pink", "cream2", "pink"))
lamp(east, 74.6, 29.1, 28, lit=True)
bench(east, 76.4, 29.1, 38.6, 160)

# ---------------------------------------------------------------- south: hall of miners and the open shore
court = group("Harbor Plaza", "Miners Court")
for s, key in ((-1, "Server"), (1, "Global")):
    m = group("Harbor Plaza", "Miners Court", key)
    cx = s * 27.0
    old = -16.0 if s < 0 else 16.0
    b.pad(m, "Court foundation", cx, 127.5, 36, 22, 23.4, 24.2, P["slate2"], 4)
    b.pad(m, "Court paving", cx, 127.5, 34, 20, 23.6, 24.5, P["stone3"], 3.4)
    for it in CORE[key].findall("Item"):
        k = b.adopt(m, it)
        p = xyz(k, "CFrame")
        dy = {"Standings": -5.4, "Name tag": -1.4}.get(name(it), 0)
        for a, v in zip("XYZ", (p[0] + cx - old, p[1] + dy, p[2])):
            prop(k, "CFrame").find(a).text = f"{v:.4f}"
        if name(it) == "Standings":
            set_type(k, 270, 0.82)
        elif name(it) == "Name tag":
            station(k)
        if name(it).startswith("Podium"):
            tone = {"1": "citrine", "2": "stone2", "3": "clay"}[name(it)[-1]]
            field(k, "Color3uint8", "Color3uint8", 0xFF000000 | int(P[tone], 16))
            stud_all(k)
    b.part(m, "Board frame", [cx, 35.4, 133.1], [27.4, 14.4, 1.2], P["slate3"])
    for t in (-1, 1):
        b.part(m, "Board pillar foot", [cx + t * 14.6, 25.4, 132.8], [4.4, 2.2, 4.4], P["slate2"])
        b.part(m, "Board pillar", [cx + t * 14.6, 34.0, 132.8], [2.8, 16.0, 2.8], P["slate"])
        b.part(m, "Board pillar cap", [cx + t * 14.6, 42.6, 132.8], [3.8, 1.4, 3.8], P["slate2"])
        crystal(m, cx + t * 14.6, 43.2, 132.8, 3.8, 1.7, P["citrine" if s > 0 else "violet"])
    b.part(m, "Board lintel", [cx, 43.2, 132.9], [26.0, 1.6, 2.4], P["wood2"])
    b.part(m, "Board sill", [cx, 27.2, 132.9], [26.0, 2.4, 2.6], P["slate2"])
    # The beach sees the back: planks, a brace and the cove's mark.
    for t in range(6):
        b.part(m, "Board back", [cx - 11.0 + t * 4.4, 35.4, 133.95], [4.2, 13.6, 0.6], P["wood" if t % 2 else "plank"])
    b.part(m, "Board brace", [cx, 35.4, 134.4], [25.6, 1.4, 0.6], P["wood2"], studs=False)
    b.part(m, "Board mark", [cx, 35.4, 134.6], [4.6, 4.6, 0.8], P["citrine" if s > 0 else "violet"], rot=rz(45), studs=False, mat=SMOOTH)
    for x in (cx - 11, cx + 11):
        g = b.part(m, "Pilot lamp", [x, 44.4, 131.4], [1.0, 1.0, 1.0], "FFE3A0", studs=False, mat=NEON, solid=False)
        if x < cx:
            b.light(g, "FFD9A0", 20, 0.55)
# The sea behind the mesas. It stops above the first row the mine can dig.
b.box(isle, "Lagoon", -96, 96, 19.4, 20.4, -220, -78, "2F9CC4", mat=SMOOTH, studs=False)
shore = group("South shore")
b.pad(shore, "Beach sand", 0, 126, 190, 31, 23.2, 24.0, P["sand"], 7)
# Boardwalk straight on from spawn, to a lookout over open water.
b.box(shore, "Boardwalk bed", -5.4, 5.4, 23.2, 24.22, 119.2, 138, P["wood2"])
z = 119.8
i = 0
while z < 136.8:
    b.part(shore, "Boardwalk plank", [0, 24.46, z], [11.4, 0.36, 1.3], P["plank" if i % 2 else "wood3"])
    z += 1.45
    i += 1
b.pad(shore, "Lookout deck", 0, 143.6, 22, 12, 23.2, 25.0, P["wood2"], 3.5)
b.pad(shore, "Lookout deck", 0, 143.6, 21, 11, 24.8, 25.3, P["plank"], 3)
b.ramp(shore, "Lookout ramp", -4.5, 4.5, 24.66, 25.42, 135.6, 138.8, P["wood3"])
fence(shore, [(-10, 141), (-10, 147.5), (-7, 149.6), (7, 149.6), (10, 147.5), (10, 141)], 25.3)
for s in (-1, 1):
    bench(shore, s * 6.5, 25.3, 146.4, 180)
    palm(shore, s * 17, 139, 23.9, 1.1, 90 - s * 90)
    palm(shore, s * 52, 128, 23.9, 1.2, 40)
    palm(shore, s * 66, 136, 23.9, 1.0, 110)
    palm(shore, s * 58, 141, 23.9, 1.15, 200)
    lamp(shore, s * 7.4, 24.4, 119, lit=False)
b.part(shore, "Spyglass post", [0, 26.6, 148.2], [0.8, 2.8, 0.8], P["iron"], studs=False, mat=SMOOTH)
b.part(shore, "Spyglass", [0, 28.2, 148.4], [0.9, 0.9, 3.2], P["citrine"], rot=rx(-6), studs=False, mat=SMOOTH)
# A boat riding at anchor outside the boundary.
boat = group("South shore", "Ore tender")
fb = Frame(26, 20.2, 168, 24)
b.part(boat, "Hull", [0, 1.4, 0], [7.4, 3.4, 18], P["coral"], fb)
b.part(boat, "Hull stripe", [0, 2.7, 0], [7.7, 0.7, 18.3], P["cream2"], fb, studs=False)
for s in (-1, 1):
    b.part(boat, "Bow", [0, 1.4, s * 10.4], [5.2, 3.4, 3.4], P["coral"], fb, ry(0))
b.part(boat, "Deck", [0, 3.2, 0], [6.6, 0.4, 17], P["plank"], fb)
b.part(boat, "Cabin", [0, 5.2, -3.4], [5.0, 4.0, 6.0], P["cream2"], fb)
b.part(boat, "Cabin roof", [0, 7.5, -3.4], [6.0, 0.8, 7.0], P["teal"], fb)
b.part(boat, "Mast", [0, 11.0, 2.6], [0.8, 15.6, 0.8], P["wood2"], fb, studs=False)
b.part(boat, "Sail", [0, 12.6, 5.6], [0.4, 9.0, 6.0], P["cream2"], fb, rx(0), cl="WedgePart", studs=False)
b.part(boat, "Pennant", [0, 18.4, 1.4], [0.3, 1.2, 2.6], P["citrine"], fb, studs=False, mat=SMOOTH)
for it in boat.findall("Item"):
    field(it, "bool", "CanCollide", "false")

# ---------------------------------------------------------------- shoreline
# One convex outline, inside the boundary. Each course is a ring of strips that meet edge to edge,
# with a wedge pair turning every corner, so nothing overlaps and nothing is left open.
coast = group("Citrine Highlands", "Shoreline")


def hull(points):
    pts = sorted(set(points))

    def half(seq):
        out = []
        for p in seq:
            while len(out) > 1 and (out[-1][0] - out[-2][0]) * (p[1] - out[-2][1]) - (out[-1][1] - out[-2][1]) * (p[0] - out[-2][0]) <= 0:
                out.pop()
            out.append(p)
        return out[:-1]
    return half(pts) + half(reversed(pts))


rimline = [p for p in hull([(round(e[0], 2), round(e[2], 2)) for e in edge])]
# Merge points that are close together, for long clean runs.
outline = []
for p in rimline:
    if not outline or math.dist(p, outline[-1]) > 9:
        outline.append(p)


def inset(poly, d):
    """The outline moved in by d (out if negative)."""
    out = []
    n = len(poly)
    for k in range(n):
        a, p, c = poly[k - 1], poly[k], poly[(k + 1) % n]
        def off(u, v):
            L = math.dist(u, v)
            nx, nz = -(v[1] - u[1]) / L, (v[0] - u[0]) / L
            return (u[0] + nx * d, u[1] + nz * d), (v[0] + nx * d, v[1] + nz * d)
        (x1, y1), (x2, y2) = off(a, p)
        (x3, y3), (x4, y4) = off(p, c)
        den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        if abs(den) < 1e-6:
            out.append((x2, y2))
            continue
        t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den
        out.append((x1 + t * (x2 - x1), y1 + t * (y2 - y1)))
    return out


def prism(parent, label, right, p, q, y0, y1, color, **k):
    """An upright right-angled prism: the right angle at `right`, legs to p and q."""
    lp, lq = math.dist(right, p), math.dist(right, q)
    if lp < 0.05 or lq < 0.05:
        return
    # Wedge: right angle at (-Y, +Z). Local Y runs to p, local -Z runs to q.
    ly = [(p[0] - right[0]) / lp, 0, (p[1] - right[1]) / lp]
    lz = [-(q[0] - right[0]) / lq, 0, -(q[1] - right[1]) / lq]
    lx = [ly[1] * lz[2] - ly[2] * lz[1], ly[2] * lz[0] - ly[0] * lz[2], ly[0] * lz[1] - ly[1] * lz[0]]
    mid = [(p[0] + q[0]) / 2, (y0 + y1) / 2, (p[1] + q[1]) / 2]
    b.part(parent, label, mid, [y1 - y0, lp, lq], color, rot=[[lx[i], ly[i], lz[i]] for i in range(3)], cl="WedgePart", **k)


@thing
def ring(parent, poly, outer, label, y0, y1, ink, **k):
    """A band between an inner outline and `outer` studs further out."""
    far = inset(poly, -outer)
    n = len(poly)
    for i in range(n):
        u, v = poly[i], poly[(i + 1) % n]
        L = math.dist(u, v)
        nx, nz = (v[1] - u[1]) / L, -(v[0] - u[0]) / L
        mx, mz = (u[0] + v[0]) / 2 + nx * outer / 2, (u[1] + v[1]) / 2 + nz * outer / 2
        tone = ink(mx, mz)
        b.part(parent, label, [mx, (y0 + y1) / 2, mz], [outer, y1 - y0, L], P[tone], rot=ry(math.degrees(math.atan2(v[0] - u[0], v[1] - u[1]))), **k)
        # Turn the corner at v: from this strip's end to the mitre, and from the mitre to the next.
        w = poly[(i + 2) % n]
        M2 = math.dist(v, w)
        mx2, mz2 = (w[1] - v[1]) / M2, -(w[0] - v[0]) / M2
        e1, e2, tip = (v[0] + nx * outer, v[1] + nz * outer), (v[0] + mx2 * outer, v[1] + mz2 * outer), far[(i + 1) % n]
        turn = P[ink(*v)]
        prism(parent, label, e1, v, tip, y0, y1, turn, **k)
        prism(parent, label, e2, v, tip, y0, y1, turn, **k)


def top_tone(x, z):
    return "sand" if z > 100 else "grass3"


inner = inset(outline, 15)
ring(coast, inner, 13.0, "Coast bank", 22.2, 24.12, top_tone)
ring(coast, inner, 13.8, "Coast bed", 19.0, 22.2, lambda x, z: "sand2" if z > 100 else "clay")
ring(coast, inset(outline, 6), 8.2, "Coast foot", 14.0, 20.9, lambda x, z: "sand2" if z > 100 else "rust")
ring(coast, inset(outline, -2.2), 0.9, "Surf line", 20.1, 20.52, lambda x, z: "surf", mat=SMOOTH, solid=False, studs=False, shadow=False)
# Bluffs on the flanks with the sea between them. A fence closes each gap.
n = len(outline)
run = inset(outline, 7.5)
for i in range(n):
    u, v = run[i], run[(i + 1) % n]
    L = math.dist(u, v)
    for k in range(max(1, round(L / 19))):
        count = max(1, round(L / 19))
        t = (k + 0.5) / count
        x, z = u[0] + (v[0] - u[0]) * t, u[1] + (v[1] - u[1]) * t
        if z < 8 or abs(x) < 70:
            continue
        yaw = math.degrees(math.atan2(v[0] - u[0], v[1] - u[1]))
        seg = L / count
        f = Frame(x, 0, z, yaw)
        if z > 108:
            for q in range(2):
                g = f.at([rng.uniform(-2, 3), 0, rng.uniform(-seg / 2, seg / 2)])
                rock(coast, g[0], 24.1, g[2], rng.uniform(1.3, 2.6), ("stone2", "amber", "slate2"), 2)
            g = f.at([-1, 0, 2])
            palm(coast, g[0], g[2], 24.1, rng.uniform(0.9, 1.15), rng.uniform(0, 360))
            continue
        if (k + i) % 2 == 0:
            h = rng.uniform(7, 15) if z < 70 else rng.uniform(4, 8)
            mesa(coast, x, z, 10.5, seg * 0.82, 24.0, 24.0 + h, 2.6, yaw, lip=0.5, capy=1.4)
            g = f.at([0, 0, rng.uniform(-3, 3)])
            (pine if rng.random() < 0.6 else leafy)(coast, g[0], g[2], 24.0 + h, rng.uniform(0.75, 0.95))
        else:
            fence(coast, [tuple(f.at([2.6, 0, -seg * 0.42])[::2]), tuple(f.at([2.6, 0, seg * 0.42])[::2])], 24.1)
            bush(coast, *f.at([-1.5, 24.1, 1.5]), rng.uniform(0.8, 1.1), bloom="citrine2")

# ---------------------------------------------------------------- roads and meadows
roads = group("Roads")
slab_path(roads, [(-34.4, 18), (-43, 20), (-52, 20.4), (-60, 17), (-62.4, 14)], 6, 24.0)
slab_path(roads, [(34.4, 18), (43, 20), (51, 21), (56.4, 29), (63.4, 36)], 6, 24.0)
for s in (-1, 1):
    b.box(roads, "Bridge apron", s * 41 - 3.4, s * 41 + 3.4, 23.2, 24.2, 47.9, 51.4, P["stone2"])
slab_path(roads, [(-61, 79), (-76, 72), (-87, 60), (-87, 50.4)], 6, 24.0)
slab_path(roads, [(61, 79), (76, 72), (89, 60), (89, 50.8)], 6, 24.0)
slab_path(roads, [(-92, 56), (-104, 47), (-114, 26), (-116, 8)], 5, 24.0)
slab_path(roads, [(94, 56), (106, 47), (114, 26), (116, 8)], 5, 24.0)
slab_path(roads, [(-60, 105), (-64, 109)], 5, 24.0, "sand2")
slab_path(roads, [(60, 105), (64, 109)], 5, 24.0, "sand2")
meadow = group("Meadow planting")
# The lawns rise away from the plaza in low steps, so the square sits in a bowl.
hills = group("Meadow terraces")
for s in (-1, 1):
    mesa(hills, s * 96, 93, 40, 30, 23.6, 27.4, 7, s * 6, "grass2", capy=1.3)
    mesa(hills, s * 102, 96, 25, 21, 27.2, 31.4, 6, s * 14, "grass", capy=1.4)
    mesa(hills, s * 106, 98, 13, 12, 31.2, 35.0, 4, s * 24, "grass2", capy=1.3)
    steps(hills, s * 74.4, 93, 8, 24.0, 27.5, 5.4, -s * 96)
    steps(hills, s * 87.6, 94.5, 7, 27.4, 31.5, 5.6, -s * 84)
    mesa(hills, s * 113, 58, 18, 18, 23.6, 28.6, 5, s * 8, "grass2", capy=1.3)
    mesa(hills, s * 72, 61, 15, 12, 23.6, 26.0, 4, -s * 12, "grass2", capy=1.1)
    mesa(hills, s * 62, 70, 9, 9, 23.6, 25.6, 3, s * 10, "grass", capy=1.0)
    leafy(hills, s * 106, 98, 35.0, 1.35, ("leafgold", "citrine", "honey") if s < 0 else ("pink", "cream2", "pink"))
    bench(hills, s * 94, 31.4, 91, -s * 96)
    for x, z, y in ((84, 100, 27.4), (88, 84, 27.4), (111, 84, 27.4), (117, 60, 28.6), (109, 54, 28.6), (72, 61, 26.0)):
        (pine if z > 90 else leafy)(hills, s * x, z, y, rng.uniform(0.85, 1.1))
    for x, z, w, d, t in ((52, 112, 24, 14, "grass2"), (80, 72, 20, 10, "grass2"), (30, 48.4, 18, 5, "grass2")):
        b.pad(hills, "Meadow patch", s * x, z, w, d, 23.4, 23.9, P[t], 4)
# Groves where they close a view or shelter a corner. Open lawn between them.
GROVES = [(-98, 74, 4), (98, 74, 4), (-78, 112, 4), (78, 112, 4), (-104, 112, 4), (104, 112, 4), (-58, 10, 2), (-60, 49, 3), (62, 49, 3), (-101, 58, 2), (101, 58, 2)]
for x, z, n in GROVES:
    for k in range(n):
        a = k * 2.4 + x
        px, pz = x + math.cos(a) * (2 + 3.6 * k / n * 2), z + math.sin(a) * (2 + 3.2 * k / n * 2)
        kind = leafy if (k + int(x)) % 3 else pine
        kind(meadow, px, pz, 23.9, rng.uniform(0.85, 1.25))
    for k in range(4):
        a = k * 1.7 + z
        px, pz = x + math.cos(a) * 8.5, z + math.sin(a) * 8.0
        if b.clear(px, pz, 1.6, 24.4, 26):
            bush(meadow, px, 23.9, pz, rng.uniform(0.8, 1.2), bloom=("citrine2", "lilac", "coral", None)[k])
    if b.clear(x + 6, z - 6, 2.2, 24.4, 27):
        rock(meadow, x + 6, 23.8, z - 6, rng.uniform(1.8, 3.0), ("stone2", "slate2", "stone"))
for k in range(120):
    px, pz = rng.uniform(-112, 112), rng.uniform(44, 116)
    if b.clear(px, pz, 1.0, 24.15, 26):
        (tuft if k % 3 else lambda p, x, y, z: flowers(p, x, y, z, 5, 1.3))(meadow, px, 23.85, pz)
for k in range(30):
    px, pz = rng.choice((-1, 1)) * rng.uniform(31, 60), rng.uniform(6, 27)
    if b.clear(px, pz, 1.2, 24.15, 26):
        tuft(meadow, px, 23.95, pz, 1.1)
        if k % 4 == 0:
            flowers(meadow, px + 1, 23.95, pz, 5, 1.2)
# Crystals breaking the turf: citrine near the gate, Starfall only close to the mine.
for x, z, y, c in ((-34, 8, 24, "citrine"), (35, 8, 24, "citrine"), (-58, 26, 24, "honey"), (-110, 78, 24, "citrine"), (108, 74, 24, "citrine2")):
    if b.clear(x, z, 1.4, y + 0.4, y + 4):
        cluster(meadow, x, y - 0.1, z, 1.7, (P[c], P["citrine2"], P["honey"]), 4)
# Tops of the gate terraces.
dress = group("Gate planting")
for x, z, y in ((46, 2, 34), (40, -14, 40), (52, -10, 40), (46, -26, 40), (42, -42, 46.6), (56, -38, 46.6), (60, -47, 46.6), (70, -22, 37.8), (64, -34, 37.8), (76, -34, 37.8), (88, -22, 31)):
    for s in (-1, 1):
        (leafy if (x + z) % 3 else pine)(dress, s * x, z, y, rng.uniform(0.75, 1.05))
for s in (-1, 1):
    for x, z, y in ((38, 5.5, 34), (50, 5, 34), (26, 5, 38.2), (36, -10, 40), (56, -22, 40), (78, -18, 37.8)):
        bush(dress, s * x, y, z, rng.uniform(0.8, 1.2), bloom=("lilac" if x < 40 else "coral"))
    # Vines over the lip, so the cliff is not one plane.
    for x, z, y in ((30.4, 8.75, 36.5), (37, 10.3, 32.3), (44, 10.3, 32.3), (48.5, 10.3, 32.3)):
        for k in range(3):
            h = rng.uniform(1.6, 4.4)
            b.part(dress, "Hanging vine", [s * (x + k * 0.9), y - h / 2, z], [0.7, h, 0.4], P["grass3" if k % 2 else "moss"], solid=False, studs=False)
    for x, z, r in ((31.5, 10.4, 2.6), (34.6, 11.2, 1.8), (55, 10.6, 2.4), (53, 12.2, 1.6)):
        rock(dress, s * x, 23.9, z, r)
