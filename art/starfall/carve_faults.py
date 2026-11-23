"""Cook three fitted volcanic outcrops into portable Roblox solids."""

import base64
import itertools
import json
import math
import os
import random
import re
import subprocess
import tempfile
from pathlib import Path

ART = Path(__file__).resolve().parent
DEST = ART.parents[1] / "src/client/Starfall"


def carve(seed):
    rng = random.Random(240 + seed * 31)
    n = 9
    rings = [[], [], [], []]
    mid = (-0.9, 1.70, 0.29)
    peak = (-0.68, 5.8 + seed * 0.75, 0.47)
    root = (0.2, -1.75, -0.25)
    for i in range(n):
        a = (i + rng.uniform(-0.19, 0.19)) * math.tau / n
        r = rng.uniform(0.88, 1.16)
        x, z = 7.8 * r * math.cos(a), (5.5 + seed * 0.43) * r * math.sin(a)
        h = 3.56 + 0.94 * math.sin(a + 0.8) + rng.uniform(-0.54, 0.57)
        for ring, scale, y in zip(
            rings,
            (1.03, 1.0, 0.91, 0.78),
            (-1.5, 1.27 + 0.63 * math.sin(a + 0.3), h - 0.37, h),
        ):
            ring.append((x * scale, y, z * scale))

    def panels(lo, hi):
        faces = []
        for k in range(len(lo) - 1):
            faces.extend(((lo[k], lo[k + 1], hi[k]), (lo[k + 1], hi[k + 1], hi[k])))
        return faces

    def fan(center, rim):
        return [(center, a, b) for a, b in itertools.pairwise(rim)]

    def add(shapes, name, faces):
        shapes[name] = [[round(v, 5) for pt in tri for v in pt] for tri in faces]

    pieces = {}
    for s in range(3):
        ids = [(s * 3 + j) % n for j in range(4)]
        low, ledge, vein, crown = [[ring[j] for j in ids] for ring in rings]
        shapes = {}
        add(
            shapes,
            "Shale",
            panels(ledge, vein)
            + [
                (mid, ledge[0], vein[0]),
                (mid, vein[0], peak),
                (mid, ledge[-1], vein[-1]),
                (mid, vein[-1], peak),
            ]
            + fan(mid, ledge),
        )
        add(shapes, "Quartz", panels(vein, crown))
        add(shapes, "Cap", fan(peak, crown))
        coords = [peak, mid, *ledge, *vein, *crown]
        center = [sum(pt[d] for pt in coords) / len(coords) for d in range(3)]
        pieces["Leaf" + str(s + 1)] = {"center": center, "shapes": shapes}
    shapes = {}
    low, ledge = rings[:2]
    add(
        shapes,
        "Foot",
        panels(low + [low[0]], ledge + [ledge[0]]) + fan(root, low + [low[0]]),
    )
    add(shapes, "Cleavage", fan(mid, ledge + [ledge[0]]))
    pieces["Bed"] = {"center": [0, 0, 0], "shapes": shapes}
    return pieces


def sea_stack(seed):
    rng = random.Random(1216 + seed * 17)
    count = 7
    rows = [[] for _ in range(5)]
    center = (-0.35, 7.45, 0.22)
    for k in range(count):
        theta = (k + rng.uniform(-0.21, 0.16)) * math.tau / count
        q = rng.uniform(0.88, 1.16)
        x, z = 4.55 * math.cos(theta) * q, (5.05 + 0.65 * seed) * math.sin(theta) * q
        tilt = 0.5 * math.cos(theta - 0.65) + 0.92 * math.sin(theta + 0.7)
        for layer, (rad, height, lean) in enumerate(
            (
                (1.30, -0.65, -0.6),
                (0.75, 2.45, 0),
                (0.97, 7.25, 0.7),
                (0.81, 11.93, 1.9),
                (0.67, 13.04, 2.4),
            )
        ):
            rows[layer].append(
                (
                    x * rad + lean,
                    height + (tilt if layer else 0),
                    z * rad + 0.22 * layer,
                )
            )

    def coat(band):
        faces = []
        for i in range(count):
            j = (i + 1) % count
            p, q = rows[band][i], rows[band][j]
            r, s = rows[band + 1][i], rows[band + 1][j]
            faces.extend(((p, q, r), (q, s, r)))
        return faces

    def face(row, peak):
        return [(row[i], row[(i + 1) % count], peak) for i in range(count)]

    def encode(polygons):
        return [
            [round(value, 4) for vertex in triangle for value in vertex]
            for triangle in polygons
        ]

    bed = {
        "Foot": encode(coat(0)),
        "Shale": encode(coat(1)),
        "Cleavage": encode(face(rows[2], center)),
    }
    top = {
        "Shale": encode(coat(2) + face(rows[2], center)),
        "Quartz": encode(coat(3)),
        "Cap": encode(face(rows[4], (2.50, 13.48, 0.49))),
    }
    return {
        "Base" + str(seed + 1): {"center": [0, 0, 0], "shapes": bed},
        "Lid" + str(seed + 1): {"center": [1.2, 9.6, 0.67], "shapes": top},
    }


def main():
    data = {name: carve(i) for i, name in enumerate(("Shelf", "Dyke", "Tor"))}
    profiles = [
        "-- Surface samples used to land each tumbling shell on a sloping footing.",
        "return {",
    ]
    for name, chunks in data.items():
        profiles.append(name + "={")
        for i in range(1, 4):
            spec = chunks["Leaf" + str(i)]
            points = set()
            for faces in spec["shapes"].values():
                for face in faces:
                    for j in (0, 3, 6):
                        points.add(
                            tuple(
                                round(face[j + k] - spec["center"][k], 3)
                                for k in range(3)
                            )
                        )
            profiles.append(
                "{"
                + ",".join(
                    "Vector3.new(" + ",".join(map(str, pt)) + ")"
                    for pt in sorted(points)
                )
                + "},"
            )
        profiles.append("},")
    profiles.append("}")
    (DEST / "FaultProfiles.luau").write_text("\n".join(profiles) + "\n")
    data["Stacks"] = {}
    for i in range(3):
        data["Stacks"].update(sea_stack(i))
    code = (
        (ART / "cook_faults.luau")
        .read_text()
        .replace("FAULT_SOURCE", json.dumps(json.dumps(data, separators=(",", ":"))))
    )
    studio = max(
        (Path(os.environ["LOCALAPPDATA"]) / "Roblox/Versions").glob(
            "*/RobloxStudioBeta.exe"
        ),
        key=lambda f: f.stat().st_mtime,
    )
    with tempfile.TemporaryDirectory(prefix="cove-fault-kit-") as folder:
        path = Path(folder)
        (path / "bake.luau").write_text(code)
        project = path / "build.project.json"
        project.write_text(
            json.dumps(
                {
                    "name": "Volcanic outcrops",
                    "tree": {
                        "$className": "DataModel",
                        "Workspace": {"$className": "Workspace"},
                    },
                }
            )
        )
        place = path / "Bake.rbxlx"
        subprocess.run(["rojo", "build", project, "-o", place], check=True)
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        log = path / "result.log"
        subprocess.run(
            [
                studio,
                "--task",
                "RunScript",
                "--localPlaceFile",
                place,
                "--runScriptFile",
                path / "bake.luau",
                "--outputFile",
                log,
                "--quitAfterExecution",
            ],
            startupinfo=startup,
            timeout=180,
            check=True,
        )
        result = log.read_text(encoding="utf8", errors="replace")
        if not re.search(r"^FAULT_COMPLETE\s*$", result, re.MULTILINE):
            raise RuntimeError(result[-2600:])
        encoded = "".join(
            re.findall("^FAULT_BYTES ([A-Za-z0-9+/=]+)", result, re.MULTILINE)
        )
        binary = base64.b64decode(encoded, validate=True)
        assert binary.startswith(b"<roblox!")
        (DEST / "FaultRocks.rbxm").write_bytes(binary)
        print("Cooked", len(binary), "bytes")


if __name__ == "__main__":
    main()
