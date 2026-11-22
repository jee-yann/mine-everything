"""Survey the fault field against the cove and dress its ancient maritime rim."""

import math
import random

import numpy as np


def build(shore, coast, sample, front_exposure, group, part, face, spar, destination):
    rng = random.Random(6733)
    sea = 20.30

    def point(a, r, y):
        return np.array((math.cos(a) * r, y, -32 + math.sin(a) * r))

    # Shared height survey includes the exact map cliffs, flat shelves, the
    # bevelled toes, the seabed and the adjoining ancient crater surface.
    ground = sample

    def grade(delta):
        # At the edge of a block the two samples lie on different steps. A
        # landed cap rests on the upper horizontal face, not on a connecting ramp.
        slope = delta / 3.4
        return slope if abs(slope) < 0.55 else 0.0

    sites = []
    for ring, angles in enumerate(
        (
            (7, 53, 102, 148, 218, 289),
            (-7, 22, 67, 96, 133, 176, 223, 270, 311),
            (1, 17, 39, 58, 76, 104, 126, 151, 174, 205, 278, 330),
        )
    ):
        for deg in angles:
            a = math.radians(deg + rng.uniform(-3.5, 3.5))
            bank, _ = coast(a)
            r = bank * (
                rng.uniform(0.22, 0.34)
                if ring == 0
                else rng.uniform(0.47, 0.69) if ring == 1 else rng.uniform(0.85, 0.94)
            )
            r = max(33.0, r)
            p = point(a, r, 0)
            x, z = p[0], p[2]
            y = ground(x, z)
            scale = (
                rng.uniform(0.71, 1.12)
                if ring == 0
                else rng.uniform(0.91, 1.43) if ring == 1 else rng.uniform(1.12, 1.66)
            )
            # Height samples under both ends of each flight prevent caps from
            # landing on an implied plane through the slopes and cliffs.
            paths = []
            for j in range(3):
                heading = a + rng.uniform(-0.30, 0.30) + (j - 1) * 0.27
                step = rng.uniform(19, 40) * scale
                xx = x + math.cos(heading) * step
                zz = z + math.sin(heading) * step
                gx = grade(ground(xx + 1.7, zz) - ground(xx - 1.7, zz))
                gz = grade(ground(xx, zz + 1.7) - ground(xx, zz - 1.7))
                paths.append(
                    (
                        xx,
                        ground(xx, zz),
                        zz,
                        rng.uniform(1.08, 1.60),
                        rng.uniform(13, 30) * scale,
                        gx,
                        gz,
                    )
                )
            pitch = grade(ground(x + 1.7, z) - ground(x - 1.7, z))
            roll = grade(ground(x, z + 1.7) - ground(x, z - 1.7))
            sites.append((x, y, z, scale, a + rng.uniform(-1.0, 1), pitch, roll, paths))

    # The slope samples and target heights are immutable production data.
    lines = [
        "-- Measured outcrop positions, ground slopes and downrange resting points.",
        "return {",
    ]
    for x, y, z, scale, yaw, sx, sz, paths in sites:
        impacts = ",".join("{" + ",".join(f"{v:.3f}" for v in s) + "}" for s in paths)
        angle = math.atan2(z + 32, x) + 0.72
        fissure = []
        for k, (away, offset) in enumerate(
            ((4.2, 0), (7.8, -1.4), (11.6, 1.3), (16.1, -0.68), (18.4, 0.84))
        ):
            px = x + scale * (math.cos(angle) * away - math.sin(angle) * offset)
            pz = z + scale * (math.sin(angle) * away + math.cos(angle) * offset)
            fissure.append(f"{{{px:.3f},{ground(px, pz) + 0.22:.3f},{pz:.3f}}}")
        lines.append(
            f"  {{{x:.3f},{y:.3f},{z:.3f},{scale:.3f},{yaw:.3f},{sx:.3f},{sz:.3f},{{{impacts}}},{{{','.join(fissure)}}}}},"
        )
    lines.append("}")
    (destination / "FaultSurvey.luau").write_text("\n".join(lines) + "\n")

    # Folded beds are exposed in short oblique patches under headland crests.
    # They follow the native rim depth and stop at small cobble beaches.
    minerals = group(0, 19.30, "Sea-cut strata and reefs")
    spray = group(0, 19.56, "Tidal froth on skerries")
    for key, (a, _, _, _) in enumerate(shore):
        if key % 4 == 2:
            continue
        length = rng.uniform(0.055, 0.16)
        for layer in range(2 if key % 3 else 1):
            prev = None
            for step in range(4):
                theta = a + length * step / 3
                bank, h = coast(theta)
                r = bank + 4.3 + layer * 3.3 + 1.8 * math.sin(theta * 7 + key * 0.7)
                p = point(theta, r, 0)
                p[1] = ground(p[0], p[2]) + 0.42
                inner = point(
                    theta, r - 0.48 - 0.25 * math.sin(step * 0.77), p[1] + 0.54
                )
                if prev is not None:
                    ink = ("C0AC93", "B0A391", "8C9F97", "B6A59C")[(key + layer) % 4]
                    face(minerals, "Mineral bedding", prev[0], prev[1], p, ink, 272)
                    face(minerals, "Mineral bedding", prev[1], inner, p, ink, 272)
                prev = (p, inner)
        for j in range(2 if key % 2 else 3):
            theta = a + rng.uniform(-0.032, 0.032)
            bank, _ = coast(theta)
            r = bank + rng.uniform(13, 29)
            p = point(theta, r, 0)
            y = ground(p[0], p[2])
            span = rng.uniform(1.6, 4.7)
            rot = theta + rng.uniform(-0.64, 0.64)
            axes = np.array(
                (
                    (math.cos(rot), 0, math.sin(rot)),
                    (0, 1, 0),
                    (-math.sin(rot), 0, math.cos(rot)),
                )
            )
            part(
                minerals,
                "Intertidal basalt",
                (p[0], max(19.62, y + 0.055), p[2]),
                (span * 0.82, span * 0.51, span * 1.73),
                ("8B859E", "AAA2B5", "797E94")[j % 3],
                272,
                axes,
                "WedgePart",
            )
            if j == 0 and key % 5 != 1:
                prev = None
                run = (0.062, 0.035, 0.12, 0.09)[key % 4]
                for step in range(5):
                    phi = theta + 0.012 + step * run / 4
                    q = point(
                        phi,
                        r
                        + (1.0 + key % 3 * 0.38) * math.sin(step * 0.74 + key * 0.21)
                        + 0.5,
                        20.49,
                    )
                    width = 0.13 + 0.47 * math.sin(math.pi * step / 4)
                    q2 = q + np.array(
                        (math.cos(phi) * width, 0.01, math.sin(phi) * width)
                    )
                    if prev is not None:
                        face(
                            spray, "Lace of broken surf", prev[0], prev[1], q, "A7D3BF"
                        )
                        face(spray, "Lace of broken surf", prev[1], q2, q, "B5D8C6")
                    prev = (q, q2)

    # Fixed sills and breakable caps share one crest outline. Most pillars
    # survive; the seaward pillar of each cluster loses its weathered crown.
    stacks = []
    for group_id, (degrees, offset, top, count) in enumerate(
        (
            (12, 15, 16, 3),
            (47, 15, 21, 3),
            (71, 11, 16, 2),
            (101, 19, 18, 3),
            (146, 18, 14, 2),
            (184, 13, 17, 2),
            (250, 15, 14, 2),
            (319, 13, 15, 2),
        )
    ):
        a = math.radians(degrees)
        for k in range(count):
            phi = a + (k - 1) * 0.069
            bank, _ = coast(phi)
            radius = bank + offset + (k % 2) * 6.7
            center = point(phi, radius, sea - 0.38)
            scale = top / 13 * (1 if k == 1 else 0.55 + 0.19 * rng.random())
            variant = (group_id + k * 2) % 3 + 1
            stacks.append(
                f"  {{{variant},{center[0]:.2f},{center[2]:.2f},{phi:.3f},{scale:.3f},{str(k == 1).lower()}}},"
            )
    (destination / "SeaStacks.luau").write_text(
        "-- Surveyed positions of the wave-cut stacks at the cliff toe.\nreturn {\n"
        + "\n".join(stacks)
        + "\n}\n"
    )

    # Rock pools collect by the lowest ribs, and warm flowering groundcover
    # breaks the silhouette of the windward heath. The blast strips the heath
    # in the same direction and order as the high canopy.
    for j in range(43):
        x, y, z, scale, yaw, _, _, _ = sites[(j * 7 + 3) % len(sites)]
        a = math.atan2(z + 32, x)
        r = math.hypot(x, z + 32)
        u = x + rng.uniform(-11, 11)
        v = z + rng.uniform(-9, 9)
        y = ground(u, v)
        at = front_exposure(r)
        heath = group(0, at + 0.08, "Windward meadow flowers")
        returning = group(13.87 + j % 6 * 0.25, 18.28, "Recovering heath")
        # The source Wildflowers use solid, broad petals and a leaf rosette.
        for target in (heath, returning):
            for k in range(3):
                phi = yaw + k * math.tau / 3
                c, s = math.cos(phi), math.sin(phi)
                axis = np.array(((c, 0, s), (0, 1, 0), (-s, 0, c)))
                part(
                    target,
                    "Meadow leaf",
                    (u + c * 0.68, y + 0.36, v - s * 0.68),
                    (2.24, 0.64, 1.21),
                    ("65B859", "7EC962", "4DA366")[k],
                    272,
                    axis,
                )
            if j % 3:
                for k in range(3):
                    phi = yaw + k * math.tau / 3
                    part(
                        target,
                        "Wildflower petals",
                        (u + math.cos(phi) * 0.39, y + 0.92, v + math.sin(phi) * 0.39),
                        (0.74, 0.27, 0.71),
                        ("FFD462", "ED9975", "EBB0C0")[j % 3],
                    )
