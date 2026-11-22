"""Blender 4.x: blender -b -P art/starfall/sculpt_star.py

The shelled geode travels nose-first along local +X. Its open flank faces +Z.
Export the colored triangles and Blender's evaluated tumble at 24 frames per second.
To export a saved edit, open Falling Star.blend with -b and append -- --export.
Studio can reproduce this asset offline, including on restricted clients.
"""

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "src/client/Starfall"


def build_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    rock = bpy.data.objects.new("Star shell â€¢ tumble", None)
    scene.collection.objects.link(rock)
    palette = {}
    points, polygons, colors = [], [], []

    def mat(hexcode):
        if hexcode not in palette:
            m = bpy.data.materials.new(hexcode)
            m.diffuse_color = tuple(
                (int(hexcode[i : i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4)
            ) + (1,)
            palette[hexcode] = m
        return list(palette).index(hexcode)

    def tri(a, b, c, color):
        start = len(points)
        points.extend([(p[0], -p[2], p[1]) for p in (a, b, c)])
        polygons.append((start, start + 1, start + 2))
        colors.append(mat(color))

    # Seven overlapping plates, cut completely through at the lip. Inner fracture
    # faces remain visible where the basalt curls back from the glass.
    basalt = ["372E47", "503B57", "645067", "885766", "55435D", "343244", "624957"]
    rim = ["FBB773", "D78974", "F6BE85", "BC746F"]
    for layer, (tail, nose, rad) in enumerate(
        [(-7.2, -0.4, 2.54), (-4.3, 3.1, 3.15), (-0.8, 5.1, 2.74)]
    ):
        for side in range(6):
            angle = math.radians(40 + side * 50)
            end = angle + math.radians(44 if side in (0, 5) else 48)

            def p(x, a, r):
                return Vector(
                    (x, math.sin(a) * r + 0.08 * x, math.cos(a) * r - 0.08 * x)
                )

            stagger = math.sin(side * 2.3 + layer) * 0.55
            a = p(tail + stagger, angle, rad * 0.65)
            b = p(tail + 0.93 + stagger, end, rad * 0.72)
            c = p(nose - 0.47 + stagger, end + 0.11, rad * 0.82)
            d = p(nose + 0.65 + stagger, angle + 0.06, rad * 0.70)
            ridge = p(tail + (nose - tail) * 0.55, (angle + end) * 0.5, rad * 1.18)
            for j, (v, w) in enumerate([(a, b), (b, c), (c, d), (d, a)]):
                tri(v, w, ridge, basalt[(side + layer + j * 2) % 7])
            # Hot fissure along the outside of the plate and darker leading bevel.
            q = c * 0.84 + Vector((0.48, 0, 0))
            r = d * 0.82 + Vector((0.63, 0, 0))
            tri(c, q, d, rim[(layer + side) % 4])
            tri(d, q, r, "955866")
            tri(a, d, r, "AB6B71" if side == 0 else "4C3B50")

    def crystal(base, tip, radius, twist):
        axis = (tip - base).normalized()
        e = axis.cross(Vector((0, 1, 0))).normalized()
        f = axis.cross(e)
        ring = [
            base
            + axis * ((tip - base).length * 0.26)
            + radius
            * (
                math.cos(i * math.tau / 5 + twist) * e
                + math.sin(i * math.tau / 5 + twist) * f
            )
            for i in range(5)
        ]
        top = ["D0ACFF", "9770DF", "65479C", "B18AE9", "F8E8FF"]
        foot = ["7D529D", "644784", "443865", "865AB5", "A17ACF"]
        for i, a in enumerate(ring):
            b = ring[(i + 1) % 5]
            tri(a, b, tip, top[i])
            tri(a, base, b, foot[i])

    crystal(Vector((-4.8, -0.2, 0.3)), Vector((5.83, 0.26, 1.1)), 2.2, 0.32)
    crystal(Vector((-3.4, -0.32, 1.2)), Vector((0.5, 1.74, 3.75)), 0.87, 0.15)
    crystal(Vector((0.35, -0.46, 0.83)), Vector((4.15, -0.82, 2.95)), 0.77, 0.64)
    mesh = bpy.data.meshes.new("Basalt plates and cleaved glass")
    mesh.from_pydata(points, [], polygons)
    mesh.update()
    obj = bpy.data.objects.new("Aureole â€¢ split falling star", mesh)
    scene.collection.objects.link(obj)
    obj.parent = rock
    for m in palette.values():
        mesh.materials.append(m)
    for face, i in zip(mesh.polygons, colors):
        face.material_index = i
    scene.render.fps = 24
    scene.frame_end = 70
    for t, ax, ay, az in [
        (1, -20, 16, -16),
        (12, -8, 16, -12),
        (22, 32, 8, -18),
        (31, 73, -6, -27),
        (35, 95, -18, -34),
        (46, 134, -13, -24),
        (54, 160, 8, -20),
        (59, 180, 17, -28),
        (70, 241, 24, -34),
    ]:
        rock.rotation_euler = tuple(math.radians(v) for v in (ax, ay, az))
        rock.keyframe_insert(data_path="rotation_euler", frame=t)
    for curve in rock.animation_data.action.fcurves:
        for key in curve.keyframe_points:
            key.handle_left_type = key.handle_right_type = "AUTO_CLAMPED"
    scene.frame_set(1)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    scene.display.shading.color_type = "MATERIAL"
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_distance = 21
            area.spaces.active.shading.color_type = "MATERIAL"
    scene.render.resolution_percentage = 100
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(
        filepath=str(ROOT / "art/starfall/Falling Star.blend"), compress=True
    )

    return scene, obj, rock


def fmt(values):
    return ",".join(
        format(float(v), ".4f").rstrip("0").rstrip(".") or "0" for v in values
    )


if "--export" in sys.argv:
    scene = bpy.context.scene
    obj = scene.objects["Aureole • split falling star"]
    rock = obj.parent
else:
    scene, obj, rock = build_scene()

# Material colors use the same gamma conversion as the painting above.
mesh = obj.data
palette = [
    "".join(
        f"{round(255 * max(0, min(1, channel)) ** (1 / 2.2)):02X}"
        for channel in material.diffuse_color[:3]
    )
    for material in mesh.materials
]
mesh.calc_loop_triangles()
# B maps Blender's (x,y,z) to Roblox's (x,z,-y).
B = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
lines = [
    "-- Baked by art/starfall/sculpt_star.py using Blender 4.0.",
    "return {",
    " palette={" + ",".join(json.dumps(k) for k in palette) + "},",
    " faces={",
]
for poly in mesh.loop_triangles:
    verts = [B @ (obj.matrix_local @ mesh.vertices[i].co) for i in poly.vertices]
    lines.append(
        "  {"
        + str(poly.material_index + 1)
        + ","
        + fmt(v for p in verts for v in p)
        + "},"
    )
lines.extend([" },", " rotations={"])
for t in range(1, 71):
    scene.frame_set(t)
    rotation = B @ rock.rotation_euler.to_matrix() @ B.transposed()
    lines.append("  {" + fmt(x for row in rotation for x in row) + "},")
lines.extend([" },", "}"])
(OUT / "StarSculpture.luau").write_text("\n".join(lines) + "\n")
