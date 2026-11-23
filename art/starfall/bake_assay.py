"""Cook the Citrine assay specimen as a portable, faceted Roblox model."""

import base64
import json
import math
import os
from pathlib import Path
import random
import re
import subprocess
import tempfile

import numpy as np
from scipy.spatial import Delaunay

ART = Path(__file__).resolve().parent
OUT = ART / "AssayTrace.rbxm"
STRANDS = (
    (
        (-0.47, -0.15),
        (-0.35, -0.13),
        (-0.235, -0.048),
        (-0.12, -0.076),
        (-0.012, -0.025),
        (0.084, 0.025),
        (0.197, 0.038),
        (0.307, 0.112),
        (0.466, 0.129),
    ),
    (
        (-0.012, -0.025),
        (0.065, -0.106),
        (0.152, -0.126),
        (0.204, -0.20),
        (0.311, -0.237),
    ),
    ((-0.235, -0.048), (-0.26, 0.045), (-0.35, 0.099)),
)
STRANDS = tuple(np.array(s) for s in STRANDS)


def distance(x, z):
    p = np.array((x, z))
    closest = 1.0
    for strand in STRANDS:
        for a, b in zip(strand, strand[1:]):
            v = b - a
            t = np.clip(np.dot(p - a, v) / np.dot(v, v), 0, 1)
            closest = min(closest, np.linalg.norm(p - a - t * v))
    return closest


def top(x, z):
    d = distance(x, z)
    return (
        0.154
        + 0.041 * math.sin(x * 4.9 - z * 3.2)
        + 0.021 * math.cos(z * 9 + x * 2)
        - 0.092 * math.exp(-((d / 0.055) ** 2))
    )


def sculpture():
    rng = random.Random(4251)
    objects = {}

    def add(obj, mat, a, b, c):
        objects.setdefault(obj, []).append(
            [mat, *[round(float(v), 5) for p in (a, b, c) for v in p]]
        )

    def strip(obj, low, high, tones):
        for i, a in enumerate(low):
            j = (i + 1) % len(low)
            add(obj, tones[i % len(tones)], a, low[j], high[i])
            add(obj, tones[(i + 1) % len(tones)], low[j], high[j], high[i])

    R = math.tau
    N = 16
    hull = []
    for i in range(N):
        a = (i + 0.12 * math.sin(i * 2.4)) * R / N
        hull.append(
            (
                0.558 * math.cos(a) * (1 + 0.05 * math.sin(3 * a)),
                0.384 * math.sin(a) * (1 + 0.065 * math.cos(4 * a + 0.3)),
            )
        )
    xy = list(hull)
    # Keep paired points on the two edges of the same open, branching fissure.
    for s, strand in enumerate(STRANDS):
        for k, p in enumerate(strand):
            v = strand[min(k + 1, len(strand) - 1)] - strand[max(0, k - 1)]
            normal = np.array((-v[1], v[0])) / np.linalg.norm(v)
            for spread in (-1, 0, 1):
                q = p + normal * spread * (0.053 if s == 0 else 0.036)
                if np.hypot(q[0] / 0.545, q[1] / 0.37) < 0.98:
                    xy.append(tuple(q))
    for i in range(58):
        a = rng.random() * R
        r = rng.random() ** 0.5 * 0.93
        x = 0.53 * math.cos(a) * r
        z = 0.37 * math.sin(a) * r
        if (
            distance(x, z) > 0.068
            and min(math.hypot(x - u, z - v) for u, v in xy) > 0.056
        ):
            xy.append((x, z))
    peak = [(x, top(x, z), z) for x, z in xy]
    roof = peak[:N]
    bevel = [
        (x * 1.015, rng.uniform(0.047, 0.095) + z * 0.07, z * 1.025) for x, z in hull
    ]
    belt = [
        (x * 1.01, rng.uniform(-0.01, 0.022) + z * 0.075, z * 1.015) for x, z in hull
    ]
    foot = [(x * 0.80, rng.uniform(-0.138, -0.099), z * 0.82) for x, z in hull]
    rock = ("34323E", "3C3540", "4D434A", "413941", "53484E", "403D48")
    weather = ("533F42", "72524C", "5E4545", "805A4F", "644746", "49393E")
    strip("Country rock", foot, belt, rock)
    strip("Iron-stained rind", belt, bevel, weather)
    strip("Country rock", bevel, roof, rock[2:] + rock[:2])
    for i in range(N):
        add(
            "Country rock", "302D38", foot[i], foot[(i + 1) % N], (0.004, -0.149, 0.014)
        )
    for tri in Delaunay(np.array(xy)).simplices:
        pts = [peak[i] for i in tri]
        x, y, z = np.mean(pts, axis=0)
        d = distance(x, z)
        if d < 0.035:
            pal = ("2D2141", "402956", "4F2E62", "47315A")
        elif d < 0.065:
            pal = ("5D4A60", "665367", "8F757E", "504457")
        else:
            pal = ("5C5663", "5C535D", "635967", "575460", "6A5B61", "5F5560")
        add("Country rock", rng.choice(pal), *pts)

    for si, strand in enumerate(STRANDS):
        lips = [[], []]
        centers = []
        for i, (x, z) in enumerate(strand):
            v = strand[min(i + 1, len(strand) - 1)] - strand[max(0, i - 1)]
            n = np.array((-v[1], v[0])) / np.linalg.norm(v)
            w = (0.027 if si == 0 else 0.014) * (
                0.36 if i in (0, len(strand) - 1) else 1.0
            )
            for a, sign in zip(lips, (-1, 1)):
                u, vv = np.array((x, z)) + sign * n * w
                a.append((u, top(u, vv) + 0.012, vv))
            centers.append((x, top(x, z) + 0.033, z))
        for i in range(len(strand) - 1):
            for k, edge in enumerate(lips):
                tone = (("7047A0", "7953A8"), ("AA83D8", "A382D4"))[k][i % 2]
                add("Seam", tone, edge[i], centers[i], edge[i + 1])
                add("Seam", tone, edge[i + 1], centers[i], centers[i + 1])
            if (i + si) % 2 == 0:
                near = np.array(centers[i])
                far = np.array(centers[i + 1])
                a = np.array(lips[1][i])
                b = np.array(lips[1][i + 1])
                v = np.array((0, 0.002, 0))
                add(
                    "Living thread",
                    "9B77C5",
                    near + v,
                    (near * 0.69 + a * 0.31) + v,
                    far + v,
                )
                add(
                    "Living thread",
                    "9B77C5",
                    far + v,
                    (near * 0.69 + a * 0.31) + v,
                    (far * 0.74 + b * 0.26) + v,
                )

    # The prismatic quartz has an actual six-sided basal section, growth band,
    # offset termination and a tiny polished table. Each crystal sits in the fissure.
    crystals = [
        (-0.037, -0.024, 0.102, 0.255, 0.028, 0.046, 0.22),
        (-0.199, -0.058, 0.068, 0.148, -0.036, 0.021, 0.71),
        (0.095, 0.029, 0.071, 0.191, 0.042, -0.027, 0.48),
        (0.234, 0.077, 0.057, 0.134, 0.033, 0.021, 0.04),
        (0.153, -0.15, 0.051, 0.127, 0.020, -0.028, 0.55),
        (-0.356, -0.13, 0.048, 0.116, -0.029, -0.017, 0.28),
        (0.357, 0.12, 0.038, 0.083, 0.031, 0.005, 0.85),
        (-0.275, 0.060, 0.031, 0.079, -0.012, 0.018, 0.63),
        (0.262, -0.22, 0.031, 0.066, 0.015, -0.008, 0.47),
        (-0.117, -0.072, 0.037, 0.098, -0.024, 0.015, 0.11),
    ]
    for i, (x, z, r, h, dx, dz, angle) in enumerate(crystals):
        base = top(x, z) - 0.012

        def ring(level, scale, phase):
            result = []
            for j in range(6):
                theta = angle + j * R / 6 + phase
                rockY = level + (0.035 * math.sin(theta + 1.2) if level > 0.72 else 0)
                result.append(
                    (
                        x + dx * level + math.cos(theta) * r * scale,
                        base + h * rockY,
                        z + dz * level + math.sin(theta) * r * scale * 0.88,
                    )
                )
            return result

        lo = ring(0, 0.72, 0)
        mid = ring(0.52, 1.00, 0.012)
        zone = ring(0.61, 0.99, 0.012)
        hi = ring(0.76, 0.94, 0.005)
        tip = ring(0.98, 0.195, 0.20)
        dark = ("27124F", "4E218C", "261754", "5A2BAD", "332071", "461757")
        stripe = ("6733B1", "8460D4", "482287", "9B7DE5", "6234AC", "422078")
        prism = ("49228B", "7547BD", "4338A8", "9472D7", "6938A7", "58288C")
        facets = ("B395E8", "7763D9", "6251CA", "85A6F2", "B983D3", "8047B3")
        strip("Crystal prisms", lo, mid, dark)
        strip("Growth bands", mid, zone, stripe)
        strip("Crystal prisms", zone, hi, prism)
        for j in range(6):
            k = (j + 1) % 6
            add("Crystal terminations", facets[j], hi[j], hi[k], tip[j])
            add("Crystal terminations", facets[(j + 5) % 6], hi[k], tip[k], tip[j])
            add(
                "Crystal terminations",
                "C4B5E8",
                tip[j],
                tip[k],
                (x + dx, base + h * 1.02, z + dz),
            )
        # Internal reflections follow the prism faces up to the termination.
        # Each strip follows a physical facet, so the colored edge also moves
        # correctly when the prospector turns the sample in their hand.
        if i in (0, 1, 2, 4, 5):
            front = min(range(6), key=lambda v: mid[v][2])
            bands = (
                (front, 1, ("4C26A0", "6042BD", "4B9DE8", "A9DBF2")),
                ((front + 1) % 6, -1, ("6030A6", "7D3BDD", "A171E4", "C79CE2")),
            )
            for j, step, tones in bands:
                k = (j + step) % 6
                ax, _, az = mid[j]
                offset = np.array((ax - x, 0.014, az - z))
                offset *= 0.0015 / np.linalg.norm(offset)
                cuts = []
                widths = (0.025, 0.12, 0.14, 0.135, 0.045)
                for ring_points, width in zip((lo, mid, zone, hi, tip), widths):
                    vertex = np.array(ring_points[j]) + offset
                    across = np.array(ring_points[k]) - ring_points[j]
                    cuts.append((vertex + across * 0.025, vertex + across * (0.025 + width)))
                for (a, b), (c, d), tone in zip(cuts, cuts[1:], tones):
                    add("Transmitted light", tone, a, b, c)
                    add("Transmitted light", tone, b, d, c)
        if i in (0, 2, 5):
            j = (1, 2, 0)[(0, 2, 5).index(i)]
            lift = np.array([0, 0.0029, 0])
            a, b, c = map(np.array, (tip[j], hi[j], hi[(j + 1) % 6]))
            q = a * 0.12 + b * 0.82 + c * 0.06
            w = a * 0.12 + b * 0.63 + c * 0.25
            add("Flash " + str(i), "A990D7", a + lift, q + lift, w + lift)
    # Three minute pyrite inclusions register the scale against the primary violet cluster.
    for x, z, r in (
        (-0.295, 0.14, 0.018),
        (0.21, 0.185, 0.012),
        (-0.14, -0.212, 0.011),
    ):
        y = top(x, z)
        ring = [
            (
                x + r * math.cos(j * math.pi / 2 + 0.2),
                y + 0.007,
                z + r * math.sin(j * math.pi / 2 + 0.2),
            )
            for j in range(4)
        ]
        for j in range(4):
            add(
                "Pyrite",
                "CCA269" if j % 2 else "95714F",
                ring[j],
                ring[(j + 1) % 4],
                (x + 0.002, y + 0.029, z - 0.001),
            )
    return objects


def bake():
    data = sculpture()
    source = (
        (ART / "cook_assay.luau")
        .read_text()
        .replace("SPECIMEN_SOURCE", json.dumps(json.dumps(data, separators=(",", ":"))))
    )
    studio = max(
        (Path(os.environ["LOCALAPPDATA"]) / "Roblox/Versions").glob(
            "*/RobloxStudioBeta.exe"
        ),
        key=lambda p: p.stat().st_mtime,
    )
    with tempfile.TemporaryDirectory(prefix="cove-lapidary-") as d:
        d = Path(d)
        code = d / "cook.luau"
        code.write_text(source)
        proj = d / "cook.project.json"
        proj.write_text(
            json.dumps(
                {
                    "name": "Assay",
                    "tree": {
                        "$className": "DataModel",
                        "Workspace": {"$className": "Workspace"},
                    },
                }
            )
        )
        place = d / "Assay.rbxlx"
        log = d / "result.log"
        subprocess.run(["rojo", "build", proj, "-o", place], check=True)
        si = subprocess.STARTUPINFO()
        si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        si.wShowWindow = subprocess.SW_HIDE
        subprocess.run(
            [
                studio,
                "--task",
                "RunScript",
                "--localPlaceFile",
                place,
                "--runScriptFile",
                code,
                "--outputFile",
                log,
                "--quitAfterExecution",
            ],
            startupinfo=si,
            timeout=240,
            check=True,
        )
        text = log.read_text(encoding="utf8", errors="replace")
        if not re.search(r"^ASSAY_READY\s*$", text, re.M):
            raise RuntimeError(text[-2400:])
        octets = base64.b64decode(
            "".join(re.findall(r"^ASSAY_DATA ([A-Za-z0-9+/=]+)", text, re.M)),
            validate=True,
        )
        assert octets.startswith(b"<roblox!") and len(octets) > 15000
        OUT.write_bytes(octets)
        print(
            len(octets),
            "bytes;",
            sum(len(f) for f in data.values()),
            "authored triangular facets",
        )


if __name__ == "__main__":
    bake()
