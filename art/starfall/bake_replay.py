"""Copy today's cove out of map/CitrineCove.rbxmx for distant replays and the broadcast.

Run after `python map/build_map.py`. It writes CoveReplay.rbxm and nothing else, so the
approved ancient set is never touched.
"""

import copy
import json
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "src/client/Starfall/CoveReplay.rbxm"
# The sea, the boundary and the spawn belong to the live place.
SKIP = {"SiteOrigin", "Landing", "Outer cliff boundary", "Lagoon", "Water glint", "Shallow water"}


def prop(i, key):
    return i.find(f'./Properties/*[@name="{key}"]')


def name(i):
    return prop(i, "Name").text


def field(i, kind, key, value):
    el = prop(i, key)
    if el is None:
        el = ET.SubElement(i.find("Properties"), kind, name=key)
    el.text = str(value)
    return el


def item(parent, cl, label):
    v = ET.SubElement(parent, "Item", {"class": cl})
    ET.SubElement(v, "Properties")
    field(v, "string", "Name", label)
    return v


def main():
    source = ET.parse(ROOT / "map/CitrineCove.rbxmx").getroot().find("Item")
    document = ET.Element("roblox", version="4")
    replay = item(document, "Model", "CoveReplay")
    site, floor = item(replay, "Model", "Present-day cove"), item(replay, "Model", "Present_EditFace")
    count = 0

    def extract(parent, top):
        nonlocal count
        for p in parent.findall("Item"):
            cl, k = p.get("class"), name(p)
            if cl in ("Model", "Folder"):
                extract(p, top or k)
            if cl not in ("Part", "WedgePart", "SpawnLocation") or k in SKIP:
                continue
            q = copy.deepcopy(p)
            for child in list(q.findall("Item")):
                if child.get("class") not in ("PointLight", "SurfaceLight", "SurfaceGui"):
                    q.remove(child)
            for key in ("CanCollide", "CanTouch", "CanQuery"):
                field(q, "bool", key, "false")
            (floor if top == "EditFace" else site).append(q)
            count += 1

    extract(source, None)
    root = item(replay, "Part", "Survey origin")
    root.set("referent", "FilmOrigin")
    size = ET.SubElement(root.find("Properties"), "Vector3", name="size")
    for k in "XYZ":
        ET.SubElement(size, k).text = "0.1"
    for key, value in (("Anchored", "true"), ("CanCollide", "false"), ("CanTouch", "false"), ("CanQuery", "false")):
        field(root, "bool", key, value)
    field(root, "float", "Transparency", 1)
    field(replay, "Ref", "PrimaryPart", "FilmOrigin")
    with tempfile.TemporaryDirectory() as folder:
        tmp = Path(folder)
        ET.ElementTree(document).write(tmp / "model.rbxmx", encoding="utf-8")
        (tmp / "bake.project.json").write_text(json.dumps({"name": "CoveReplay", "tree": {"$path": "model.rbxmx"}}))
        subprocess.run(["rojo", "build", tmp / "bake.project.json", "-o", DEST], check=True)
    print(f"{count} parts, {DEST.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
