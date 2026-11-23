"""Bake the original replacement drawings for the fire above Citrine Cove.

Coordinates are studs on the drawing plane. The painter works from a dark
silhouette through its rolled shadow and lit banks. A cast specifies the
shape, palette, depth and placement of an individual tongue or ash roll.
The drawings deliberately use different casts and negative spaces.
Run from any directory with Python 3. No image or uploaded mesh is required.
"""

import math
from pathlib import Path


# A closed contour starts at its first pair of coordinates. Four numbers per
# subsequent segment describe a quadratic control point and endpoint.
# Each shape has a shell, a dark fold, a lit face and a hottest accent.
FORMS = {
    "sweep": [
        "0 0; -10 -1 -23 2; -35 5 -46 15; -31 8 -21 9; -26 12 -28 17; -18 12 -10 11; -5 15 -4 19; 2 13 5 11; 18 11 36 21; 31 15 21 10; 34 12 45 15; 23 5 13 3; 8 -1 0 0",
        "-39 10; -25 6 -16 6; -17 9 -20 11; -9 6 0 7; 16 7 28 13; 14 3 2 2; -17 1 -39 10",
        "-27 7; -11 3 1 4; 15 5 31 13; 13 8 3 7; -8 7 -14 9; -8 6 -5 5; -17 5 -27 7",
        "-14 5; 2 3 18 9; 2 6 -5 6; -9 6 -14 5",
    ],
    "lance": [
        "-8 0; -14 7 -17 16; -13 12 -9 11; -9 19 -11 25; -16 28 -19 35; -13 30 -8 29; -5 35 -2 46; 1 48 7 55; 4 46 6 42; 13 47 18 49; 8 40 9 35; 10 31 14 28; 9 28 6 30; 7 22 14 18; 16 16 18 13; 11 17 6 16; 9 8 15 4; 7 -2 -8 0",
        "-8 2; -12 10 -13 13; -8 11 -7 11; -9 21 -5 24; -9 31 -12 32; -6 31 -5 33; 0 36 1 44; 2 38 4 40; 7 44 10 45; 6 37 5 32; 5 25 11 22; 3 22 1 23; 2 14 9 10; 3 12 2 11; 3 5 6 3; 1 -1 -8 2",
        "-5 1; -9 8 -7 14; -6 18 -6 19; -4 16 -2 15; -2 23 -1 29; 2 32 3 36; 5 34 3 28; -1 23 5 21; 3 20 2 20; 2 13 9 8; 2 12 -1 10; 2 4 3 1; 0 -1 -5 1",
        "-4 1; -7 6 -5 11; -3 12 -2 15; 1 9 4 7; -2 10 -2 6; 0 3 0 1; -1 0 -4 1",
    ],
    "roll": [
        "-11 0; -13 5 -16 8; -23 15 -19 20; -20 17 -16 16; -18 24 -12 27; -12 26 -10 24; -11 31 -4 34; 3 39 7 36; 5 38 4 40; 12 37 12 32; 20 34 20 26; 21 22 18 20; 18 25 14 24; 12 23 13 19; 15 15 19 16; 26 18 28 15; 22 16 21 11; 17 5 11 5; 7 -1 -11 0",
        "-10 2; -11 10 -16 11; -18 12 -18 16; -14 13 -12 14; -16 22 -10 24; -11 19 -7 20; -6 26 -2 26; 3 28 1 31; 5 31 8 28; 12 31 17 28; 11 27 10 24; 10 19 15 16; 17 13 21 14; 18 10 14 11; 15 8 13 7; 7 9 5 6; 4 3 -10 2",
        "-7 2; -11 8 -13 10; -10 8 -8 9; -11 14 -9 18; -6 12 -3 14; -5 19 -2 21; 0 19 2 19; 3 23 5 23; 10 24 9 27; 12 26 11 22; 7 19 10 14; 13 10 17 11; 15 8 10 9; 8 6 4 6; 0 2 -7 2",
        "-6 4; -9 7 -10 9; -5 6 -4 8; -5 11 -4 13; 0 9 2 10; 4 12 4 13; 6 10 9 10; 5 6 2 7; -1 4 -6 4",
    ],
    "scythe": [
        "-6 0; -3 8 -8 14; -13 18 -19 19; -15 21 -11 19; -13 24 -23 27; -30 30 -37 38; -26 33 -19 32; -24 36 -28 41; -23 37 -13 34; -3 32 1 25; 7 26 13 24; 7 24 4 20; 6 12 13 9; 16 6 18 4; 10 8 6 7; 8 2 7 0; 2 -1 -6 0",
        "-4 2; -2 10 -7 16; -8 18 -13 19; -9 19 -7 18; -10 25 -19 28; -23 30 -27 33; -18 29 -14 29; -17 32 -19 33; -7 30 -1 23; 2 19 6 18; 4 17 3 17; 3 11 10 8; 5 9 3 9; 6 3 4 2; 1 0 -4 2",
        "-3 2; -1 9 -4 14; -3 13 0 12; -1 20 -9 24; -14 26 -15 28; -5 25 0 20; 3 16 4 14; 1 15 1 13; 2 8 5 6; 1 7 1 5; 1 2 -3 2",
        "-1 3; 0 6 -1 9; 2 8 3 6; 1 6 2 3; 1 2 -1 3",
    ],
    "ember": [
        "-3 0; -9 4 -9 10; -9 7 -5 7; -6 14 2 17; 8 20 6 28; 13 20 9 14; 8 10 10 8; 7 8 6 10; 3 7 2 4; 1 1 -3 0",
        "-3 2; -6 5 -6 7; -4 5 -2 6; -2 12 2 15; 7 17 8 21; 10 17 6 14; 4 11 5 10; 2 9 1 7; -1 3 -3 2",
        "-2 3; -3 5 -3 6; 0 6 0 9; 1 13 6 15; 3 11 3 8; 0 7 -2 3",
    ],
}

# Outermost rim to palest heat. Cool umber and indigo preserve the silhouette
# beside the white contact frame, and carry the buried mineral's violet seam.
COLORS = {
    "white": ("CF532E", "FF952B", "FFDE55", "FFF5C0"),
    "torch": ("9A373C", "E6592E", "FF9E32", "FFE368"),
    "red": ("483044", "974445", "DD5537", "FFAD49"),
    "wine": ("413044", "713C49", "A7554D", "DF795D"),
    "coal": ("363248", "48394E", "6C4A5F", "986577"),
    "smoke": ("524958", "645561", "7C6871", "97807E"),
}

# x, y and z are offsets in the impact frame, with +z toward the lens.
# Shape scale is signed horizontally so opposing banks can fold over each
# other. There is no global interpolation between drawings.
POSES = [
    (0.09, [
        ("sweep", "red",    0, 0, -4, 0.62, 0.40, 2),
        ("sweep", "white",  0, 1,  3, 0.59, 0.46, 0),
        ("ember", "torch", -3, 0,  0, 0.35, 0.75, -15),
    ]),
    (0.18, [
        ("scythe", "red",  -8, 0, -5, 0.56, 0.54, 7),
        ("lance", "torch",  2, 0, -2, 0.67, 0.62, -12),
        ("sweep", "torch",  0, 0,  2, 0.68, 0.42, 0),
        ("lance", "white",  0, 0,  5, 0.35, 0.47, -10),
    ]),
    (0.26, [
        ("roll", "red",     0, 0, -8, 0.78, 0.57, 4),
        ("scythe", "torch",-9, 0, -5, 0.58, 0.67, 6),
        ("lance", "white",  2, 0, -1, 0.77, 0.79, -11),
        ("ember", "white", 10, 0,  1, 0.43, 0.76, -24),
        ("sweep", "torch",  0, 0,  5, 0.75, 0.44, 0),
        ("sweep", "white",  1, 1,  7, 0.52, 0.32, 0),
    ]),
    (0.36, [
        ("roll", "red",    8, 6, -10, 0.91, 0.77, -11),
        ("scythe", "torch",-5, 0, -7, 0.85, 0.76, 3),
        ("lance", "torch",  3, 0, -3, 0.90, 0.82, -11),
        ("scythe","white", 10, 2,  0,-0.50, 0.64,-16),
        ("ember", "white",  0, 2,  2, 0.52, 0.88, 2),
        ("sweep", "torch",  1, 0,  4, 0.96, 0.56, -2),
    ]),
    (0.43, [
        ("roll", "red",   11, 9, -10, 0.94, 0.81, -12),
        ("scythe","red", -12, 1, -8, 0.71, 0.68, 8),
        ("roll","torch",  -7, 2, -6,-0.70, 0.78, 7),
        ("lance","torch",  1, 0, -2, 0.94, 0.82,-12),
        ("scythe","white", 9, 0,  0,-0.60, 0.76,-15),
        ("ember","white", -4, 0,  2, 0.76, 0.95, 8),
        ("lance","white",  2, 0,  4, 0.50, 0.49,-12),
        ("sweep","red",   -1, 0,  5, 1.03, 0.61, 0),
        ("sweep","torch",  1, 1,  7, 0.68, 0.46, 3),
    ]),
    (0.68, [
        ("roll", "wine",   3,12,-12, 1.03, 0.85,-14),
        ("roll", "red",   17, 8, -9, 0.93, 0.93,-18),
        ("scythe","red",  -6, 6, -6, 0.98, 0.73, 0),
        ("lance","torch", -1, 2, -3, 0.74, 0.73, -3),
        ("scythe","torch",12, 2,  0,-0.91, 0.79,-18),
        ("ember","white", 10, 3,  2, 0.75, 0.73,-21),
        ("scythe","white", 3, 0,  4,-0.54, 0.49,-11),
        ("sweep","wine",   0, 0,  6, 1.08, 0.59, 1),
        ("sweep","red",   -2, 1,  8, 0.71, 0.42,-1),
    ]),
    (0.80, [
        ("roll","wine",   14,18,-10, 0.99, 0.85,-21),
        ("roll","red",    22, 9, -8, 1.03, 0.84,-18),
        ("roll","coal",   -7,12, -7,-0.88, 0.72, 8),
        ("scythe","wine", -8, 7, -4, 0.80, 0.70, 1),
        ("lance","red",    2, 3, -3, 0.67, 0.68,-11),
        ("ember","torch", 18, 7,  0, 0.78, 0.68,-24),
        ("scythe","torch", 0, 1,  2,-0.58, 0.62,-12),
        ("sweep","coal",   0, 0,  5, 1.11, 0.55, 1),
    ]),
    (0.95, [
        ("roll","coal",   16,22,-10, 1.12, 0.84,-23),
        ("roll","wine",   23,10, -8, 0.97, 0.85,-19),
        ("roll","coal",  -12,15, -6,-0.79, 0.67, 3),
        ("scythe","wine", -8, 8, -4, 0.78, 0.63, 3),
        ("ember","red",   14, 6,  0, 0.76, 0.76,-26),
        ("ember","torch",  3, 4,  2, 0.39, 0.60, 2),
        ("sweep","coal",   0, 0,  4, 1.13, 0.53, 2),
    ]),
    (1.12, [
        ("roll","coal",   19,25,-13, 1.12, 0.80,-25),
        ("roll","coal",  -12,18, -7,-0.79, 0.64, 8),
        ("scythe","wine", -6, 8, -5, 0.68, 0.56, 8),
        ("ember","red",   17,10, -2, 0.55, 0.74,-26),
        ("sweep","smoke",  1, 0,  4, 1.12, 0.48, 1),
    ]),
]


def signed_area_twice(start, end, point):
    """Return a positive value when point lies left of the directed edge."""
    return (
        (end[0] - start[0]) * (point[1] - start[1])
        - (end[1] - start[1]) * (point[0] - start[0])
    )


def sample_contour(start, segments):
    points = [start]
    for control_x, control_y, end_x, end_y in segments:
        control = (control_x, control_y)
        end = (end_x, end_y)
        midpoint = ((start[0] + end_x) / 2, (start[1] + end_y) / 2)
        bend = math.dist(control, midpoint)
        steps = max(1, min(6, math.ceil(math.sqrt(bend / 0.85))))
        for step in range(1, steps + 1):
            t = step / steps
            point = tuple(
                round(
                    (1 - t) ** 2 * start_value
                    + 2 * t * (1 - t) * control_value
                    + t * t * end_value,
                    3,
                )
                for start_value, control_value, end_value in zip(start, control, end)
            )
            if math.dist(points[-1], point) > 0.03:
                points.append(point)
        start = end

    if points[-1] == points[0]:
        points.pop()
    area = sum(
        x1 * y2 - y1 * x2
        for (x1, y1), (x2, y2) in zip(points, points[1:] + points[:1])
    )
    if area <= 0:
        points.reverse()
    return points


def triangulate(points):
    """Clip ears in contour order and return one-based Luau vertex indices."""
    remaining = list(range(len(points)))
    triangles = []
    while len(remaining) > 2:
        for position, tip in enumerate(remaining):
            previous = remaining[position - 1]
            following = remaining[(position + 1) % len(remaining)]
            corners = previous, tip, following
            a, b, c = (points[index] for index in corners)
            if signed_area_twice(a, b, c) <= 0.00001:
                continue

            # An ear is convex and encloses no other point of the polygon.
            edges = ((a, b), (b, c), (c, a))
            if any(
                all(
                    signed_area_twice(start, end, points[index]) >= -0.000001
                    for start, end in edges
                )
                for index in remaining
                if index not in corners
            ):
                continue

            triangles.extend(index + 1 for index in corners)
            remaining.pop(position)
            break
        else:
            if len(remaining) == 3:
                last_triangle = (points[index] for index in remaining)
                if abs(signed_area_twice(*last_triangle)) < 0.05:
                    break
            raise ValueError(f"Self-intersection near {points[remaining[0]]}")
    return triangles



def geometry(contour):
    commands = [tuple(map(float, cmd.split())) for cmd in contour.split(";")]
    return sample_contour(commands[0], commands[1:])


def bake():
    root = Path(__file__).resolve().parents[2]
    destination = root / "src/client/MineOrigins/CinderDrawings.luau"
    lines = [
        "-- Original key drawings of the expanding curtain and overturning hot column.",
        "-- Regenerate with art/origins/draw_fire.py.",
        "return {",
        "\tforms = {",
    ]
    for name, layers in FORMS.items():
        lines.append(f"\t\t{name} = {{")
        for contour in layers:
            points = geometry(contour)
            coordinates = ", ".join(f"{x:g}, {y:g}" for x, y in points)
            indices = ", ".join(map(str, triangulate(points)))
            lines.append(f"\t\t\t{{ {{ {coordinates} }}, {{ {indices} }} }},")
        lines.append("\t\t},")
    lines.extend(["\t},", "\tcolors = {"])
    for name, swatches in COLORS.items():
        lines.append(f'\t\t{name} = {{ ' + ", ".join(f'"{s}"' for s in swatches) + " },")
    lines.extend(["\t},", "\tposes = {"])
    for time, cast in POSES:
        lines.append(f"\t\t{{ {time:g}, {{")
        for form, palette, *transform in cast:
            values = ", ".join(f"{n:g}" for n in transform)
            lines.append(f'\t\t\t{{ "{form}", "{palette}", {values} }},')
        lines.append("\t\t} },")
    lines.extend(["\t},", "}"])
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    bake()
