"""Build the editable Blender plume and export its solids and 24 fps timing.

Each sculpt is a turbulent density surface with carved sockets. Its painted
triangles are cooked offline by Studio into portable native solids.
Run bake_plume.py from the project root to reproduce the playable content.
"""

import json
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
SCENE = ROOT / "art/starfall/Pressure Bloom.blend"
B = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
PAINT = {"Mantle": "673947", "Fold": "C55038", "Lip": "FF8A34", "Flame": "FFE180"}

# A tumbling, concave volcanic roll. Circumferential satellites break the
# sphere silhouette. The three hooked cutouts split the crown from its throat.
ROLL = {
    "Mantle": [
        (0, 1, 0, 12, 8.4, 9, 4),
        (-4.9, 1.6, 0.2, 6.7, 6.1, 7, -26),
        (-3.8, 4.0, -1.7, 6.3, 4.3, 6, 22),
        (-0.6, 4.2, 0.65, 7, 6.5, 6.2, -13),
        (3.4, 3.0, -1.85, 6.8, 5.0, 6.7, 25),
        (5, 0.45, 0.65, 6.3, 5.5, 6.4, 31),
        (2.8, -1.6, 1.8, 6.3, 4.6, 6.5, -29),
        (-2, -2, 2, 7.4, 4, 5, 14),
        (-1, 2, -4.0, 6.6, 5.9, 4.5, -12),
        (-3.85, 3.4, 2.35, 4.8, 5, 3.2, -31),
        (2.25, 4.3, 2.1, 5, 4.1, 4.4, -12),
    ],
    "Fold": [
        (-4.6, 0.0, 2.2, 6.5, 3.5, 5.7, -33),
        (-1.2, -1.9, 3.2, 7.1, 3.3, 3.8, 7),
        (2.6, -0.8, 3.25, 5.7, 4.2, 3.9, 31),
        (4.7, 0.7, 2.13, 4.6, 4.7, 4.3, 28),
        (4.0, 1.2, -2.9, 5.2, 3.6, 4.1, -18),
        (-0.55, -1.1, -3.8, 9.2, 3.3, 4.3, 13),
    ],
    "Lip": [
        (-4.3, -0.35, 4.27, 4.4, 1.2, 1.4, -35),
        (-2.6, -1.23, 4.79, 3.4, 1.06, 1.2, -3),
        (-0.25, -0.99, 4.87, 3.4, 1.04, 1.15, 17),
        (1.7, -0.3, 4.82, 2.1, 1.21, 1.5, 31),
        (3, 0.55, 4.22, 2.79, 1.25, 1.7, 43),
        (4.06, 1.34, 3.6, 2.2, 1.1, 1.2, 41),
        (-1.7, -1.56, -5.23, 4.5, 1.22, 1.6, -8),
        (1.13, -1.09, -5.04, 2.9, 1.55, 1.5, 20),
    ],
    "cuts": [
        (-1.1, 1.55, 5.8, 6.3, 3.1, 3.8, 18),
        (5.0, -2.48, -1.4, 3.7, 3.8, 5, 39),
        (-5.5, -1.4, -3.7, 3, 2.6, 3.6, -40),
    ],
}

# A vertical, offset coil, pinched in one direction and open in the other.
CURL = {
    "Mantle": [
        (-0.5, -1, 0, 7, 10, 6.1, -20),
        (1.2, 2.3, -0.4, 6.6, 10, 7.4, -27),
        (3.2, 5.8, -0.1, 6.6, 5.7, 7, -21),
        (0.55, 7, -0.4, 7.1, 4.8, 6.3, 9),
        (-2.4, 5.9, 0, 4.5, 3.6, 4.9, 30),
        (-2.1, -2.6, -0.6, 4.8, 5.6, 5.9, 2),
        (1.8, 3, -3.3, 5.8, 6.2, 3.6, -8),
        (0.9, 5.5, 2.8, 5.5, 4.1, 3.8, 8),
    ],
    "Fold": [
        (-1.8, -2.8, 1.3, 4.5, 7.2, 4.3, -19),
        (0.39, -0.22, 1.6, 4.7, 7.3, 3.7, -29),
        (2.0, 2.9, 1.8, 4.3, 5, 3.6, -6),
        (1.8, 4.4, 2.0, 3.8, 4.8, 4, -18),
        (-0.2, 5.66, 2.58, 5, 1.9, 2.8, 17),
        (-0.2, -1.4, -2, 4.6, 6.8, 3.5, -29),
    ],
    "Lip": [
        (-1.97, -3.0, 2.8, 1.8, 6.1, 1.6, -17),
        (-0.82, -0.44, 3.0, 1.65, 4.4, 1.5, -29),
        (0.75, 2.05, 3.18, 1.9, 4.6, 1.55, -26),
        (1.55, 4.0, 3.4, 1.57, 3.4, 1.4, -5),
        (0.82, 5.2, 3.26, 2.5, 1.16, 1.45, -22),
        (-0.38, 5.13, 3.16, 1.92, 1.06, 1.18, 19),
    ],
    "cuts": [(-1.38, 3.1, 2.66, 3.9, 4.2, 3.6, 22), (2.7, -1.9, -2.8, 4, 6, 4, 4)],
}

# Short explosive thrusts with tapered tips. These control points describe
# connected, closed blade cross-sections, not flat sprites or billboards.
JETS = [
    [
        (0, -5, 0, 2.15),
        (1.4, -1.2, 0.12, 2.42),
        (2.2, 2.5, 0.2, 1.68),
        (1.1, 6.9, 0.1, 0.81),
        (-1.4, 12.9, 0.23, 0.04),
    ],
    [
        (-1.1, -3, -0.2, 1.54),
        (-2.3, 0.4, -0.65, 1.9),
        (-2.5, 3.8, -1.2, 1.06),
        (-4.3, 7, -0.64, 0.05),
    ],
    [
        (1.3, -1, 1.0, 1.25),
        (3.4, 1.7, 1.7, 1.62),
        (3.5, 3.8, 1.65, 0.52),
        (5.1, 5.2, 1.45, 0.04),
    ],
]
# Kind, start, horizontal travel at full impulse, peak height, maximum girth,
# rotation and duration. Backbank, cap and flank flashes rise at separate beats.
PACKETS = [
    # A compressed foot shears to the east before the tall ash columns open.
    ("Curl", 0.012, -3, 1, 20, 1.55, 28, 1.80),
    ("Curl", 0.036, 5, -3, 52, 1.44, -41, 2.03),
    ("Roll", 0.06, -12, -8, 11, 2.28, 17, 2.36),
    ("Roll", 0.08, 27, 7, 8, 2.39, 99, 2.88),
    ("Roll", 0.095, -27, 7, 11, 2.21, 59, 2.77),
    ("Curl", 0.125, -17, -13, 71, 2.35, 31, 3.76),
    ("Curl", 0.16, -22, -17, 89, 2.72, 58, 4.45),
    ("Roll", 0.23, -26, -15, 91, 2.98, -15, 4.55),
    ("Roll", 0.27, -38, -13, 75, 2.62, 53, 4.11),
    ("Roll", 0.30, -16, -24, 83, 2.79, 89, 4.26),
    ("Roll", 0.21, 36, 16, 18, 2.20, 165, 3.29),
    ("Curl", 0.285, 42, 25, 24, 2.01, 22, 3.18),
    ("Roll", 0.355, 52, 27, 15, 1.62, 166, 2.79),
    ("Roll", 0.37, -51, 14, 12, 2.05, 227, 3.24),
    ("Curl", 0.43, -22, 23, 31, 1.94, 180, 3.28),
    # The second hot branch has a different root, direction and timing.
    ("Curl", 0.49, 9, 4, 44, 1.58, 5, 2.76),
    ("Curl", 0.595, 20, -3, 63, 1.91, 52, 3.25),
    ("Roll", 0.63, 25, -6, 80, 2.72, -32, 3.88),
    ("Roll", 0.69, 38, -7, 68, 2.39, 135, 3.83),
    ("Roll", 0.73, 15, -9, 73, 2.01, -66, 3.53),
    ("Roll", 0.77, -11, 16, 41, 2.31, 12, 3.48),
    ("Curl", 0.89, 12, 24, 36, 1.93, 88, 2.97),
    ("Roll", 1.04, 35, 25, 36, 2.00, 232, 3.15),
    ("Curl", 1.14, -41, 12, 26, 1.65, 41, 2.98),
    ("Roll", 1.29, 57, -10, 20, 1.77, 94, 2.60),
    ("Roll", 1.55, -53, -1, 23, 1.71, -25, 2.52),
]


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = 24
    scene.frame_start = 1
    scene.frame_end = 130
    mats = {}
    for key, hexcode in PAINT.items():
        mat = bpy.data.materials.new(key)
        mat.diffuse_color = tuple(
            (int(hexcode[i : i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4)
        ) + (1,)
        mats[key] = mat

    collections = {}
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from ash_surface import polygonize

    for name, specs in [("Roll", ROLL), ("Curl", CURL)]:
        col = bpy.data.collections.new(name)
        collections[name] = col
        surface = polygonize(name, specs, mats)
        for parent in list(surface.users_collection):
            parent.objects.unlink(surface)
        col.objects.link(surface)
    for i, (kind, start, x, z, height, scale, yaw, life) in enumerate(PACKETS):
        obj = bpy.data.objects.new(f"{i + 1:02} {kind}", None)
        scene.collection.objects.link(obj)
        obj.instance_type = "COLLECTION"
        obj.instance_collection = collections[kind]
        obj["kind"], obj["onset"], obj["life"] = kind, start, life
        # Fast first recoil, fanned expansion, then buoyant drift and roll.
        for u, travel, lift, spread, twist in [
            (0, 0, 0, 0.015, 0),
            (0.055, 0.31, 0.28, 0.41, -9),
            (0.16, 0.73, 0.64, 0.85, -4),
            (0.33, 0.92, 0.83, 1.0, 8),
            (0.56, 0.94, 0.86, 1.02, 17),
            (0.78, 1.02, 1.0, 1.09, 21),
            (1, 1.11, 1.18, 1.10, 28),
        ]:
            frame = 1 + 24 * (start + life * u)
            pos = Vector(
                (
                    1.32 * x * travel
                    + max(0, u - 0.35) ** 1.4 * (31 if i % 4 else -20)
                    + math.sin(math.pi * u) * (0.16 * x),
                    1.49 * height * lift + 4.2 * math.sin(math.pi * u * 1.7 + i) * u,
                    1.30 * z * travel
                    + 9.5 * math.sin(math.pi * u) * math.sin(i * 1.64),
                )
            )
            obj.location = B.transposed() @ pos
            obj.scale = (1.53 * scale * spread,) * 3
            obj.rotation_euler = (
                math.radians(8 * math.sin(i + u * 2)),
                math.radians((10 + 4 * (i % 3)) * math.sin(u * 3 + i)),
                math.radians(yaw + twist * (1 if i % 2 else -1)),
            )
            for prop in ["location", "scale", "rotation_euler"]:
                obj.keyframe_insert(data_path=prop, frame=frame)
        for fc in obj.animation_data.action.fcurves:
            for key in fc.keyframe_points:
                key.handle_left_type = key.handle_right_type = "AUTO_CLAMPED"
    scene.frame_set(38)
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.shading.color_type = "MATERIAL"
            area.spaces.active.region_3d.view_distance = 161
            area.spaces.active.region_3d.view_location = (0, 0, 41)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(SCENE), compress=True)


def export(path):
    scene = bpy.context.scene
    shapes = {}
    for kind in ["Roll", "Curl"]:
        shape = {}
        obj = next(o for o in bpy.data.collections[kind].objects if o.get("isosurface"))
        mesh = obj.data
        mesh.calc_loop_triangles()
        for tri in mesh.loop_triangles:
            tone = mesh.materials[tri.material_index].name
            verts = [B @ (obj.matrix_local @ mesh.vertices[i].co) for i in tri.vertices]
            shape.setdefault(tone, []).append([round(v, 4) for p in verts for v in p])
        shapes[kind] = shape
    tracks = []
    for obj in sorted(
        (o for o in scene.objects if o.get("kind")), key=lambda o: o.name
    ):
        start, life = obj["onset"], obj["life"]
        poses = []
        for i in range(math.ceil(life * 24) + 1):
            frame = 1 + 24 * start + i
            scene.frame_set(int(frame), subframe=frame % 1)
            pos = B @ obj.location
            e = (B @ obj.rotation_euler.to_matrix() @ B.transposed()).to_euler("XYZ")
            poses.append([round(v, 4) for v in [*pos, obj.scale.x, *e]])
        tracks.append([obj["kind"], round(start, 4), round(life, 4), poses])
    path.write_text(
        json.dumps(
            {"shapes": shapes, "tracks": tracks, "jets": JETS}, separators=(",", ":")
        )
    )


args = sys.argv[sys.argv.index("--") + 1 :]
if not bpy.data.filepath:
    build()
export(Path(args[0]))
