"""Build the private photographic set from the editable island. Run with Python, NumPy and Rojo."""

import copy
import json
import math
import random
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from collections import Counter
from functools import lru_cache
from pathlib import Path

import numpy as np
from landforms import build as build_landforms
from ancestral_cove import CoveKit

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "src/client/Starfall"
source = ET.parse(ROOT / "map/CitrineCove.rbxmx").getroot().find("Item")
document = ET.Element("roblox", version="4")
groups = {}
shore = []
facets = []
IDENTITY = np.identity(3)
TAU = math.tau
SEA = 20.30
HIT = np.array([0.0, -32.0])
END = 99.99  # The exposed ancient terrain stays in place until the era cut.
rand = random.Random(407)
timeline = (DEST / "Timeline.luau").read_text()
wave_start = float(re.search(r"\bwaveLaunch\s*=\s*([\d.]+)", timeline).group(1))
wave_end = float(re.search(r"\bbreaker\s*=\s*([\d.]+)", timeline).group(1))
eye = [
    float(v)
    for v in re.search(r"breakerEye\s*=\s*Vector3\.new\(([^)]+)", timeline)
    .group(1)
    .split(",")
]
travel = wave_end - wave_start
front_speed = (
    math.hypot(eye[0] - HIT[0], eye[2] - HIT[1]) - 6 - 2 * travel**2
) / travel


def front_exposure(distance):
    return (
        wave_start
        + (-front_speed + math.sqrt(front_speed**2 + 8 * max(0, distance - 6))) / 4
    )


def prop(i, key):
    return i.find(f'./Properties/*[@name="{key}"]')


def name(i):
    return prop(i, "Name").text


def field(i, key, kind, val):
    el = prop(i, key)
    if el is None:
        el = ET.SubElement(i.find("Properties"), kind, name=key)
    el.text = str(val)
    return el


def item(parent, cl, label):
    v = ET.SubElement(parent, "Item", {"class": cl})
    ET.SubElement(v, "Properties")
    field(v, "Name", "string", label)
    return v


model = item(document, "Model", "CoveChronicle")
replay_document = ET.Element("roblox", version="4")
replay = item(replay_document, "Model", "CoveReplay")
replay_site = item(replay, "Model", "Present-day cove")
replay_floor = item(replay, "Model", "Present_EditFace")


def group(a, b, label):
    key = f"{round(a * 100):04}_{round(b * 100):04}_{label}"
    if key not in groups:
        groups[key] = item(model, "Model", key)
    return groups[key]


def xyz(v, key):
    return np.array([float(prop(v, key).findtext(k)) for k in "XYZ"])


def vector(v, key, p, cl="Vector3"):
    el = ET.SubElement(v.find("Properties"), cl, name=key)
    for k, val in zip("XYZ", p):
        ET.SubElement(el, k).text = f"{val:.5f}"
    return el


def color(s):
    return 0xFF000000 | int(s, 16)


def part(parent, label, pos, size, palette, mat=272, axes=IDENTITY, cl="Part"):
    p = item(parent, cl, label)
    vector(p, "size", size)
    cf = vector(p, "CFrame", pos, "CoordinateFrame")
    for (r, c), val in np.ndenumerate(axes):
        ET.SubElement(cf, f"R{r}{c}").text = f"{val:.7f}"
    field(p, "Color3uint8", "Color3uint8", color(palette))
    field(p, "Material", "token", mat)
    if label in {
        "Deep water",
        "Tidal flats",
        "Shelf water",
        "Wind lane",
        "Weathered beds",
        "Bed of the rim",
        "Weathered bedding",
        "Thrift and lichen",
        "Storm-cut bank",
        "Spoil bank",
        "Haul track",
        "Root",
        "Survey origin",
        "Mineral bedding",
        "Lace of broken surf",
        "Meadow leaf",
        "Wildflower petals",
    }:
        field(p, "CastShadow", "bool", "false")
    if label in ("Shelf water", "Tidal flats"):
        field(p, "Reflectance", "float", "0.12")
    for k in ("CanCollide", "CanTouch", "CanQuery"):
        field(p, k, "bool", "false")
    field(p, "Anchored", "bool", "true")
    return p


def face(parent, label, a, b, c, ink, mat=272):
    a, b, c = np.array(a), np.array(b), np.array(c)
    ab, ac, bc = b - a, c - a, c - b
    if ab @ ab > ac @ ac and ab @ ab > bc @ bc:
        a, c = c, a
    elif ac @ ac > bc @ bc:
        a, b = b, a
    ab, ac, bc = b - a, c - a, c - b
    normal = np.cross(ac, ab)
    if np.linalg.norm(normal) < 0.0002:
        return
    normal /= np.linalg.norm(normal)
    along = bc / np.linalg.norm(bc)
    up = np.cross(along, normal)
    h = abs(ab @ up)
    for v, sign in ((b, 1), (c, -1)):
        d = abs((v - a) @ along)
        if h > 0.018 and d > 0.018:
            part(
                parent,
                label,
                (a + v) * 0.5,
                [0.035, h, d],
                ink,
                mat,
                np.column_stack((normal * sign, up, along * sign)),
                "WedgePart",
            )


def ramp(v, lo, hi):
    return max(0.0, min(1.0, (v - lo) / (hi - lo)))


def survey():
    for p in source.iter("Item"):
        if name(p) == "Coastal escarpment":
            x, y, z = xyz(p, "CFrame")
            shore.append(
                (math.atan2(z + 32, x) % TAU, x, z, y + xyz(p, "size")[1] * 0.39)
            )
    shore.sort()
    assert len(shore) == 47, "Check that the island survey still follows the rock rim"


def coast(angle):
    d = np.array((math.cos(angle), math.sin(angle)))
    for i, (_, x, z, h) in enumerate(shore):
        _, x2, z2, h2 = shore[(i + 1) % len(shore)]
        a = np.array([x, z]) - HIT
        e = np.array([x2 - x, z2 - z])
        det = d[0] * e[1] - d[1] * e[0]
        if abs(det) < 0.001:
            continue
        r = (a[0] * e[1] - a[1] * e[0]) / det
        s = (a[0] * d[1] - a[1] * d[0]) / det
        if r > 0 and -0.0001 <= s <= 1.0001:
            return r, h + s * (h2 - h)
    raise RuntimeError(angle)


BASIN_RINGS = (9, 19, 28, 34, 43)


def crater_height(radius, a, age):
    # The impact heaves a continuous rim around the original seam. The low
    # seaward saddle keeps the seam in sight and becomes the miners' entrance.
    seaward = max(0, 0.45 * math.cos(a) + 0.89 * math.sin(a)) ** 3
    crest = 41 + 2.1 * math.sin(3 * a + 0.4) + 1.25 * math.sin(7 * a) - 6.5 * seaward
    if age == "intact":
        heights = (26, 26.14, 26.5, 27.15, 27.6, 26.4)
    elif age == "struck":
        heights = (25.27, 25.5, 27.1, 30.4 + 0.24 * (crest - 34), crest, 26.4)
    else:
        heights = (25.65, 25.8, 27.4, 30.5, crest - 2.4, 26.4)
    return np.interp(radius, (0, *BASIN_RINGS), heights)


def terrain_height(x, z, a, age):
    dx, dz = x, z + 32
    elliptical = math.hypot(dx, dz * 1.1)
    if elliptical <= BASIN_RINGS[-1] + 0.001:
        return crater_height(elliptical, a, age)

    # The actual map is built on broad, flat island slabs. The open meadow
    # meets the edge of the ancestral impact basin without a seam.
    return 24.70 + 1.70 * (1 - ramp(elliptical, BASIN_RINGS[-1], 55))


kit = CoveKit(source, name, prop, xyz, part, field, group)


def headlands():
    kit.build_shelves(END, front_exposure)
    kit.build_shore(shore, END)

    spit = group(0, END, "Shingle landing")
    kit.pad(spit, "Landing beach", -136.3, 118.9, 28, 32, 19.5, 21.80, -5, 5.0, "EBAD6A")
    kit.pad(spit, "Golden shingle", -135.6, 118.3, 23, 27, 21.65, 23.37, -5, 4.3, "F3CF96")
    kit.pad(spit, "Landing crest", -135.5, 118.6, 16.7, 21.4, 23.30, 24.43, -5, 3.1, "F6D99F")

    # The eastern ledge overhangs the narrow rim at water level. These
    # chamfered rock courses join its split boulder to the map's bedrock.
    bank = group(0, END, "East cape intertidal bedrock")
    for x, z, w, d, lo, hi, turn, corner, tone in (
        (133.9, -35.2, 32, 44, 18.8, 24.8, -5, 6.0, "9D7972"),
        (133.1, -35.7, 26, 36, 23.3, 30.1, -5, 5.3, "A48178"),
        (132.6, -35.4, 21, 27, 28.9, 35.8, 4, 4.7, "9A7A77"),
        (132.0, -34.9, 17.8, 22, 34.7, 42.3, 4, 4.1, "A68078"),
    ):
        kit.pad(
            bank, "Wave-worn sandstone course", x, z, w, d, lo, hi, turn, corner, tone
        )


def make_terrain():
    N = 40
    rows = []
    for j in range(len(BASIN_RINGS) + 5):
        ring = []
        for k in range(N):
            a = (k + 0.12 * math.sin(k * 1.7 + j * 0.35)) * TAU / N
            scale = math.hypot(math.cos(a), 1.1 * math.sin(a))
            edge = coast(a)[0]
            r = (
                [r / scale for r in BASIN_RINGS]
                + [
                    BASIN_RINGS[-1] / scale + (edge - BASIN_RINGS[-1] / scale) * f
                    for f in (0.18, 0.40, 0.64, 0.86, 1.015)
                ]
            )[j]
            ring.append((r * math.cos(a), -32 + r * math.sin(a)))
        rows.append(ring)

    def render_tri(row, k, triangle):
        points = np.array(triangle)
        x, z = points.mean(axis=0)
        radius = math.hypot(x, z + 32)
        hit = 4.60 if row <= 1 else round((front_exposure(radius) - 0.09) * 10) / 10
        # The outer capes take an ash wash while the inner basin fractures.
        hard_hit = radius < 83 + 13 * math.sin(math.atan2(z + 32, x) * 3 + 0.3)
        basin = row < len(BASIN_RINGS)
        states = [(0, hit, "intact"), (hit, END, "struck" if hard_hit else "ash")]
        pine = (
            ("85CC60",) * 6
            if row > 3
            else ("78BC63", "80C15F", "85CC60", "85CC60", "80C15F", "78BC63")
        )
        dust = ("4E4249", "664F53", "453D48", "78605D", "56484E")
        index = (k + 3 * row) % 6
        for start, end, state in states:
            grp = group(start, end, "Impact basin" if basin else "Headland")
            polygon = []
            for xx, zz in triangle:
                yy = terrain_height(xx, zz, math.atan2(zz + 32, xx), state)
                polygon.append((xx, yy, zz))
            if state == "intact":
                ink = pine[index]
            elif state == "struck":
                ink = dust[index % len(dust)]
            else:
                ink = ("796F6E", "88776C", "675F63")[index % 3]
            face(
                grp,
                "Weathered beds",
                *polygon,
                ink,
                272,
            )
            if state == "intact":
                facets.append(np.array(polygon))

    for j, row in enumerate(rows):
        for k, p in enumerate(row):
            i = (k + 1) % N
            prev = rows[j - 1] if j else [(0, -32)] * N
            render_tri(j, k, [prev[k], p, row[i]])
            if j:
                render_tri(j, k, [prev[k], row[i], prev[i]])


# The survey is baked once; a local cell index keeps debris and foot sampling
# inexpensive without losing the actual triangular surface at the crater.
survey_grid = {}


def index_surface():
    for triangle in facets:
        heights = triangle[:, 1]
        a, b, c = triangle[:, [0, 2]]
        u, v = b - a, c - a
        det = u[0] * v[1] - u[1] * v[0]
        record = (a, u, v, det, heights)
        corners = np.array((a, b, c)) / 16
        low, high = np.floor(corners.min(axis=0)).astype(int), np.floor(
            corners.max(axis=0)
        ).astype(int)
        for i in range(low[0], high[0] + 1):
            for j in range(low[1], high[1] + 1):
                survey_grid.setdefault((i, j), []).append(record)


@lru_cache(maxsize=32768)
def sample(x, z):
    """Return the surveyed pre-impact ground elevation."""
    for a, u, v, det, heights in survey_grid.get(
        (math.floor(x / 16), math.floor(z / 16)), ()
    ):
        dx, dz = x - a[0], z - a[1]
        s = (dx * v[1] - dz * v[0]) / det
        t = (u[0] * dz - u[1] * dx) / det
        if s >= -0.00001 and t >= -0.00001 and s + t <= 1.00001:
            y = (
                heights[0]
                + s * (heights[1] - heights[0])
                + t * (heights[2] - heights[0])
            )
            return kit.top(x, z, y)
    return kit.top(x, z, SEA)


def prehistoric(path, label):
    top, site = (path + ["", ""])[:2]
    if top in ("Island and lagoon", "Honey bluffs", "Spring falls"):
        return True
    if site in ("Rock rim", "Turquoise cascade"):
        return True
    if site == "Cableway ridge":
        return "Quartz" not in label
    if site == "Outer meadows":
        return label in ("Headland turf", "Tidal shallows")
    if site == "Beacon Point":
        return "island" in label.lower()
    return label in (
        "Ridgeline turf", "Wild stone", "Dressed stone", "Sloping bluff foundation",
        "Rear bluff foundation", "Ridge footing",
    )


def extract(parent, path):
    inner_bluff, previous = False, None
    for p in parent.findall("Item"):
        cl, k = p.get("class"), name(p)
        if cl in ("Model", "Folder"):
            extract(p, path + [k])
        if cl not in ("Part", "WedgePart", "SpawnLocation"):
            continue
        x, y, z = xyz(p, "CFrame")
        if k in ("SiteOrigin", "Landing", "Outer cliff boundary", "Lagoon", "Water glint", "Shallow water"):
            continue
        q = copy.deepcopy(p)
        if k in ("Far slope", "Mountain flank", "Summit facet", "Tidal shallows"):
            field(q, "CastShadow", "bool", "false")
        for child in list(q.findall("Item")):
            if child.get("class") not in ("PointLight", "SurfaceLight", "SurfaceGui"):
                q.remove(child)
        for key in ("CanCollide", "CanTouch", "CanQuery"):
            field(q, key, "bool", "false")
        # A deep replay can be outside map streaming range. Store the finished
        # playable architecture in a single timeless replica, complete with signage.
        target = replay_floor if path[0] == "EditFace" else replay_site
        target.append(copy.deepcopy(q))
        if not prehistoric(path, k):
            continue
        if k == "Ridgeline turf" and x > 101 and z > -26:
            # The walking map's tilted turf slab projects beyond the rock rim.
            # From out on the tide its original underside is entirely visible.
            mat = np.array(
                [
                    [float(prop(p, "CFrame").findtext(f"R{i}{j}")) for j in range(3)]
                    for i in range(3)
                ]
            )
            size = xyz(p, "size")
            depth = 17.4
            at = np.array((x, y, z)) - mat[:, 1] * (size[1] + depth - 0.20) * 0.5
            part(
                group(0, END, "East cape intertidal bedrock"),
                "Sandstone under the turf",
                at,
                (size[0] - 0.28, depth, size[2] - 0.32),
                "AC805D",
                272,
                mat,
            )
        # The bluff enclosing the mine and the man-made gallery roof exist
        # only on the finished island. Outer bluffs remain in the ancient coast.
        if path[0] == "Honey bluffs":
            if k == "Weathered sandstone" and previous != k:
                inner_bluff = abs(x) < 59
            previous = k
            if inner_bluff:
                continue
        if path[0] == "Spring falls" or k in (
            "Ridge sandstone", "Ridge meadow", "Gully shoulder", "Gully bed",
        ):
            continue
        if k in (
            "Meadow cap",
            "Turf on the rim",
            "Slate crown",
            "Grass shelf",
        ):
            matrix = np.array(
                [
                    [float(prop(p, "CFrame").find(f"R{i}{j}").text) for j in range(3)]
                    for i in range(3)
                ]
            )
            kit.add_native_cap(
                np.array((x, y, z)),
                xyz(p, "size"),
                matrix,
                cl,
            )
        if (
            k in (
                "Meadow cap",
                "Turf on the rim",
                "Fir boughs",
                "Grass shelf",
                "Ridgeline turf",
            )
            and math.hypot(x, z + 32) < 148
        ):
            # Keep the cliffs' actual scaled parts and positions throughout the
            # blast. The scorched caps stay exposed for the aftermath.
            hit = round(front_exposure(math.hypot(x, z + 32)) * 8) / 8
            group(0, hit, path[-1]).append(copy.deepcopy(q))
            ash = copy.deepcopy(q)
            field(
                ash,
                "Color3uint8",
                "Color3uint8",
                color(
                    {"Fir boughs": "595961", "Ridgeline turf": "554A53"}.get(
                        k, "776767"
                    )
                ),
            )
            group(hit, END, path[-1]).append(ash)
        else:
            group(0, END, path[-1]).append(q)


def sea():
    water = group(0, END, "Open sea")
    for ix in range(-3, 4):
        for iz in range(-3, 4):
            p = part(
                water,
                "Deep water",
                (ix * 1990, 19.88, iz * 1990),
                (1990, 0.6, 1990),
                "387B93",
            )
            field(p, "Reflectance", "float", ".055")
    prev = []
    for j, (size, ink) in enumerate(
        [
            (1.08, "5AA5AB"),
            (1.29, "519CA6"),
            (1.72, "4590A1"),
            (2.82, "3F849A"),
        ]
    ):
        outline = []
        for a, x, z, _ in shore[::2]:
            shelf = (
                1.0
                + 0.26 * math.sin(2 * a - 0.44)
                + 0.21 * math.sin(5 * a + 0.28)
                + 0.16 * math.cos(3 * a)
                + 0.10 * math.sin(9 * a)
            )
            run = 1.0 + (size - 1) * shelf
            xx = x * run
            zz = -32 + (z + 32) * run
            outline.append((xx, SEA - j * 0.014, zz))
        for i, p in enumerate(outline):
            q = outline[(i + 1) % len(outline)]
            if not prev:
                face(water, "Tidal flats", (0, SEA, 28), p, q, ink)
            else:
                v, w = prev[i], prev[(i + 1) % len(outline)]
                face(water, "Shelf water", v, p, q, ink)
                face(water, "Shelf water", v, q, w, ink)
        prev = outline
    for _ in range(95):
        a, r = rand.random() * TAU, rand.uniform(1.08, 4.5)
        margin = coast(a)[0] * r
        cx = math.cos(a) * margin
        cz = -32 + math.sin(a) * margin
        for j in range(rand.randint(2, 4)):
            x, z = cx + rand.uniform(-13, 13), cz + rand.uniform(-5, 5)
            length = rand.uniform(2, 13)
            breadth = rand.uniform(0.28, 0.95)
            ink = (
                rand.choice(("79A9AF", "87BAB9", "9AC4BD"))
                if r < 2
                else rand.choice(("6796A4", "73A0AA", "76A4AF"))
            )
            blade = part(
                water,
                "Wind lane",
                (x + length * 0.5, SEA + 0.16, z),
                (length, 0.05, breadth),
                ink,
            )
            field(blade, "shape", "token", "0")


def vegetation():
    # Sample the same grove footprints used by the baked moon shadows.
    # Every standing tree is present before the meteor reaches the island.
    groves = item(model, "Model", "Wind trees")
    trees = []
    grovesites = [
        (-78, 40),
        (-80, 72),
        (-56, 99),
        (-115, 87),
        (65, 51),
        (88, 79),
        (45, 93),
        (52, -19),
        (-49, -37),
        (14, 116),
        (-17, 28),
    ]
    for i in range(205):
        if i < 31:
            a = rand.uniform(0, TAU)
            r = rand.uniform(0.31, 0.90) * coast(a)[0]
            x, z = math.cos(a) * r, -32 + math.sin(a) * r
        else:
            cx, cz = grovesites[(i - 31) % len(grovesites)]
            x, z = cx + rand.gauss(0, 11), cz + rand.gauss(0, 13)
            a = math.atan2(z + 32, x)
            r = math.hypot(x, z + 32)
        if (
            math.hypot(x, (z + 32) * 1.1) < BASIN_RINGS[-1] + 2
            or r > coast(a)[0] * 0.948
            or any(math.hypot(x - xx, z - zz) < 3.5 for xx, zz in trees)
        ):
            continue
        trees.append((x, z))
        h = rand.uniform(7.2, 16.7) * (1.08 if x < 0 else 0.94)
        spin = rand.random() * TAU
        if i >= 31 and i % 4 != 0:
            continue
        y = sample(x, z)
        damaged = r < 116 or i % 3 != 0
        closes = front_exposure(r) + 0.48 if damaged else END
        tree = item(groves, "Model", f"0.00_{closes:.2f}")
        root = part(tree, "Root", (x, y, z), (0.1, 0.1, 0.1), "6D604F")
        root.set("referent", f"Tree{i}")
        field(root, "Transparency", "float", "1")
        field(tree, "PrimaryPart", "Ref", f"Tree{i}")
        kit.native_tree(tree, i, x, y, z, h, spin, i % 3 == 0)
        if damaged:
            # At this exposure the crown tears away. Blackened forks and a
            # broken crown lie along the same bearing as the passing wave.
            snag = group(closes, END, "Burned windfall")
            direction = np.array((x / r, 0, (z + 32) / r))
            foot = np.array((x, y, z))
            is_down = i % 3 != 0
            frac = 0.93 if is_down else 0.27
            tip = (
                foot
                + direction * h * frac
                + np.array((0, h * (0.18 if is_down else 0.69), 0))
            )
            spar(snag, "Carbonized bole", foot, tip, h * 0.093, "494247")
            for q in (-1, 1):
                waist = foot + (tip - foot) * (0.49 + 0.11 * q)
                fork = (
                    waist
                    + direction * h * 0.27
                    + np.array(
                        (
                            direction[2] * q * h * 0.23,
                            h * 0.16,
                            -direction[0] * q * h * 0.23,
                        )
                    )
                )
                spar(snag, "Splintered limb", waist, fork, h * 0.054, "71615A")
    return groves.findall("Item")


def spar(parent, label, a, b, width, ink):
    a, b = np.array(a, dtype=float), np.array(b, dtype=float)
    back = (a - b) / np.linalg.norm(a - b)
    right = np.cross([0, 1, 0] if abs(back[1]) < 0.999 else [0, 0, 1], back)
    right /= np.linalg.norm(right)
    part(
        parent,
        label,
        (a + b) * 0.5,
        (width, width, np.linalg.norm(a - b)),
        ink,
        512,
        np.column_stack((right, np.cross(back, right), back)),
    )


def main():
    survey()
    extract(source, [])
    sea()
    make_terrain()
    index_surface()
    headlands()
    trees = vegetation()
    build_landforms(shore, coast, sample, front_exposure, group, part, face, spar, DEST)
    # Keep the editable map origin even when ancient parcels detach or a replay
    # is placed above a player's distant, underground character.
    for root_model, data in ((model, document), (replay, replay_document)):
        label = name(root_model)
        root = part(root_model, "Survey origin", (0, 0, 0), (0.1, 0.1, 0.1), "FFFFFF")
        root.set("referent", "FilmOrigin")
        field(root, "Transparency", "float", "1")
        field(root_model, "PrimaryPart", "Ref", "FilmOrigin")
        with tempfile.TemporaryDirectory() as folder:
            tmp = Path(folder)
            ET.ElementTree(data).write(tmp / "model.rbxmx", encoding="utf-8")
            project = tmp / "bake.project.json"
            project.write_text(json.dumps({"name": label, "tree": {"$path": "model.rbxmx"}}))
            subprocess.run(["rojo", "build", project, "-o", DEST / f"{label}.rbxm"], check=True)
    # Sample the travelling wave against this exact pre-impact surface, including
    # the cliffs. Each row records radius and height from the crater to open water.
    heights = []
    for k in range(48):
        a = k * TAU / 48
        bank, _ = coast(a)
        row = []
        for u in (0, 0.12, 0.25, 0.4, 0.57, 0.73, 0.88, 0.97, 1.015, 1.06, 1.14, 1.27):
            r = bank * u
            x, z = r * math.cos(a), -32 + r * math.sin(a)
            y = sample(x, z)
            if u <= 1.015:
                y = max(y, terrain_height(x, z, a, "struck"))
            row.append(f"{{{r:.2f},{y:.2f}}}")
        heights.append("\t{" + ",".join(row) + "},")
    (DEST / "CoastSections.luau").write_text(
        "-- Generated by art/starfall/bake_cove.py. Radius and elevation along rays from the starfall.\nreturn {\n"
        + "\n".join(heights)
        + "\n}\n"
    )
    print(
        f"{len(groups)} exposure groups, {len(trees)} wind trees, {Counter(i.get('class') for i in document.iter('Item'))}"
    )


if __name__ == "__main__":
    main()
