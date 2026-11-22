"""Bake the low moon's cast shadows from the private historical island.

Rebuild on Windows with Roblox Studio, Rojo, NumPy and Shapely >= 2.1.
"""

import base64
from collections import defaultdict
import itertools
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

import numpy as np
from shapely import constrained_delaunay_triangles
from shapely.affinity import translate
from shapely.geometry import MultiPoint, Point
from shapely.ops import unary_union


ART = Path(__file__).resolve().parent
STAGE = ART.parents[1] / "src/client/Starfall"
BEARING = np.array([-0.959, 0.218, 0.181])
DRIFT = BEARING[[0, 2]] / BEARING[1]
BOX = np.array(list(itertools.product((-0.5, 0.5), repeat=3)))
WEDGE = BOX[(BOX[:, 1] < 0) | (BOX[:, 2] > 0)]

CASTERS = {
    "Sea-grape crown", "Salt-pruned crown", "Fir boughs", "Fir trunk", "Trunk",
    "Fork", "Sandstone shoulder", "Mesa face", "Weathered sandstone", "Cape step",
    "Coastal escarpment", "Wave-worn sandstone course", "Slate crown",
    "Headland turf", "Turf lip", "Fractured stone", "Split face", "Ridgeline turf",
    "Mountain flank", "Far slope", "Summit facet",
}
SHINGLE = {
    "Golden shingle", "Sea-worn rock shelf", "Wave-worn sandstone course",
    "Sand exposed by the tide",
}
RECEIVERS = SHINGLE | {
    "Turf lip", "Meadow cap", "Grass shelf", "Landing island turf", "Mine island turf",
    "Ridgeline turf", "Turf on the rim", "Headland turf", "Brook stone",
}


def name(node):
    return node.findtext("Properties/*[@name='Name']")


def vertices(part):
    frame = part.find("Properties/*[@name='CFrame']")
    size = part.find("Properties/*[@name='size']")
    position = np.array([float(frame.findtext(key)) for key in "XYZ"])
    dimensions = np.array([float(size.findtext(key)) for key in "XYZ"])
    rotation = np.array([
        [float(frame.findtext(f"R{row}{col}")) for col in range(3)] for row in range(3)
    ])
    corners = WEDGE if part.get("class") == "WedgePart" else BOX
    return (corners * dimensions) @ rotation.T + position


def survey(place):
    source = next(p for p in ET.parse(place).iter("Item") if name(p) == "CoveChronicle")
    parcels = [p for p in source.findall("Item") if name(p).startswith("0000_")]
    grove = next(p for p in source.findall("Item") if name(p) == "Wind trees")
    parcels.extend(p for p in grove.findall("Item") if name(p).startswith("0.00_"))
    casters, surfaces, crowns = [], defaultdict(list), []
    for parcel in parcels:
        leaf_faces = []
        for part in parcel.findall("Item"):
            label = name(part)
            if label not in CASTERS and label not in RECEIVERS:
                continue
            if part.get("class") not in ("Part", "WedgePart"):
                continue
            points = vertices(part)
            center = points.mean(axis=0)
            height = points[:, 1].max()
            if height < 21.2 or abs(center[0]) > 170 or abs(center[2]) > 175:
                continue
            if label in CASTERS:
                casters.append((height, points))
            if label in {"Sea-grape crown", "Salt-pruned crown"}:
                top_face = points[BOX[:, 1] > 0][[0, 1, 3, 2]]
                leaf_faces.append((height, top_face, points))
            if label in RECEIVERS:
                top = points[abs(points[:, 1] - height) < 0.014][:, [0, 2]]
                face = MultiPoint(top).convex_hull
                if face.area > 1:
                    surfaces[round(height, 2), label].append(face)
        if leaf_faces:
            crowns.append(max(leaf_faces, key=lambda face: face[0]))
    return casters, surfaces, crowns


def footprint(corners, height, bounds):
    # A convex caster clips to the receiver plane first. Internal chords
    # also produce intersection points but do not change the convex hull.
    above = corners[:, 1] > height + 0.1
    top = corners[above]
    projected = top[:, [0, 2]] - (top[:, 1, None] - height) * DRIFT
    if not above.all():
        low = corners[~above]
        chords = top[:, None] - low[None, :]
        fraction = (height - low[:, 1]) / (chords[:, :, 1] + 1e-12)
        cuts = low[None, :] + chords * fraction[:, :, None]
        projected = np.concatenate((projected, cuts[:, :, [0, 2]].reshape(-1, 2)))
    x, z = projected.min(0)
    right, back = projected.max(0)
    if right < bounds[0] or back < bounds[1] or x > bounds[2] or z > bounds[3]:
        return None
    return MultiPoint(projected).convex_hull


def polygons(shape):
    if shape.geom_type == "Polygon":
        yield shape
    else:
        for region in getattr(shape, "geoms", ()):
            yield from polygons(region)


def triangulate(shape, height):
    faces = []
    for polygon in polygons(shape.simplify(0.25, preserve_topology=True)):
        if polygon.area < 2:
            continue
        for tri in constrained_delaunay_triangles(polygon).geoms:
            if tri.area >= 0.33:
                faces.append([
                    [round(x, 3), round(height + 0.055, 3), round(z, 3)]
                    for x, z in list(tri.exterior.coords)[:3]
                ])
    return faces


def canopy_light(crowns, casters):
    # Each tree presents a single photographed crown to the distant source.
    # Reject turned-away and occluded faces; keep the actual tilt of its leaves.
    lit = []
    for _, face, owner in crowns:
        normal = np.cross(face[1] - face[0], face[2] - face[0])
        normal /= np.linalg.norm(normal)
        if normal[1] < 0:
            normal *= -1
        if normal @ BEARING < 0.21:
            continue
        center = face.mean(axis=0)
        probe = Point(center[[0, 2]])
        shaded = False
        for highest, corners in casters:
            if corners is owner or highest <= center[1] + 0.12:
                continue
            mask = footprint(corners, center[1], probe.bounds)
            if mask is not None and mask.covers(probe):
                shaded = True
                break
        if not shaded:
            skin = np.round(face + normal * 0.06, 3)
            lit.extend((skin[[0, 1, 2]].tolist(), skin[[0, 2, 3]].tolist()))
    return lit


def cast(place):
    casters, surfaces, crowns = survey(place)
    regions = []
    for (height, label), parts in surfaces.items():
        ledge = unary_union(parts).simplify(0.08)
        if ledge.area < 20:
            continue
        casts = [
            mask for highest, corners in casters if highest > height + 0.12
            if (mask := footprint(corners, height, ledge.bounds)) is not None
        ]
        if not casts:
            continue
        shadow = unary_union(casts)
        lit = "LunarShingle" if label in SHINGLE else "LunarGrass"
        # Parallel light catches only the windward lip of a terrace. Moving
        # its footprint down-light leaves a narrow contour on the source side.
        inner = translate(ledge, xoff=-BEARING[0] * 1.25, yoff=-BEARING[2] * 1.25)
        rim = ledge.difference(inner).difference(shadow)
        for role, shape in (("Umbra", ledge.intersection(shadow)), (lit, rim)):
            triangles = triangulate(shape, height)
            if triangles:
                regions.append((role, triangles))
    crowns = canopy_light(crowns, casters)
    if crowns:
        regions.append(("Canopy", crowns))
    return regions


def bake():
    studio = max(
        (Path(os.environ["LOCALAPPDATA"]) / "Roblox/Versions").glob("*/RobloxStudioBeta.exe"),
        key=lambda exe: exe.stat().st_mtime,
    )
    with tempfile.TemporaryDirectory(prefix="cove-lunar-relief-") as temp:
        folder = Path(temp)
        project = folder / "relief.project.json"
        project.write_text(json.dumps({"name": "Lunar relief", "tree": {
            "$className": "DataModel",
            "ReplicatedStorage": {"CoveChronicle": {"$path": str(STAGE / "CoveChronicle.rbxm")}},
        }}))
        place = folder / "Island.rbxlx"
        subprocess.run(["rojo", "build", project, "-o", place], check=True)
        facets = json.dumps(cast(place), separators=(",", ":"))
        code = (ART / "cook_moonlight.luau").read_text().replace("RELIEF_FACETS", json.dumps(facets))
        script = folder / "cook.luau"
        script.write_text(code)
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        log = folder / "cook.log"
        subprocess.run([
            studio, "--task", "RunScript", "--localPlaceFile", place, "--runScriptFile", script,
            "--outputFile", log, "--quitAfterExecution",
        ], check=True, timeout=300, startupinfo=startup)
        result = log.read_text(encoding="utf8", errors="replace")
        if not re.search(r"^LUNAR_COMPLETE\s*$", result, re.MULTILINE):
            raise RuntimeError(result[-2500:])
        encoded = "".join(re.findall("^LUNAR_BYTES ([A-Za-z0-9+/=]+)", result, re.MULTILINE))
        data = base64.b64decode(encoded, validate=True)
        if not data.startswith(b"<roblox!"):
            raise ValueError("Invalid native model")
        (STAGE / "MoonlitShelves.rbxm").write_bytes(data)
        print(f"Embedded {len(data):,} bytes")


if __name__ == "__main__":
    bake()
