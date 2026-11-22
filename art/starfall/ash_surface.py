"""Sample a whorled density field, then simplify its isosurface in Blender."""

import math
import bpy
import bmesh
import numpy as np


def polygonize(name, brushes, materials):
    step = 0.55
    axis = np.arange(-13, 14, step)
    px, py, pz = np.meshgrid(axis, axis, axis, indexing="ij")
    # Advect the field in three axes. Two scales of shear curl the surface
    # around pockets of trapped gas, right through the back of the sculpture.
    x = px + 0.69 * np.sin(0.69 * py + 0.27 * pz + 0.66 * np.sin(0.44 * px))
    y = py + 0.89 * np.sin(0.64 * pz + 0.50 * px + 0.91 * np.cos(0.48 * py))
    z = pz + 0.86 * np.cos(0.63 * px - 0.38 * py + 0.53 * np.sin(0.64 * pz))

    def field(brush):
        cx, cy, cz, w, h, d, rot = brush
        a = math.radians(-rot)
        dx, dy = x - cx, y - cy
        xx = dx * math.cos(a) - dy * math.sin(a)
        yy = dx * math.sin(a) + dy * math.cos(a)
        return (
            (
                np.sqrt(
                    (xx / (w / 2)) ** 2
                    + (yy / (h / 2)) ** 2
                    + ((z - cz) / (d / 2)) ** 2
                )
                - 1
            )
            * min(w, h, d)
            * 0.5
        )

    distance = np.full(x.shape, 20.0)
    for b in brushes["Mantle"] + brushes["Fold"]:
        v = field(b)
        d = np.abs(v - distance)
        distance = np.minimum(v, distance) - np.maximum(1.35 - d, 0) ** 2 / (4 * 1.35)
    for b in brushes["cuts"]:
        distance = np.maximum(distance, -field(b))
    distance += 0.27 * np.sin(x * 1.61 + y * 1.11 + np.sin(z * 0.97)) * np.cos(
        z * 1.39 - y * 0.84
    ) + 0.10 * np.sin(y * 3 + x * 2.0 + z * 0.9)
    points = []
    faces = []
    edge_cache = {}

    def vertex(a, b):
        key = (a, b) if a < b else (b, a)
        if key in edge_cache:
            return edge_cache[key]
        va, vb = distance[a], distance[b]
        u = float(va / (va - vb))
        p = [axis[a[i]] + (axis[b[i]] - axis[a[i]]) * u for i in range(3)]
        idx = len(points)
        points.append((p[0], -p[2], p[1]))
        edge_cache[key] = idx
        return idx

    corners = np.array(
        [
            (0, 0, 0),
            (1, 0, 0),
            (1, 1, 0),
            (0, 1, 0),
            (0, 0, 1),
            (1, 0, 1),
            (1, 1, 1),
            (0, 1, 1),
        ]
    )
    shape = np.array(distance.shape) - 1
    arrays = [
        distance[i : i + shape[0], j : j + shape[1], k : k + shape[2]] < 0
        for i, j, k in corners
    ]
    crossed = np.logical_and(
        np.logical_or.reduce(arrays), ~np.logical_and.reduce(arrays)
    )
    for idx in np.argwhere(crossed):
        pts = [tuple(p) for p in idx + corners]
        for tet in [
            (0, 1, 2, 6),
            (0, 2, 3, 6),
            (0, 3, 7, 6),
            (0, 7, 4, 6),
            (0, 4, 5, 6),
            (0, 5, 1, 6),
        ]:
            inside = [pts[i] for i in tet if distance[pts[i]] < 0]
            outside = [pts[i] for i in tet if distance[pts[i]] >= 0]
            if len(inside) == 1:
                faces.append(tuple(vertex(inside[0], b) for b in outside))
            elif len(outside) == 1:
                faces.append(tuple(vertex(outside[0], b) for b in reversed(inside)))
            elif len(inside) == 2:
                a, b = inside
                c, d = outside
                v0, v1, v2, v3 = vertex(a, c), vertex(a, d), vertex(b, d), vertex(b, c)
                faces.extend([(v0, v1, v2), (v0, v2, v3)])
    mesh = bpy.data.meshes.new(name + " · advected ash isosurface")
    mesh.from_pydata(points, [], faces)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name + " · carved density", mesh)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    simplify = obj.modifiers.new("Silhouette budget", "DECIMATE")
    simplify.ratio = min(1, 385 / max(1, len(mesh.polygons)))
    bpy.ops.object.modifier_apply(modifier=simplify.name)
    mesh = obj.data
    # Local bands follow the face normal into the grooves. They are painted
    # around the entire volume so a camera reverse reveals another drawing.
    tones = ["Mantle", "Fold", "Lip", "Flame"]
    for tone in tones:
        mesh.materials.append(materials[tone])
    for poly in mesh.polygons:
        nx, nz, ny = poly.normal
        x, z, y = poly.center
        layer = (
            -0.66 * ny
            + 0.36 * nx
            - 0.24 * nz
            + 0.22 * math.sin(0.72 * x + 0.49 * y + 0.78 * z + 0.85 * math.sin(0.8 * y))
        )
        poly.material_index = (
            0 if layer < -0.25 else 1 if layer < 0.16 else 2 if layer < 0.61 else 3
        )
    obj["isosurface"] = name
    return obj
