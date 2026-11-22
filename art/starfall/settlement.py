"""Stage the working valley between the first landing and the surveyed modern cove."""

import math
from itertools import pairwise

import numpy as np


def build(group, part, face, spar, ground, destination):
    def quad(g, label, a, b, c, d, ink, mat=512):
        face(g, label, a, b, c, ink, mat)
        face(g, label, a, c, d, ink, mat)

    # Several trades occupy the same valley simultaneously. The waterman's
    # sheds on tall piers precede the cottages on the new terraces. Each gets
    # an actual platform, skeletal wall bents, roof sheets and occupied front.
    houses = [
        # x, z, width, depth, eaves, yaw, founding date, roof, walls, removed
        (-147, 97, 11, 16, 5.4, -0.44, 18.92, "BA694B", "D7B78A", 22.32),
        (-58, 49, 15, 22, 7.1, 0.34, 19.12, "C99B66", "C29161", 23.78),
        (-91, 99, 12, 18, 6.2, -0.24, 19.32, "B67A4E", "DABC8D", 23.40),
        (-37, 60, 16, 21, 8.2, 0.22, 19.80, "577E80", "D9AD77", 25.35),
        (-12, 45, 17, 22, 7.6, -0.24, 20.34, "B66D4C", "C79667", 25.62),
        (17, 62, 16, 25, 8.8, -0.29, 20.74, "A56649", "DFBE85", 26.18),
        (49, 48, 22, 29, 9.9, 0.27, 21.04, "688F89", "AE8055", 26.31),
        (-47, 91, 16, 22, 7.5, -0.48, 21.18, "C49A64", "E3C390", 25.45),
        (-10, 101, 16, 25, 8.7, -0.06, 21.67, "AB7051", "D9AD7B", 26.24),
        (36, 94, 14, 17, 7.1, -0.21, 22.11, "648C91", "B88B65", 26.13),
        (68, 26, 11, 20, 7.4, 0.32, 22.45, "C99F6E", "E3CAA1", 26.48),
    ]
    for index, (x, z, w, d, h, yaw, born, roof, wall, retire) in enumerate(houses):
        # The waterfront shed stands on piles. Inland families first level their
        # lot, then build a low stone foundation and frame a house on top.
        sx, sz = math.cos(yaw), math.sin(yaw)
        rot = np.array(((sx, 0, sz), (0, 1, 0), (-sz, 0, sx)))
        corners = [
            (x + sx * u + sz * v, z - sz * u + sx * v)
            for u in (-w / 2, w / 2)
            for v in (-d / 2, d / 2)
        ]
        if index == 0:
            y = 23.62
        else:
            while (
                max(ground(xx, zz, born) for xx, zz in corners) > 26.1 and born < 24.7
            ):
                born += 0.08
            y = max(24.72, max(ground(xx, zz, born) for xx, zz in corners) + 0.32)
        center = np.array((x, y, z))

        def at(u, height, v, axis=rot, origin=center):
            return origin + axis @ np.array((u, height, v))

        foot = group(
            born, retire, "Pier foundations" if index == 0 else "Stone foundations"
        )
        part(foot, "Floor of hewn planks", center, (w, 0.57, d), "A78460", 512, rot)
        if index == 0:
            for u in (-w * 0.43, w * 0.43):
                for v in (-d * 0.40, 0, d * 0.40):
                    top = at(u, 0, v)
                    bottom = top.copy()
                    bottom[1] = 18.8
                    spar(foot, "Driven pile", bottom, top, 0.74, "80654D")
        else:
            depth = y - 22.74
            part(
                foot,
                "Rubble plinth",
                at(0, -depth / 2, 0),
                (w + 0.14, depth, d + 0.18),
                "817D75",
                800,
                rot,
            )
            part(
                foot,
                "Foundation course",
                at(0, -0.39, 0),
                (w + 0.56, 0.44, d + 0.54),
                "A39883",
                800,
                rot,
            )
        frame = group(born + 0.24, retire, "Framed buildings")
        for v in (-d * 0.46, 0, d * 0.46):
            for u in (-w * 0.46, w * 0.46):
                spar(frame, "Wall post", at(u, 0, v), at(u, h, v), 0.65, "866145")
                spar(
                    frame,
                    "Rafter",
                    at(u * 1.10, h - 0.32, v),
                    at(0, h + 4.2, v),
                    0.53,
                    "9E7954",
                )
            spar(
                frame,
                "Tie beam",
                at(-w * 0.47, h - 0.20, v),
                at(w * 0.47, h - 0.20, v),
                0.62,
                "8E694D",
            )
        shade = group(born + 0.55, retire, "Roof decks")
        side = group(born + 0.78, retire, "Inhabited sheds")
        for s in (-1, 1):
            a, b = at(0, h + 4.36, -d * 0.55), at(s * w * 0.55, h - 0.32, -d * 0.55)
            c, e = at(s * w * 0.55, h - 0.32, d * 0.55), at(0, h + 4.36, d * 0.55)
            quad(shade, "Pitched roof", a, b, c, e, roof)
            # A narrow eave catches sunlight, making each roof's slope legible.
            spar(shade, "Bargeboard", a, b, 0.36, "CDAB80")
            part(
                side,
                "Weatherboards",
                at(s * w * 0.46, h * 0.45, 0),
                (0.23, h * 0.89, d * 0.91),
                wall,
                512,
                rot,
            )
            part(
                side,
                "Front boarding",
                at(s * w * 0.31, h * 0.47, d * 0.46),
                (w * 0.29, h * 0.93, 0.28),
                wall,
                512,
                rot,
            )
            part(
                side,
                "Shutter",
                at(s * w * 0.30, h * 0.59, d * 0.485),
                (w * 0.16, h * 0.38, 0.23),
                "517178",
                512,
                rot,
            )
            part(
                side,
                "Window light",
                at(s * w * 0.30, h * 0.58, d * 0.50),
                (w * 0.105, h * 0.23, 0.11),
                "E6C589",
                512,
                rot,
            )
        part(
            side,
            "Far wall",
            at(0, h * 0.45, -d * 0.46),
            (w * 0.89, h * 0.90, 0.21),
            wall,
            512,
            rot,
        )
        for v in (-d * 0.46, d * 0.46):
            face(
                side,
                "Gable",
                at(-w * 0.46, h - 0.10, v),
                at(w * 0.46, h - 0.10, v),
                at(0, h + 3.93, v),
                wall,
                512,
            )
        if index % 3 == 0:
            part(
                side,
                "Chimney",
                at(w * 0.27, h + 2.2, -d * 0.23),
                (1.6, 5.2, 1.75),
                "877670",
                800,
                rot,
            )
        # Close the gap from the doorstep to the road.
        for k in range(5):
            part(
                side,
                "Gallery stair",
                at(0, -0.36 * k, d * 0.52 + 0.65 * k),
                (w * 0.27, 0.36, 1.0),
                "A88159",
                512,
                rot,
            )
        if index == 0:
            spar(
                frame,
                "Brace on piles",
                at(-w * 0.43, -3.2, d * 0.40),
                at(w * 0.43, -0.23, d * 0.40),
                0.43,
                "84694F",
            )

    # Dirt road and causeway are drawn again on each new cut level, so the
    # ridgeline moves independently while carts can follow a continuous route.
    main = [
        (-139, 100),
        (-119, 91),
        (-91, 81),
        (-66, 69),
        (-44, 55),
        (-23, 36),
        (-9, 21),
        (0, 6),
    ]
    branches = [
        [(-44, 55), (-14, 63), (13, 78), (38, 76), (59, 61)],
        [(-66, 69), (-83, 48), (-75, 31), (-62, 25)],
        [(13, 78), (12, 101), (-18, 114)],
    ]
    years = [
        18.80,
        18.88,
        19.45,
        19.50,
        19.82,
        20.02,
        20.07,
        20.32,
        20.44,
        20.64,
        20.94,
        21.31,
        21.51,
        22.69,
        23.45,
        24.22,
        25.02,
        25.86,
    ]
    for step, (start, end) in enumerate(pairwise(years)):
        progress = min(7, int((start - 18.80) / 0.43))
        routes = [main[: min(8, 3 + progress)]] + branches[
            : max(0, min(3, progress - 2))
        ]
        traces = group(start, end, "Carriers' roads")
        for line in routes:
            edge = []
            for i, point in enumerate(line):
                if i == 0:
                    continue
                a, b = np.array(line[i - 1]), np.array(point)
                gap = b - a
                count = math.ceil(np.linalg.norm(gap) / 5.5)
                side = np.array((-gap[1], gap[0])) / np.linalg.norm(gap)
                breadth = min(3.2, 1.1 + progress * 0.27)
                for j in range(count + 1):
                    if i > 1 and j == 0:
                        continue
                    c = a + gap * j / count
                    marks = []
                    for sign in (-1, 1):
                        xx, zz = c + side * sign * breadth
                        yy = ground(xx, zz, start) + 0.35
                        marks.append((xx, yy, zz))
                    if edge:
                        quad(
                            traces,
                            "Haul track",
                            edge[0],
                            edge[1],
                            marks[1],
                            marks[0],
                            "D7AE77" if progress < 4 else "E8C68C",
                            272,
                        )
                    edge = marks
            edge = []

    # A continuous earthen shoulder and its rubble facing retain the new
    # builders' road. Its top sits below a standing worker's waist.
    bank = group(20.64, 25.35, "Terrace retaining bank")
    edge = [(0, 81), (12, 80), (24, 78.4), (37, 75.3), (50, 73.6), (63, 68.9)]
    for j, ((x, z), (xx, zz)) in enumerate(pairwise(edge)):
        top = 25.88
        quad(
            bank,
            "Rubble breast",
            (x, top, z),
            (xx, top, zz),
            (xx, 23.65, zz + 0.54),
            (x, 23.65, z + 0.54),
            "AC92A1" if j % 2 else "B29EAC",
            272,
        )
        quad(
            bank,
            "Road shoulder",
            (x, top, z),
            (xx, top, zz),
            (xx, 24.18, zz - 3.5),
            (x, 24.18, z - 3.5),
            "D39D69",
            272,
        )
        spar(
            bank,
            "Timber coping",
            (x, top + 0.12, z),
            (xx, top + 0.12, zz),
            0.31,
            "B0936C",
        )

    # Excavation continually uncovers a larger face. benches, lift house and
    # staging occupy far more screen area than the rails alone.
    for i, (start, end, width, depth) in enumerate(
        [
            (19.68, 20.49, 11, 7),
            (20.49, 21.34, 21, 13),
            (21.34, 22.37, 35, 20),
            (22.37, 24.92, 46, 27),
        ]
    ):
        g = group(start, end, "Cut into the ore bank")
        for side in (-1, 1):
            cx = side * (width * 0.36 + 1)
            for shelf in range(3):
                xx = cx + side * shelf * 3.5
                zz = -7 - depth * 0.44 - shelf * 2.2
                h = 2.8 + shelf * 2 + min(i, 2) * 0.8
                part(
                    g,
                    "Rock bench",
                    (xx, 24 + h / 2, zz),
                    (width * 0.28 + 3, h, depth + 3),
                    "89746D" if shelf % 2 else "9E8776",
                    800,
                )
                part(
                    g,
                    "Exposed band",
                    (xx, 24 + h - 0.68, zz + 0.5),
                    (width * 0.28 + 3.1, 0.49, depth + 2.5),
                    "AE9A88",
                    800,
                )
        if i >= 1:
            part(
                g,
                "Open adit",
                (0, 27.55, -11 - depth * 0.30),
                (width * 0.31, 6.8, 1.8),
                "46424E",
                800,
            )

    for side in (-1, 1):
        site = group(20.84, 25.82, "Ore winding tower")
        for z in (-8, 6):
            spar(
                site,
                "Splayed legs",
                (side * 8.3, 23.8, z),
                (side * 5.1, 49, z + 1),
                0.95,
                "805D45",
            )
        spar(
            site,
            "Trestle brace",
            (side * 7.8, 27, -7),
            (side * 5.4, 44, 5.4),
            0.75,
            "B28C63",
        )
        spar(
            site,
            "Trestle brace",
            (side * 7.6, 27, 5),
            (side * 5.4, 44, -6),
            0.75,
            "8C6C54",
        )
        spar(
            site,
            "Head frame sill",
            (-7, 46.0, side * 5),
            (7, 46.0, side * 5),
            0.89,
            "9B754F",
        )
    hoist = group(21.37, 25.82, "Head sheave and hauling cable")
    for i in range(12):
        a, b = i * math.pi / 6, (i + 1) * math.pi / 6
        p = (-1 + 4.4 * math.cos(a), 49 + 4.4 * math.sin(a), 2)
        q = (-1 + 4.4 * math.cos(b), 49 + 4.4 * math.sin(b), 2)
        spar(hoist, "Sheave rim", p, q, 0.65, "565E61")
        if i % 2 == 0:
            spar(hoist, "Spoke", (-1, 49, 2), p, 0.31, "747B77")
    spar(hoist, "Bucket cable", (3.3, 48.7, 2), (3.3, 26.2, 2), 0.19, "4E5050")
    spar(hoist, "Cable to winch", (-4.8, 51, 2), (-19, 28, 15), 0.20, "565C5A")
    part(hoist, "Lift bucket", (3.3, 27, 2), (3.2, 2.0, 3.2), "866D58", 512)

    # Sawyers leave stockpiles at different worksites in successive exposures.
    for i, (x, z, born, end) in enumerate(
        [
            (-69, 81, 18.96, 21.10),
            (-65, 55, 19.85, 22.62),
            (-30, 48, 20.76, 24.15),
            (35, 51, 21.94, 25.83),
            (4, 18, 22.37, 25.71),
        ]
    ):
        dates = (
            [born]
            + [
                t
                for t in (
                    18.88,
                    19.45,
                    19.5,
                    19.82,
                    20.02,
                    20.07,
                    20.32,
                    20.44,
                    20.64,
                    20.94,
                    21.31,
                    21.51,
                )
                if born < t < end
            ]
            + [end]
        )
        for start, stop in pairwise(dates):
            yard = group(start, stop, "Sawpit and storage")
            y = ground(x, z, start)
            for k in range(7):
                off = (k % 4 - 1.5) * 1.08
                yy = y + 0.56 + (1 if k >= 4 else 0)
                spar(
                    yard,
                    "Stacked timbers",
                    (x - 5.1, yy, z + off),
                    (x + 5.2 - 0.58 * (k % 3), yy, z + off),
                    0.89,
                    "A47D53",
                )
            for j in range(3):
                part(
                    yard,
                    "Ore crate",
                    (x - 3 + j * 2.7, y + 1.13, z + 3.6),
                    (2.4, 2.2, 2.7),
                    "937452",
                    512,
                )

    population(destination, ground)

    # The graded frontage has a bench and a sawhorse in the open, so that
    # carpenters still read among the larger buildings beyond them.
    for start, end in pairwise(
        (19.30, 20.02, 20.64, 20.76, 21.38, 21.94, 22.56, 22.68, 23.30, 24.17, 24.51)
    ):
        yard = group(start, end, "Builders' yard")
        for x, z in ((19.6, 82.7), (46.0, 76.5)):
            y = ground(x, z, start)
            for dx in (-2.7, 2.7):
                for sign in (-1, 1):
                    xx, zz = x + dx, z + sign * 1.16
                    spar(
                        yard,
                        "Sawhorse leg",
                        (xx, ground(xx, zz, start), zz),
                        (xx, y + 2.1, z),
                        0.41,
                        "A87945",
                    )
            part(
                yard,
                "Sawhorse beam",
                (x, y + 2.24, z),
                (7.9, 0.54, 0.84),
                "DEAB65",
                512,
            )


def population(destination, ground):
    """Expose new people and places at each shutter; never move one actor along a build schedule."""
    # Indexed sites span boat landing, switchback, timber camp, quarry, sawmill,
    # rail siding, gate, market and wharf. All dates sample actual ground height.
    sites = [
        (-120, 91),
        (-101, 84),
        (-82, 74),
        (-70, 62),
        (-55, 56),
        (-36, 52),
        (-26, 37),
        (-17, 24),
        (12, 22),
        (28, 39),
        (49, 62),
        (25, 81),
        (-17, 94),
        (-64, 91),
        (-90, 38),
        (-87, 56),
        (-10, 11),
        (6, 9),
        (-68, 35),
        (48, 36),
        (6, 72),
        (-37, 80),
    ]
    poses = ("march", "haul", "reach", "sight", "lift", "kneel", "strike")
    stations = (
        ((19.2, 85.0, "sight"), (44.4, 78.8, "haul"), (8.1, 80.0, "lift")),
        ((28.8, 77.2, "haul"), (20.8, 84.5, "strike"), (53.9, 72.0, "sight")),
        ((45.3, 79.0, "lift"), (16.5, 91.3, "haul"), (30.6, 81.2, "sight")),
        ((7.0, 87.6, "sight"), (42.8, 75.2, "strike"), (23.0, 84.2, "lift")),
    )
    sheet = []
    dates = (
        17.94,
        18.36,
        18.75,
        19.14,
        19.49,
        19.85,
        20.23,
        20.62,
        20.98,
        21.36,
        21.74,
        22.08,
        22.47,
        22.82,
        23.16,
        23.49,
        23.83,
        24.18,
        24.57,
        24.98,
        25.38,
        25.86,
        26.39,
        26.90,
    )
    for i, t in enumerate(dates):
        band = min(3, max(0, (i - 2) // 5))
        count = min(11, 2 + i // 2)
        take = min(len(sites), 3 + i)
        cells = []
        for n in range(count):
            site = (i * 3 + n * 5 + n // 3) % take
            x, z = sites[site]
            x += (n % 3 - 1) * 1.6
            z += ((i + n) % 3 - 1) * 1.33
            look = (-0.72, 1.15, 2.62, -2.11, 0.18)[(site + n) % 5]
            pose = poses[(n + 3 * i + site) % len(poses)]
            if 19.14 <= t < 24.51 and n < min(3, count - 1):
                x, z, pose = stations[i % len(stations)][n]
                look = (2.38, -1.85, 1.33)[(i + n) % 3]
            y = ground(x, z, t) + 0.11
            costume = (n + 4 * band + 2 * (i % 3)) % 18 + 1
            cells.append((costume, x, y, z, look, pose))
        if len({v[0] for v in cells}) != len(cells):
            raise ValueError(t)
        code = ",".join(
            f'{{{a},{x:.2f},{y:.2f},{z:.2f},{look:.2f},"{pose}"}}'
            for a, x, y, z, look, pose in cells
        )
        sheet.append(f"\t{{{t:.2f},{{{code}}}}},")
    (destination / "Population.luau").write_text(
        "-- Exposure sheet generated from the terrain under each worksite.\nreturn {\n"
        + "\n".join(sheet)
        + "\n}\n"
    )
