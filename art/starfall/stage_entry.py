"""Stage and export the flight in Blender. Run blender -b -P stage_entry.py.

Open Flight Layout.blend to edit a camera rail, aim, or body exposure. To bake
those edits, run blender -b "Flight Layout.blend" -P stage_entry.py -- --export.
"""

import math
import sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector, Quaternion

ART = Path(__file__).resolve().parent
OUT = ART.parents[1] / "src/client/Starfall/FlightTrack.luau"
B = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
V = Vector
CONTACT = V((0, 26, -32))
HEADING = Matrix.Rotation(math.radians(64), 3, "Y")
BACK = (HEADING @ V((-270, 178, -159))).normalized()
SHOTS = [
    ("Crossing", 54, 96, 37, -2),
    ("Cleavage to chase", 96, 210, 32, 2),
    ("Shore", 210, 240, 54, 0),
]


def point(frame):
    # Shooting distance along one unbroken line. Release the overcranked
    # photography for the three real-time offshore exposures.
    travel = frame - 54
    distance = 774 - travel * (1.65 + 0.0065 * travel)
    if frame > 210:
        distance = 358.416 - (frame - 210) * 2.04
    if frame >= 236:
        distance = {236: 303, 237: 287, 238: 191, 239: 95, 240: 0}[frame]
    return CONTACT + BACK * distance


def rail(keys, f):
    """Hermite interpolation with tangents in studs (or degrees) per exposure."""
    for i in range(1, len(keys)):
        a, b = keys[i - 1], keys[i]
        if f <= b[0]:
            prev, nxt = keys[max(0, i - 2)], keys[min(len(keys) - 1, i + 1)]
            dt = b[0] - a[0]
            u = max(0, (f - a[0]) / dt)
            m0 = (b[1] - prev[1]) * (dt / (b[0] - prev[0]))
            m1 = (nxt[1] - a[1]) * (dt / (nxt[0] - a[0]))
            return (
                (2 * u**3 - 3 * u * u + 1) * a[1]
                + (u**3 - 2 * u * u + u) * m0
                + (-2 * u**3 + 3 * u * u) * b[1]
                + (u**3 - u * u) * m1
            )
    return keys[-1][1]


# Camera and focus in flight coordinates (along the fall, above it, across
# it). A half turn around the bisector of the two views carries the lens up
# over the exposed flank and onto the rear shoulder above the jet.
def chase_rail(f):
    def crystal(k):
        u = (k - 96) / 60
        lag = -3.15 + u * (6.20 + 1.05 * u)
        return V((9.95366 - lag, -16.25481, 12.76849)), V(
            (1.51168 - lag, 0.14569, -0.70036)
        )

    if f <= 137:
        eye, look = crystal(f)
        return eye, look, 32, 2
    eye0, look0 = crystal(137)
    rear = V((-55.2, 15.5, -11.6))
    axis = (eye0.normalized() + rear.normalized()).normalized()
    angle = rail(
        [
            (137, 0),
            (143, 5),
            (150, 24),
            (159, 59),
            (169, 102),
            (179, 140),
            (190, 161),
            (201, 173),
            (210, 180),
        ],
        f,
    )
    radius = rail(
        [
            (137, eye0.length),
            (150, 23.1),
            (160, 26.6),
            (172, 32.8),
            (179, 37.7),
            (190, 45.8),
            (200, 51.9),
            (210, rear.length),
        ],
        f,
    )
    eye = (Quaternion(axis, math.radians(angle)) @ eye0.normalized()) * radius
    look = rail(
        [
            (135, crystal(135)[1]),
            (137, look0),
            (149, V((-0.95, 0.1, -0.7))),
            (161, V((-0.6, 1.4, 0.1))),
            (173, V((0.8, 3.0, 1.6))),
            (180, V((3.8, 5.8, 0.7))),
            (187, V((8.4, 10.9, -1))),
            (196, V((14.7, 16.5, -1.1))),
            (210, V((23, 19.8, -0.8))),
        ],
        f,
    )
    fov = rail(
        [
            (137, 32),
            (148, 32.6),
            (161, 39),
            (175, 47),
            (187, 53),
            (200, 55),
            (210, 55.5),
        ],
        f,
    )
    roll = rail(
        [(137, 2), (150, 3.5), (165, 6.4), (180, 2.0), (195, -2.1), (210, -1.15)], f
    )
    return eye, look, fov, roll


def empty(name, scene):
    obj = bpy.data.objects.new(name, None)
    scene.collection.objects.link(obj)
    return obj


def linear(obj):
    if obj.animation_data and obj.animation_data.action:
        for curve in obj.animation_data.action.fcurves:
            for key in curve.keyframe_points:
                key.interpolation = "LINEAR"


def stage():
    bpy.ops.wm.open_mainfile(filepath=str(ART / "Falling Star.blend"))
    scene = bpy.context.scene
    rock = next(o for o in scene.objects if o.type == "MESH").parent
    poses = {}
    for k in range(1, 71):
        scene.frame_set(k)
        poses[k] = rock.rotation_euler.copy()
    rock.animation_data_clear()
    rock.name = "Exposed core"
    carrier = empty("Line of fall", scene)
    buffet = empty("Ablation buffet", scene)
    buffet.parent = carrier
    rock.parent = buffet
    # Roblox's local X points along the atmospheric stream.
    forward = -BACK
    right = forward.cross(V((0, 1, 0))).normalized()
    up = right.cross(forward).normalized()
    # Engine looks along -Z, followed by a +90 degree local Y turn.
    eye = Matrix((right, up, -forward)).transposed() @ Matrix.Rotation(
        math.pi / 2, 3, "Y"
    )
    carrier.rotation_euler = (B.transposed() @ eye @ B).to_euler()
    # Key shapes come from the approved shell. Threes across the glancing
    # insert leave time to see the cleavage; the last few keys wind up for
    # the pass. Every exposure still translates along the unbroken carrier.
    timing = [
        (54, 1),
        (57, 2),
        (60, 4),
        (63, 6),
        (66, 7),
        (69, 9),
        (72, 11),
        (75, 13),
        (78, 15),
        (81, 17),
        (84, 19),
        (87, 20),
        (90, 22),
        (93, 24),
        (96, 25),
        (99, 26),
        (102, 27),
        (105, 28),
        (108, 29),
        (111, 30),
        (115, 31),
        (119, 32),
        (123, 33),
        (127, 34),
        (131, 35),
        (135, 36),
        (138, 37),
        (141, 38),
        (144, 39),
        (146, 40),
        (148, 41),
        (150, 42),
        (152, 43),
        (154, 45),
        (155, 46),
        (156, 47),
        (158, 48),
        (160, 50),
        (161, 52),
        (162, 54),
        (163, 56),
        (164, 58),
        (165, 60),
        (166, 61),
        (167, 62),
        (168, 64),
        (170, 66),
        (172, 68),
        (174, 69),
        (177, 70),
        (180, 71),
        (183, 72),
        (186, 73),
        (189, 74),
        (192, 75),
        (195, 76),
        (198, 77),
        (201, 78),
        (204, 79),
        (207, 80),
        (210, 81),
        (213, 82),
        (216, 83),
        (219, 84),
        (222, 85),
        (225, 86),
        (228, 87),
        (230, 88),
        (232, 89),
        (234, 90),
        (236, 91),
        (238, 92),
        (240, 94),
    ]
    # Two pressure buffets rock the split shell against the carrier. Both
    # camera rails and the ionised envelope inherit the stable centre only.
    for frame, pitch, yaw in [
        (54, 0, 0),
        (80, 0.35, -0.25),
        (88, -0.45, 0.38),
        (96, 0, 0),
        (105, 0.30, 0.42),
        (113, -0.58, 0.27),
        (117, 1.8, -1.1),
        (120, -1.15, 0.76),
        (124, 0.42, -0.25),
        (128, 0.04, 0.08),
        (136, -0.3, 0.25),
        (141, -1.45, 0.82),
        (144, 1.10, -0.59),
        (148, -0.34, 0.19),
        (153, 0.14, -0.10),
        (159, -0.92, 0.41),
        (164, 0.64, -0.22),
        (170, 0, 0),
        (200, 0.27, 0.40),
        (216, -0.43, -0.67),
        (235, 0.79, -0.41),
        (240, 0, 0),
    ]:
        buffet.rotation_euler = (0, math.radians(yaw), math.radians(pitch))
        buffet.keyframe_insert(data_path="rotation_euler", frame=frame)
    linear(buffet)
    for frame, key in timing:
        rock.rotation_euler = poses[min(70, key)].copy()
        if key > 70:
            rock.rotation_euler.x += math.radians(2.6 * (key - 70))
        rock.keyframe_insert(data_path="rotation_euler", frame=frame)
    for curve in rock.animation_data.action.fcurves:
        for key in curve.keyframe_points:
            key.interpolation = "CONSTANT"
    for f in range(54, 241):
        carrier.location = B.transposed() @ point(f)
        carrier.keyframe_insert(data_path="location", frame=f)
    linear(carrier)
    for name, start, end, lens, roll in SHOTS:
        camera = bpy.data.cameras.new(name)
        cam = bpy.data.objects.new(name, camera)
        scene.collection.objects.link(cam)
        aim = empty(name + " focus", scene)
        camera.sensor_fit = "VERTICAL"
        camera.lens = camera.sensor_height / (2 * math.tan(math.radians(lens) / 2))
        marker = scene.timeline_markers.new(name, frame=start)
        marker.camera = cam
        for f in range(start, end + 1):
            p = point(f)
            u = (f - start) / (end - start)
            if name == "Crossing":
                eye = point(75) + HEADING @ V((-34, -29, 118))
                look = point(75) + HEADING @ V((2.5 * u, 0, 0))
            elif name == "Cleavage to chase":
                mount, target, lens, roll = chase_rail(f)
                basis = Matrix((forward, up, right)).transposed()
                eye, look = p + basis @ mount, p + basis @ target
            else:
                eye = V((251, 131, 105))
                look = V((-7, 34, -21))
            cam.location = B.transposed() @ eye
            aim.location = B.transposed() @ look
            camera.lens = camera.sensor_height / (2 * math.tan(math.radians(lens) / 2))
            camera.keyframe_insert(data_path="lens", frame=f)
            cam["roll"] = math.radians(roll)
            cam.keyframe_insert(data_path='["roll"]', frame=f)
            cam.rotation_euler = (
                (aim.location - cam.location).to_track_quat("-Z", "Y")
                @ Quaternion((0, 0, 1), math.radians(roll))
            ).to_euler()
            cam.keyframe_insert(data_path="location", frame=f)
            cam.keyframe_insert(data_path="rotation_euler", frame=f)
            aim.keyframe_insert(data_path="location", frame=f)
        linear(cam)
        linear(camera)
        linear(aim)
    scene.render.fps = 24
    scene.frame_start = 54
    scene.frame_end = 240
    scene.camera = scene.objects["Crossing"]
    scene.frame_set(54)
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(
        filepath=str(ART / "Flight Layout.blend"), compress=True
    )


def num(seq):
    return ",".join(format(x, ".5f").rstrip("0").rstrip(".") or "0" for x in seq)


def export():
    scene = bpy.context.scene
    carrier = scene.objects["Line of fall"]
    core = scene.objects["Exposed core"]
    buffet = scene.objects["Ablation buffet"]
    lines = [
        "-- Baked from Flight Layout.blend by stage_entry.py.",
        "return {",
        "bodies={",
    ]
    for f in range(54, 241):
        scene.frame_set(f)
        m = (
            B
            @ (buffet.rotation_euler.to_matrix() @ core.rotation_euler.to_matrix())
            @ B.transposed()
        )
        lines.append(
            "{" + num([*(B @ carrier.location), *(x for row in m for x in row)]) + "},"
        )
    lines.append("}, shots={")
    for name, start, end, _, _ in SHOTS:
        cam = scene.objects[name]
        aim = scene.objects[name + " focus"]
        lines.append("{" + num([start]) + ",{")
        for f in range(start, end + 1):
            scene.frame_set(f)
            lens = math.degrees(
                2 * math.atan(cam.data.sensor_height / (2 * cam.data.lens))
            )
            lines.append(
                "{"
                + num([*(B @ cam.location), *(B @ aim.location), lens, cam["roll"]])
                + "},"
            )
        lines.append("}},")
    OUT.write_text("\n".join(lines + ["}}", ""]), encoding="utf8")


if "--export" not in sys.argv:
    stage()
export()
