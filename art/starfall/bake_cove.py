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
from settlement import build as build_settlement

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
END = 28.25
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


def crater_height(radius, a, age):
    lip = 31.25 + 1.4 * math.sin(3 * a + 0.4) + 0.75 * math.sin(7 * a)
    if age == "intact":
        return np.interp(radius, [0, 7, 14, 23, 32], [26, 26.06, 26.45, 27.1, 28.1])
    if age == "struck":
        return np.interp(radius, [0, 7, 14, 23, 32], [25.27, 25.34, 26.08, lip, 28.1])
    return np.interp(
        radius, [0, 7, 14, 23, 32], [26.1, 26.45, 26.98, lip * 0.44 + 15.7, 28.1]
    )


def terrain_height(x, z, a, age):
    dx, dz = x, z + 32
    elliptical = math.hypot(dx, dz * 1.1)
    if elliptical < 32:
        return crater_height(elliptical, a, age)

    # The actual map is built on broad, flat island slabs. The open meadow
    # meets the edge of the ancestral impact basin without a seam.
    return 24.70 + 3.40 * (1 - ramp(elliptical, 32, 47))


def clearing(x, z):
    # The pit and western right-of-way are cut before the level valley lots.
    if -136 < x < -35 and 27 < z < 116:
        return 18.88 if x < -74 else 19.45
    if x < -70:
        return 19.82
    # The working valley is one cut-and-fill district. Its front hill and
    # houses share a continuous grade when the quarry opens behind them.
    return 20.02


def developed(t):
    # Trade ordering of the native parts is rescheduled onto the valley,
    # village and tramway exposures, after each district is ready to receive it.
    return float(
        np.interp(
            t,
            [0, 18.8, 19.6, 20.5, 21.9, 22.65, 23.55, 24.93, 27],
            [0, 20.0, 21.54, 23.34, 24.08, 24.62, 25.46, 26.90, END],
        )
    )


# The virtual set shares its coastal cliff blocks, capped mesas and garden tree
# templates with the walkable map. Only the quarry history needs an extra shelf kit.
kit = CoveKit(source, name, prop, xyz, part, field, group)


def headlands():
    kit.build_shelves(clearing, front_exposure)
    kit.build_shore(shore, developed)

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
    for j in range(9):
        ring = []
        for k in range(N):
            a = (k + 0.12 * math.sin(k * 1.7 + j * 0.35)) * TAU / N
            scale = math.hypot(math.cos(a), 1.1 * math.sin(a))
            edge = coast(a)[0]
            r = (
                [7 / scale, 14 / scale, 23 / scale, 32 / scale]
                + [
                    32 / scale + (edge - 32 / scale) * f
                    for f in (0.18, 0.40, 0.64, 0.86, 1.015)
                ]
            )[j]
            ring.append((r * math.cos(a), -32 + r * math.sin(a)))
        rows.append(ring)

    def render_tri(row, k, triangle):
        points = np.array(triangle)
        x, z = points.mean(axis=0)
        remove = clearing(x, z)
        radius = math.hypot(x, z + 32)
        hit = 4.60 if row <= 1 else round((front_exposure(radius) - 0.09) * 10) / 10
        # The compact scorch front outruns the sea swell; patches of the old
        # surface survive on the outer capes. Recover in sweeps across the basin.
        hard_hit = radius < 83 + 13 * math.sin(math.atan2(z + 32, x) * 3 + 0.3)
        first_green = 12.90 + 0.26 * round(ramp(z - x * 0.35, -65, 137) * 7)
        states = [
            (0, hit, "intact"),
            (hit, first_green, "struck" if hard_hit else "ash"),
            (first_green, first_green + 0.91, "aged"),
            (first_green + 0.91, remove, "green"),
            (remove, remove + 0.62, "bench"),
            (remove + 0.62, remove + 1.49, "fill"),
        ]
        pine = (
            ("85CC60",) * 6
            if row > 3
            else ("78BC63", "80C15F", "85CC60", "85CC60", "80C15F", "78BC63")
        )
        dust = ("4E4249", "664F53", "453D48", "78605D", "56484E")
        index = (k + 3 * row) % 6
        for start, end, state in states:
            grp = group(start, end, "Basin" if row <= 3 else "Headland")
            polygon = []
            for xx, zz in triangle:
                yy = terrain_height(xx, zz, math.atan2(zz + 32, xx), state)
                if state == "bench":
                    yy = 24.64 + (yy - 24.64) * 0.19
                elif state == "fill":
                    yy = 24.47 + 0.63 * math.sin(xx * 0.031 + zz * 0.027)
                polygon.append((xx, yy, zz))
            if state in ("green", "intact"):
                ink = pine[index]
            elif state == "struck":
                ink = dust[index % len(dust)]
            elif state == "ash":
                ink = ("796F6E", "88776C", "675F63")[index % 3]
            elif state == "bench":
                ink = ("CE925F", "CF9564", "CB8F5D")[index % 3]
            elif state == "fill":
                ink = ("E9BC80", "E6B982", "E7B97F")[index % 3]
            else:  # a meadow in its first season after the fire
                ink = ("A7AA75", "AAA674", "99AA76")[index % 3]
            face(
                grp,
                "Weathered beds",
                *polygon,
                ink,
                272,
            )
            if state == "green" or (row <= 3 and state == "struck"):
                facets.append((state, np.array(polygon)))

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
    for state, triangle in facets:
        if state != "green":
            continue
        heights = triangle[:, 1]
        a, b, c = triangle[:, [0, 2]]
        u, v = b - a, c - a
        det = u[0] * v[1] - u[1] * v[0]
        grade = clearing(*triangle.mean(axis=0)[[0, 2]])
        record = (a, u, v, det, heights, grade)
        corners = np.array((a, b, c)) / 16
        low, high = np.floor(corners.min(axis=0)).astype(int), np.floor(
            corners.max(axis=0)
        ).astype(int)
        for i in range(low[0], high[0] + 1):
            for j in range(low[1], high[1] + 1):
                survey_grid.setdefault((i, j), []).append(record)


@lru_cache(maxsize=32768)
def parcel(x, z):
    """Return the surveyed surface elevation and first grading date at a point."""
    for a, u, v, det, heights, grade in survey_grid.get(
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
            return kit.top(x, z, y), grade
    return kit.top(x, z, SEA), math.inf


def sample(x, z):
    return parcel(x, z)[0]


def ground(x, z, year):
    """Sample the photographic parcel under an actor or foundation."""
    y, cut = parcel(x, z)
    if year < cut:
        return y
    if year < cut + 0.62:
        return 24.64 + (y - 24.64) * 0.19
    if year < cut + 1.49:
        return 24.47 + 0.63 * math.sin(x * 0.031 + z * 0.027)
    return 24.12


def map_time(path, k, x, y, z):
    top, site = (path + ["", ""])[:2]
    low = k.lower()
    if k in ("SiteOrigin", "Landing", "Outer cliff boundary"):
        return None
    if top == "EditFace":
        return 20.28
    if top == "Island and lagoon":
        return None if k in ("Lagoon", "Water glint", "Shallow water") else 0
    if top == "Coastal grove":
        return 22.35
    if site == "Rock rim":
        return 0
    if site == "Cableway ridge":
        # These bluffs and foothills are features of this island, already in
        # place when the meteor arrives. The cableway and quartz marks come later.
        return 24.83 if "Quartz" in k else 0
    if site == "Outer meadows":
        if k in ("Headland turf", "Tidal shallows"):
            return 0
        return (
            19.45
            if k == "Bridge pile"
            else 20.18 if k in ("Timber deck", "Footboard") else 23.72
        )
    if site == "Turquoise cascade" and k in ("Culvert keystone", "Drain cheek", "Drain shadow"):
        return 21.98
    if top == "Honey bluffs" or site == "Turquoise cascade" or top == "Spring falls":
        return 0
    if site == "Cableway trail" and k in (
        "Ridgeline turf",
        "Wild stone",
        "Dressed stone",
    ):
        return 0
    if site == "Cableway trail" and k in ("Mine roof slope", "Rear roof slope"):
        return 0
    if top == "Wildflowers":
        return 20.62
    if top == "Citrine Mine":
        if k in (
            "Cave jamb",
            "Cave shoulder",
            "Capstone",
            "Amber keystone bed",
            "Crystal facet",
            "Crystal point",
        ):
            return 20.28 if "Crystal" not in k else 22.72
        if k in ("Portal footing", "Cut basalt pier", "Arch voussoir"):
            return 22.64 + round(ramp(y, 24, 40) * 4) * 0.19
        return 24.15 if k == "Mine sign" else 24.55
    if top == "Working gallery":
        if any(w in low for w in ("lamp", "lantern")):
            return 24.73
        return (
            19.24
            if any(w in low for w in ("foundation", "turf"))
            else 20.28 if "wall" in low else 22.64
        )
    if site == "Ore siding":
        if k in ("Wharf pile", "Tipple timber"):
            return 20.38
        if k in ("Loading bin", "Wagon unload platform"):
            return 20.64
        if k in ("Bin band", "Ore chute"):
            return 20.77
        if k == "Sleeper":
            return 20.80 + 0.09 * int(ramp(z, 6, 86) * 10)
        if k == "Rail":
            return 21.75 if x < -91 else 21.86
        if k in ("Planked rail crossing", "Wharf step", "Stop shoe", "Rail stop"):
            return 21.92
        offset = round(ramp(z, 22, 47) * 2) * 0.065
        return offset + (
            21.96
            if "wheel" in low
            else 22.08 if "bed" in low else 22.20 if "wagon" in low else 22.35
        )
    if top == "Sand path and bridge":
        if k in ("Canal landing", "Canal step", "Canal handrail", "Rail post"):
            return 20.33
        if k == "Bridge bearer" or k == "Bridge post":
            return 19.53
        if k == "Bridge plank":
            return 19.67 + round(ramp(z, 30, 41) * 5) * 0.08
        return 20.24 if k in ("Bridge decking", "Handrail", "Post cap") else 19.45
    if site == "Loading dock":
        return (
            18.85
            if "piling" in low
            else 19.32 if "deck" in low else 23.69 if "upright" in low else 23.94
        )
    if site == "Arrival court" or site == "Miners Court":
        return (
            20.06
            if any(w in low for w in ("foundation", "concourse", "paving"))
            else 24.18 + round(ramp(y, 24, 49) * 3) * 0.13
        )
    if top == "Shore market" or site in ("Jobs", "Store", "Book", "Supplies"):
        offset = 0.32 * ramp(x, -45, 45)
        if any(w in low for w in ("deck", "floor", "mat", "pad")):
            return 19.87 + offset
        if any(w in low for w in ("post", "frame", "foot", "stand", "wall")):
            return 22.67 + offset
        if any(w in low for w in ("canvas", "canopy", "valance", "hem")):
            return 23.54 + offset + round((x % 12) / 4) * 0.09
        return 23.21 + offset if "counter" in low else 24.35 + offset
    if site == "Beacon Point":
        return 0 if "island" in low else 23.92 + round(ramp(y, 24, 64) * 4) * 0.12
    if site in ("Moving cabins", "Ridge tramway", "Cableway trail"):
        return (
            24.86
            if site == "Moving cabins"
            else 23.71 + round(ramp(y, 24, 84) * 5) * 0.14
        )
    if site == "Compass gardens":
        return 24.62 if "lamp" in low else 23.91
    return 24.8


# The original cove's outer bluffs are already rock before the strike. Near
# the impact, the crater, ejecta and regrowth need their open basin. Sediment
# beds build these inner shoulders during geological time, before the landing.
infill = item(model, "Model", "Basin infill")
burial = {
    "west": item(infill, "Model", "12.68_14.75"),
    "east": item(infill, "Model", "12.94_15.03"),
    "strata": item(infill, "Model", "13.57_15.43"),
}


def extract(parent, path):
    bluff_district, previous = None, None
    for p in parent.findall("Item"):
        cl, k = p.get("class"), name(p)
        if cl in ("Model", "Folder"):
            extract(p, path + [k])
        if cl not in ("Part", "WedgePart", "SpawnLocation"):
            continue
        x, y, z = xyz(p, "CFrame")
        when = map_time(path, k, x, y, z)
        if when is None:
            continue
        q = copy.deepcopy(p)
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
        if k in ("Far slope", "Mountain flank", "Summit facet", "Tidal shallows"):
            field(q, "CastShadow", "bool", "false")
        for child in list(q.findall("Item")):
            if child.get("class") not in ("PointLight", "SurfaceLight", "SurfaceGui"):
                q.remove(child)
        for key in ("CanCollide", "CanTouch", "CanQuery"):
            field(q, key, "bool", "false")
        district = None
        if path and path[0] == "Honey bluffs":
            # The first sandstone in each native cap is the centre of the
            # complete formation. Its corner wedges share the same geology.
            if k == "Weathered sandstone" and previous != k:
                bluff_district = ("west" if x < 0 else "east") if abs(x) < 59 else None
            district, previous = bluff_district, k
        elif k in ("Mine roof slope", "Rear roof slope", "Ridge sandstone", "Ridge meadow", "Gully shoulder", "Gully bed"):
            district = "strata"
        elif k in (
            "Sloping bluff foundation",
            "Rear bluff foundation",
            "Ridge footing",
        ):
            # These are the underlying rocks, not the mine's built portal.
            when = 0
        elif path and path[0] == "Spring falls":
            district = "east"
        if district:
            burial[district].append(q)
        if when == 0 and k in (
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
                buried=district is not None,
            )
        if district:
            continue
        if (
            when == 0
            and k
            in (
                "Meadow cap",
                "Turf on the rim",
                "Fir boughs",
                "Grass shelf",
                "Ridgeline turf",
            )
            and math.hypot(x, z + 32) < 148
        ):
            # Keep the cliffs' actual scaled parts and positions throughout the
            # blast. The new plants re-use the same kit and grow at their roots.
            hit = round(front_exposure(math.hypot(x, z + 32)) * 8) / 8
            green = 13.70 + 0.22 * round(ramp(z - x * 0.3, -100, 130) * 6)
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
            group(hit, green, path[-1]).append(ash)
            group(green, END, path[-1]).append(q)
        else:
            group(developed(when), END, path[-1]).append(q)


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
    # Each tree has a root at the measured terrain height. Botanical silhouettes
    # stay readable against the dust front; older, taller groves appear in saltation.
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
            r < 31
            or r > coast(a)[0] * 0.948
            or any(math.hypot(x - xx, z - zz) < 3.5 for xx, zz in trees)
        ):
            continue
        y = sample(x, z)
        age = 0 if i < 31 or i % 4 == 0 else 13.40 + (i % 10) * 0.27
        if age > 0:
            recovered = kit.mature_top(x, z, y)
            if recovered > y + 0.03:
                y = recovered
                age = max(age, 15.11 + i % 4 * 0.12)
        if x < -89 and 67 < z < 104 and age > 0:
            age = 14.85 + (i % 3) * 0.18
        damaged = age == 0 and (r < 116 or i % 3 != 0)
        reach = front_exposure(r)
        clear = parcel(x, z)[1]
        if x > -12 and z > 58:
            clear = min(clear, 18.76 + round(ramp(z - x * 0.4, 45, 125) * 4) * 0.10)
        closes = reach + 0.48 if damaged else clear
        tree = item(groves, "Model", f"{age:.2f}_{closes:.2f}")
        h = rand.uniform(7.2, 16.7) * (1.08 if x < 0 else 0.94)
        root = part(tree, "Root", (x, y, z), (0.1, 0.1, 0.1), "6D604F")
        root.set("referent", f"Tree{i}")
        field(root, "Transparency", "float", "1")
        field(tree, "PrimaryPart", "Ref", f"Tree{i}")
        spin = rand.random() * TAU
        kit.native_tree(tree, i, x, y, z, h, spin, i % 3 == 0)
        if not damaged and clear + 0.25 < parcel(x, z)[1]:
            harvest = group(
                clear, min(clear + 1.20, parcel(x, z)[1]), "Felled trees and cut stumps"
            )
            part(
                harvest,
                "Stump",
                (x, y + 0.32, z),
                (0.11 * h, 0.64, 0.11 * h),
                "916C4E",
                512,
            )
            endx, endz = x + 0.58 * h * math.cos(spin), z + 0.58 * h * math.sin(spin)
            spar(
                harvest,
                "Felled bole",
                (x, y + 0.38, z),
                (endx, sample(endx, endz) + 0.4, endz),
                0.092 * h,
                "907757",
            )
        if damaged:
            # At this exposure the crown tears away. Blackened forks and a
            # broken crown lie along the same bearing as the passing wave.
            snag = group(closes, 13.64 + round((i % 11) * 0.21, 2), "Burned windfall")
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
        trees.append((x, z))
    return trees


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


def survey_tent(camp, x, z, spin, scale):
    y = sample(x, z)

    def at(h, v, d):
        h, v, d = h * scale, v * scale, d * scale
        return (
            x + h * math.cos(spin) - d * math.sin(spin),
            y + v,
            z + d * math.cos(spin) + h * math.sin(spin),
        )

    for side, ink in ((-1, "D8AE80"), (1, "EAC89D")):
        a, b, c, d = (
            at(side * 3, 0, -3.5),
            at(side * 3, 0, 3.5),
            at(0, 4.3, -3.5),
            at(0, 4.3, 3.5),
        )
        face(camp, "Waxed fly", a, b, c, ink)
        face(camp, "Waxed fly", b, d, c, ink)
    spar(camp, "Ridgepole", at(0, 4.3, -4.1), at(0, 4.3, 4.1), 0.18, "775940")
    for dz in (-3.4, 3.4):
        spar(camp, "Tent upright", at(0, -0.2, dz), at(0, 4.3, dz), 0.21, "795D4B")


def first_landing():
    # A small shingle spit extends the natural shelf out into shallow water,
    # beyond the foot of the cliff. Its level crown receives the landing party.
    spit = group(0, 22.32, "Shingle landing")
    kit.pad(
        spit, "Landing beach", -136.3, 118.9, 28, 32, 19.5, 21.80, -5, 5.0, "EBAD6A"
    )
    kit.pad(
        spit, "Golden shingle", -135.6, 118.3, 23, 27, 21.65, 23.37, -5, 4.3, "F3CF96"
    )
    kit.pad(
        spit,
        "Landing crest",
        -135.5,
        118.6,
        16.7,
        21.4,
        23.30,
        24.43,
        -5,
        3.1,
        "F6D99F",
    )
    jetty = group(18.27, 22.32, "Landing gangplank")
    for k in range(4):
        dx = (k - 1.5) * 0.66
        spar(
            jetty,
            "Landing plank",
            (-142.0 + dx, 23.32, 104.6),
            (-136.8 + dx, 24.53, 114.8),
            0.66,
            "B18A5C" if k % 2 else "C19B67",
        )
    for k in range(5):
        t = (k + 1) / 6
        cx, cy, cz = -142.0 + 5.2 * t, 23.75 + 1.21 * t, 104.6 + 10.2 * t
        spar(
            jetty,
            "Foot cleat",
            (cx - 1.2, cy, cz + 0.45),
            (cx + 1.2, cy, cz - 0.45),
            0.16,
            "856647",
        )
    cargo = group(18.39, 21.82, "First survey supplies")
    for i, (x, z) in enumerate(((-131.5, 120.7), (-133.3, 122.8), (-133.0, 120.1))):
        w = 1.5 if i < 2 else 1.8
        part(
            cargo,
            "Canvas-bound provisions",
            (x, 24.42 + w * 0.48, z),
            (w, w * 0.96, 2.15),
            "AE754B" if i == 0 else "CAA477",
            512,
        )
        for dz in (-0.57, 0.57):
            part(
                cargo,
                "Crate band",
                (x, 24.42 + w * 0.48, z + dz),
                (w + 0.04, w + 0.025, 0.13),
                "655446",
            )
    # A clinker-built survey boat. Three hull strakes follow the raised sheer.
    cutter = item(model, "Model", "Cutter")
    for side in (-1, 1):
        rows = []
        for z, w, h in [
            (-13, 0.16, 3.72),
            (-8.8, 2.30, 2.77),
            (-3.8, 3.63, 2.47),
            (3.5, 3.86, 2.41),
            (9, 2.97, 2.78),
            (11.3, 0.75, 3.06),
        ]:
            rows.append(
                [
                    (side * w * 0.25, -0.34, z * 0.89),
                    (side * w * 0.65, 0.48, z * 0.955),
                    (side * w * 0.95, h - 0.55, z),
                    (side * w, h, z),
                ]
            )
        for i, row in enumerate(rows[:-1]):
            nxt = rows[i + 1]
            for j, ink in enumerate(("503E47", "885D4B", "DCA869")):
                face(cutter, "Carvel plank", row[j], row[j + 1], nxt[j], ink)
                face(cutter, "Carvel plank", nxt[j], row[j + 1], nxt[j + 1], ink)
            a, b, c, d = (
                row[3],
                nxt[3],
                (0, row[3][1] - 0.32, row[3][2]),
                (0, nxt[3][1] - 0.32, nxt[3][2]),
            )
            face(cutter, "Oiled deck", a, b, c, "C39261")
            face(cutter, "Oiled deck", b, c, d, "B68B60")
    spar(cutter, "Spruce mast", (0, 2, -3), (0, 22, -2.3), 0.43, "926D50")
    spar(cutter, "Lateen yard", (2.1, 8, -9.7), (-3.83, 22.45, 6.48), 0.36, "795745")
    # Bias-cut canvas bows out from the line of its yard. Color fields follow
    # sewn panels and visibly repeat the ochre of the original island's stalls.
    peak = np.array((-3.78, 22.3, 6.42))
    tack = np.array((2.1, 8.1, -9.7))
    clew = np.array((-2.1, 4.55, 7.87))
    for band, ink in enumerate(("DF8756", "FFE2AF", "F4C688", "DA794E", "FFE6B9")):
        u, v = band / 5, (band + 1) / 5
        left = tack + (peak - tack) * u
        right = tack + (peak - tack) * v
        a = (clew + left) * 0.5 + np.array((1.32, 0, 0))
        b = (clew + right) * 0.5 + np.array((1.32, 0, 0))
        face(cutter, "Gore", left, right, a, ink)
        face(cutter, "Gore", a, right, b, ink)
        face(cutter, "Gore", a, b, clew, ink)
    for a, b in [
        ((0, 21.6, -2.3), (0, 3.55, -12)),
        ((0, 21.6, -2.3), (-2.8, 2.64, 7)),
        (clew, (3.1, 2.6, 7.6)),
    ]:
        spar(cutter, "Standing rigging", a, b, 0.075, "735F50")
    for born, x, z, spin, scale in [
        (18.32, -104, 85, 0.22, 1.10),
        (18.53, -113, 88, -0.54, 1.22),
        (18.85, -52, 34, -0.46, 1.80),
        (19.13, -31, 49, 0.39, 1.62),
        (19.24, -16, 70, -0.55, 1.94),
        (19.48, 12, 87, 0.26, 1.63),
        (19.67, 25, 64, 0.31, 1.64),
    ]:
        retired = parcel(x, z)[1]
        if retired > born:
            survey_tent(group(born, retired, "Prospectors camp"), x, z, spin, scale)
    # Contemporary foundations take over from the first timbered mouth.
    for i, z in enumerate((7, -1, -9)):
        post = group(21.05 + i * 0.12, 24.95, "Pit props")
        for x in (-7.2, 7.2):
            spar(post, "Rough post", (x, 23.7, z), (x * 0.93, 33.4, z), 0.82, "966B47")
        header = group(21.25 + i * 0.17, 24.95, "First adit")
        spar(header, "Brow", (-8.1, 33.17, z), (8.1, 33.17, z), 1.07, "AA7F57")
        for side in (-1, 1):
            spar(
                header,
                "Knee",
                (side * 6.8, 30.6, z),
                (side * 4.7, 32.92, z),
                0.42,
                "B48E66",
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
    first_landing()
    build_settlement(group, part, face, spar, ground, DEST)
    # The pivot remains at the source map origin even as groups go in/out of frame.
    root = part(model, "Survey origin", (0, 0, 0), (0.1, 0.1, 0.1), "FFFFFF")
    root.set("referent", "FilmOrigin")
    field(root, "Transparency", "float", "1")
    field(model, "PrimaryPart", "Ref", "FilmOrigin")
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        ET.ElementTree(document).write(tmp / "CoveChronicle.rbxmx", encoding="utf-8")
        (tmp / "bake.project.json").write_text(
            json.dumps(
                {"name": "CoveChronicle", "tree": {"$path": "CoveChronicle.rbxmx"}}
            )
        )
        subprocess.run(
            [
                "rojo",
                "build",
                tmp / "bake.project.json",
                "-o",
                DEST / "CoveChronicle.rbxm",
            ],
            check=True,
        )
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
