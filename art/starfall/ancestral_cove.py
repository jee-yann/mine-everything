"""Build the prehistoric cove from the playable island's cut-block construction kit."""

import math
import numpy as np

# Overlapping shelves are surveyed from their flat tops. The six elevated
# fire-landing sites are the common ground marks used by the CraterAir shot.
# Each is (x, z, width, depth, top, angle, cap width at each chamfer).
SHELVES = [
    (-62, 28, 76, 88, 29.60, -3, 11),
    (-64, 30, 62, 67, 35.60, -3, 10),
    (-66, 33, 46, 43, 41.50, -3, 8),
    (-66, 36, 32, 29, 48.09, -3, 6),
    (-43, -14, 35, 24, 31.60, 6, 6),
    (-45, -15, 25, 18, 38.34, 6, 5),
    (-38, 58, 34, 39, 29.90, -5, 6),
    (-34, 57, 24, 24, 36.25, -5, 5),
    (-88, 82, 49, 55, 28.70, 3, 9),
    (-95, 78, 34, 34, 34.30, 3, 7),
    (-112, 74, 27, 27, 27.20, -5, 5),
    (-103, 105, 39, 25, 26.50, 0, 6),
    (58, 48, 67, 82, 30.30, 2, 11),
    (64, 65, 53, 69, 35.50, 2, 9),
    (64, 76, 41, 46, 42.60, 2, 8),
    (66, 81, 28, 30, 48.91, 2, 6),
    (52, 11, 44, 37, 31.66, -5, 7),
    (57, 12, 28, 21, 38.32, -5, 6),
    (39, -20, 32, 20, 31.66, -4, 6),
    (79, -23, 38, 40, 28.70, 3, 9),
    (-91, -34, 49, 32, 30.10, 0, 8),
    (7, 105, 47, 27, 26.63, 0, 6),
    (-30, 102, 28, 23, 27.65, -2, 5),
    (24, 59, 33, 26, 27.06, 3, 5),
]


def rotation(angle):
    c, s = math.cos(angle), math.sin(angle)
    return np.array(((c, 0, s), (0, 1, 0), (-s, 0, c)))


def contains(x, z, shelf):
    cx, cz, width, depth, _, angle, corner = shelf
    a = math.radians(angle)
    c, s = math.cos(a), math.sin(a)
    dx, dz = x - cx, z - cz
    u = abs(c * dx - s * dz) - width / 2
    v = abs(s * dx + c * dz) - depth / 2
    return u <= 0 and v <= 0 and u + v <= -corner


class CoveKit:
    def __init__(self, source, name, prop, xyz, part, field, group):
        self.part, self.field, self.group = part, field, group
        stock = {}
        for node in source.iter("Item"):
            stock.setdefault(name(node), []).append(node)

        def read(node):
            f = prop(node, "CFrame")
            matrix = np.array(
                [[float(f.find(f"R{i}{j}").text) for j in range(3)] for i in range(3)]
            )
            return (
                name(node),
                node.get("class"),
                xyz(node, "CFrame"),
                xyz(node, "size"),
                matrix,
                f'{int(prop(node,"Color3uint8").text)&0xffffff:06X}',
                int(prop(node, "Material").text),
            )

        self.bevels = [read(p)[4] for p in stock["Landing island turf"][:7]]
        self.palms = []
        for tree in stock["Sea grape"]:
            if tree.get("class") != "Model":
                continue
            self.palms.append([read(p) for p in tree.findall("Item")])
        highlands = next(p for p in source.iter("Item") if name(p) == "Cableway ridge")
        self.firs = []
        for child in highlands.findall("Item"):
            if name(child) == "Fir trunk":
                self.firs.append([read(child)])
            elif name(child) == "Fir boughs":
                self.firs[-1].append(read(child))
        assert self.palms and all(len(f) == 4 for f in self.firs)
        self.native_caps = []
        self.reef = []
        self.shelves = list(SHELVES)

    def pad(
        self,
        group,
        label,
        x,
        z,
        width,
        depth,
        bottom,
        top,
        angle,
        corner,
        color,
        material=272,
        stud=False,
        tilt=None,
    ):
        """The seven boxes/wedges and the bevel orientations are those of Landing island turf."""
        c, h = min(corner, depth * 0.34, width * 0.34), max(0.04, top - bottom)
        side = (width - c) * 0.5
        row = (depth - c) * 0.5
        pieces = [
            (0, 0, (width - 2 * c, h, depth)),
            (-side, 0, (c, h, depth - 2 * c)),
            (-side, -row, (h, c, c)),
            (-side, row, (h, c, c)),
            (side, 0, (c, h, depth - 2 * c)),
            (side, -row, (h, c, c)),
            (side, row, (h, c, c)),
        ]
        yaw = rotation(math.radians(angle))
        center = np.array((x, (bottom + top) * 0.5, z))
        for i, (u, v, size) in enumerate(pieces):
            shape = "WedgePart" if i in (2, 3, 5, 6) else "Part"
            position = center + yaw @ np.array((u, 0.0, v))
            basis = yaw @ self.bevels[i]
            if tilt is not None:
                hinge, turn = tilt
                position = hinge + turn @ (position - hinge)
                basis = turn @ basis
            piece = self.part(
                group,
                label,
                position,
                size,
                color,
                material,
                basis,
                shape,
            )
            self.field(piece, "CastShadow", "bool", "false" if h < 1.4 else "true")
            self.field(piece, "TopSurface", "token", "3" if stud else "0")
            self.field(piece, "BottomSurface", "token", "0")

    def native_tree(self, parent, index, x, y, z, size, yaw, fir):
        variants = self.firs if fir else self.palms
        stock = variants[index % len(variants)]
        p = stock[0]
        origin = p[2].copy()
        origin[1] -= p[3][1] * 0.5
        extent = max(t[2][1] + 0.5 * t[3][1] for t in stock) - origin[1]
        scale = size / extent
        r = rotation(yaw)
        for label, cl, pos, dim, basis, tint, mat in stock:
            name = (
                "Salt-pruned crown"
                if label == "Fir boughs"
                else "Sea-grape crown" if label == "Leaf crown" else label
            )
            body = self.part(
                parent,
                name,
                np.array((x, y, z)) + r @ (pos - origin) * scale,
                dim * scale,
                tint,
                mat,
                r @ basis,
                cl,
            )
            self.field(body, "TopSurface", "token", "0")

    def add_native_cap(self, pos, size, matrix, cl):
        # Tree roots, footings, shock dust and rock debris use the same height
        # as the source caps. Each of the real bevels has triangular coverage.
        if cl == "WedgePart":
            signs = [(x, y, z) for x in (-1, 1) for y, z in [(-1, -1), (-1, 1), (1, 1)]]
        else:
            signs = [(x, y, z) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
        vertices = [pos + matrix @ (size * np.array(s) * 0.5) for s in signs]
        height = max(v[1] for v in vertices)
        verts = [(v[0], v[2]) for v in vertices if height - v[1] < 0.02]
        if len(verts) < 3:
            return
        center = np.array(verts).mean(axis=0)
        corners = sorted(
            set(verts), key=lambda v: math.atan2(v[1] - center[1], v[0] - center[0])
        )
        if len(corners) < 3:
            return
        low = np.min(corners, axis=0)
        high = np.max(corners, axis=0)
        self.native_caps.append((low, high, corners, height))

    def top(self, x, z, raw):
        for shelf in self.shelves + self.reef:
            if shelf[4] > raw and contains(x, z, shelf):
                raw = shelf[4]
        return self.cap_height(self.native_caps, x, z, raw)

    @staticmethod
    def cap_height(caps, x, z, raw):
        for low, high, pts, h in caps:
            if h <= raw or x < low[0] or x > high[0] or z < low[1] or z > high[1]:
                continue
            if all(
                (b[0] - a[0]) * (z - a[1]) - (b[1] - a[1]) * (x - a[0]) >= -0.01
                for a, b in zip(pts, pts[1:] + pts[:1])
            ):
                raw = h
        return raw

    def build_shelves(self, end, wave):
        soil = ("CB8457", "DA9765", "B97457", "E6A96D")
        turf = ("74D44F", "88D75E", "83D463", "91DC66")
        for i, s in enumerate(self.shelves):
            x, z, w, d, y, angle, corner = s
            hit = wave(math.hypot(x, z + 32))
            dirt = self.group(0, end, "Ancestral sandstone shelves")
            self.pad(
                dirt,
                "Sandstone shoulder",
                x,
                z,
                w - 0.42,
                d - 0.42,
                23.6,
                y - 0.67,
                angle,
                corner,
                soil[i % 4],
            )
            for a, b, c in [
                (0, hit, turf[i % 4]),
                (hit, end, ("564B56", "695762", "66595F")[i % 3]),
            ]:
                surface = self.group(a, b, "Weather across the grass shelves")
                tilt = None
                if i in (3, 5, 7, 15, 18, 19) and a == hit:
                    # Hinge the upper bed of the surrounding hills at its
                    # outward toe. The rock beneath the tilted turf is exposed
                    # on the crater-facing side throughout the aftermath.
                    out = np.array((x, 0, z + 32)) / math.hypot(x, z + 32)
                    up = np.array((0, 1, 0))
                    basis = np.column_stack((out, up, np.cross(out, up)))
                    slope = math.radians(17)
                    cs, sn = math.cos(slope), math.sin(slope)
                    turn = basis @ ((cs, sn, 0), (-sn, cs, 0), (0, 0, 1)) @ basis.T
                    local_out = rotation(-math.radians(angle)) @ out
                    span = (abs(local_out[0]) * w + abs(local_out[2]) * d) * 0.5
                    tilt = (np.array((x, y, z)) + out * span, turn)
                    self.pad(
                        surface, "Upturned sandstone", x, z, w - 0.23, d - 0.23,
                        y - 2 * span * math.sin(slope) - 1.2, y - 0.65, angle, corner,
                        "826B68", tilt=tilt,
                    )
                self.pad(
                    surface,
                    "Turf lip",
                    x,
                    z,
                    w,
                    d,
                    y - 0.67,
                    y,
                    angle,
                    corner,
                    c,
                    256,
                    True,
                    tilt,
                )

    def build_shore(self, shore, end):
        # Horizontal shingle steps and sharp chamfers at sea level ground the
        # original cliff blocks. The western landing retains a low beach.
        for i, (a, x, z, h) in enumerate(shore):
            normal = np.array((math.cos(a), math.sin(a)))
            tangent = math.degrees(-a) + 90
            p = np.array((x, z)) + normal * (6.8 + math.sin(4 * a))
            length = max(
                14, min(30, math.hypot(x - shore[i - 1][1], z - shore[i - 1][2]) * 1.38)
            )
            q = self.group(0, end, "Wave-cut sandstone steps")
            col = ("D88F64", "A37F75", "8589A4", "AD92A2")[i % 4]
            self.reef.append(
                (p[0], p[1], length, 15.8, 22.10 + 0.45 * math.sin(i), tangent, 3.4)
            )
            self.pad(
                q,
                "Sea-worn rock shelf",
                p[0],
                p[1],
                length,
                15.8,
                19.4,
                22.10 + 0.45 * math.sin(i),
                tangent,
                3.4,
                col,
            )
            if i % 3 != 0:
                p = np.array((x, z)) + normal * (1.6 if i % 3 == 1 else 3.0)
                self.reef.append(
                    (
                        p[0],
                        p[1],
                        length * 0.89,
                        13.2,
                        23.6 + 0.75 * math.cos(a * 3),
                        tangent,
                        2.7,
                    )
                )
                self.pad(
                    q,
                    "Sand exposed by the tide",
                    p[0],
                    p[1],
                    length * 0.89,
                    13.2,
                    21.6,
                    23.6 + 0.75 * math.cos(a * 3),
                    tangent,
                    2.7,
                    ("E8B87F", "D8AD86", "E2BE9D")[i % 3],
                )
