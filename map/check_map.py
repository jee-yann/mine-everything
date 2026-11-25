"""Look for flicker, clipping and traps in map/CitrineCove.rbxmx. Needs NumPy.

  flicker   two faces within a hair of each other, both the first thing a ray meets
  clipping  a prop standing inside something it does not belong to
  traps     ground a miner can fall to and cannot jump or walk out of
"""

import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np

HERE = Path(__file__).parent
HAIR = 0.035
JUMP = 6.0


def prop(i, key):
    return i.find(f'./Properties/*[@name="{key}"]')


def text(i, key, default=None):
    el = prop(i, key)
    return el.text if el is not None else default


class Part:
    __slots__ = ("name", "cls", "pos", "R", "h", "alpha", "solid", "ink", "mat", "path", "lo", "hi", "shape", "obj", "top")


def load(path=HERE / "CitrineCove.rbxmx"):
    root = ET.parse(path).getroot().find("Item")
    parts = []

    def walk(node, trail):
        for c in node.findall("Item"):
            cl = c.get("class")
            label = text(c, "Name")
            if cl in ("Part", "WedgePart", "SpawnLocation"):
                p = Part()
                p.name, p.cls, p.path = label, cl, "/".join(trail)
                cf = prop(c, "CFrame")
                p.pos = np.array([float(cf.find(a).text) for a in "XYZ"])
                p.R = np.array([[float(cf.find(f"R{r}{k}").text) for k in range(3)] for r in range(3)])
                p.h = np.array([float(prop(c, "size").find(a).text) for a in "XYZ"]) / 2
                p.alpha = float(text(c, "Transparency", "0"))
                p.solid = text(c, "CanCollide", "true") == "true"
                p.ink, p.mat = text(c, "Color3uint8"), int(text(c, "Material", "256"))
                p.shape = text(c, "shape")
                p.obj = text(c, "Object")
                e = np.abs(p.R) @ p.h
                p.lo, p.hi = p.pos - e, p.pos + e
                parts.append(p)
            elif cl in ("Model", "Folder"):
                walk(c, trail + [label])
    walk(root, [])
    return parts


def spans(p, o, d):
    """Entry and exit distances of rays from origins `o` (n×3) along `d`."""
    ol, dl = (o - p.pos) @ p.R, p.R.T @ d
    near, far = np.full(len(o), -np.inf), np.full(len(o), np.inf)

    def cut(a, b):
        # keep a + b t <= 0
        nonlocal near, far
        if abs(b) < 1e-9:
            far = np.where(a > 1e-9, -np.inf, far)
        elif b > 0:
            far = np.minimum(far, -a / b)
        else:
            near = np.maximum(near, -a / b)
    for k in range(3):
        cut(ol[:, k] - p.h[k], dl[k])
        cut(-ol[:, k] - p.h[k], -dl[k])
    if p.cls == "WedgePart":
        cut(ol[:, 1] * p.h[2] - ol[:, 2] * p.h[1], dl[1] * p.h[2] - dl[2] * p.h[1])
    return near, far


def view(parts, axis, sign, step, keep):
    """First two surfaces met by a grid of rays looking along one axis."""
    u, v = [k for k in range(3) if k != axis]
    lo = np.array([-146.0, 14.0, -116.0])
    hi = np.array([146.0, 120.0, 168.0])
    nu, nv = int((hi[u] - lo[u]) / step), int((hi[v] - lo[v]) / step)
    t1, t2 = np.full((nu, nv), np.inf), np.full((nu, nv), np.inf)
    i1, i2 = np.full((nu, nv), -1), np.full((nu, nv), -1)
    d = np.zeros(3)
    d[axis] = sign
    start = lo[axis] - 400 if sign > 0 else hi[axis] + 400
    for n, p in enumerate(parts):
        if not keep(p):
            continue
        a, b = max(0, int((p.lo[u] - lo[u]) / step)), min(nu, int((p.hi[u] - lo[u]) / step) + 2)
        c, e = max(0, int((p.lo[v] - lo[v]) / step)), min(nv, int((p.hi[v] - lo[v]) / step) + 2)
        if a >= b or c >= e:
            continue
        # A tiny irrational offset keeps rays off shared edges.
        gu, gv = np.meshgrid(lo[u] + (np.arange(a, b) + 0.437) * step, lo[v] + (np.arange(c, e) + 0.583) * step, indexing="ij")
        o = np.zeros((gu.size, 3))
        o[:, u], o[:, v], o[:, axis] = gu.ravel(), gv.ravel(), start
        near, far = spans(p, o, d)
        hit = (near < far - 1e-4).reshape(gu.shape)
        t = near.reshape(gu.shape)
        A1, A2, B1, B2 = t1[a:b, c:e], t2[a:b, c:e], i1[a:b, c:e], i2[a:b, c:e]
        first = hit & (t < A1)
        second = hit & ~first & (t < A2)
        A2[first], B2[first] = A1[first], B1[first]
        A1[first], B1[first] = t[first], n
        A2[second], B2[second] = t[second], n
    return lo, u, v, t1, t2, i1, i2, start


def flicker(parts, step=0.5):
    found = defaultdict(lambda: [0, None])
    for axis, sign, label in ((1, -1, "top"), (0, 1, "west"), (0, -1, "east"), (2, 1, "north"), (2, -1, "south")):
        lo, u, v, t1, t2, i1, i2, _ = view(parts, axis, sign, step, lambda p: p.alpha < 0.9 and p.name != "Outer cliff boundary")
        with np.errstate(invalid="ignore"):
            gap = t2 - t1
        bad = np.argwhere((gap < HAIR) & (i1 >= 0) & (i2 >= 0))
        for a, b in bad:
            p, q = parts[i1[a, b]], parts[i2[a, b]]
            # Two plain faces of one colour show nothing.
            if p.ink == q.ink and p.mat == q.mat and p.mat in (272, 288):
                continue
            key = (label,) + tuple(sorted((f"{p.path.split('/')[-1]}/{p.name}", f"{q.path.split('/')[-1]}/{q.name}")))
            found[key][0] += 1
            found[key][1] = (round(lo[u] + a * step), round(lo[v] + b * step))
    return {k: v for k, v in found.items() if v[0] >= 4}


def overlap(p, q):
    """Penetration of two boxes, by separating axes. Wedges count as their boxes."""
    d = q.pos - p.pos
    best = np.inf
    axes = [p.R[:, k] for k in range(3)] + [q.R[:, k] for k in range(3)]
    for i in range(3):
        for j in range(3):
            c = np.cross(p.R[:, i], q.R[:, j])
            m = np.linalg.norm(c)
            if m > 1e-4:
                axes.append(c / m)
    for a in axes:
        depth = np.abs(p.R.T @ a) @ p.h + np.abs(q.R.T @ a) @ q.h - abs(d @ a)
        if depth <= 0:
            return 0
        best = min(best, depth)
    return best


def traps(parts, step=1.0):
    """Cells a miner can reach from spawn but never leave."""
    lo, u, v, t1, t2, i1, i2, start = view(parts, 1, -1, step, lambda p: p.solid and p.name not in ("Outer cliff boundary",))
    y = start - t1
    y[i1 < 0] = -50
    nx, nz = y.shape
    # Inside the boundary only.
    ring = [p.pos for p in parts if p.name == "Outer cliff boundary"]
    poly = [(p[0], p[2]) for p in ring]
    gx, gz = lo[0] + (np.arange(nx) + 0.437) * step, lo[2] + (np.arange(nz) + 0.583) * step
    X, Z = np.meshgrid(gx, gz, indexing="ij")
    inside = np.zeros_like(X, bool)
    for (ax, az), (bx, bz) in zip(poly, poly[1:] + poly[:1]):
        cross = ((az > Z) != (bz > Z)) & (X < (bx - ax) * (Z - az) / (bz - az + 1e-12) + ax)
        inside ^= cross
    ok = inside & (y > 18)

    def flood(seed, uphill):
        seen = np.zeros_like(ok)
        seen[seed] = True
        grow = True
        while grow:
            before = seen.sum()
            for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                s = np.roll(seen, (dx, dz), (0, 1))
                h = np.roll(y, (dx, dz), (0, 1))
                # forward: from neighbour (h) to here (y).  backward: from here to neighbour.
                step_ok = (y - h <= JUMP) if uphill else (h - y <= JUMP)
                seen |= s & step_ok & ok
            grow = seen.sum() > before
        return seen
    seed = (int((0 - lo[0]) / step), int((90 - lo[2]) / step))
    reach, back = flood(seed, True), flood(seed, False)
    stuck = reach & ~back
    # Connected pockets
    pockets, todo = [], {tuple(c) for c in np.argwhere(stuck)}
    while todo:
        stack, cells = [todo.pop()], []
        while stack:
            c = stack.pop()
            cells.append(c)
            for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (c[0] + dx, c[1] + dz)
                if n in todo:
                    todo.remove(n)
                    stack.append(n)
        rim = [y[c[0] + dx, c[1] + dz] for c in cells for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (c[0] + dx, c[1] + dz) not in cells]
        xs, zs = [gx[c[0]] for c in cells], [gz[c[1]] for c in cells]
        pockets.append(dict(n=len(cells), x=(round(min(xs), 1), round(max(xs), 1)), z=(round(min(zs), 1), round(max(zs), 1)),
                            floor=round(float(min(y[c] for c in cells)), 1), rim=round(float(min(rim)), 1)))
    return sorted(pockets, key=lambda p: -p["n"]), reach, y


PROPS = {"Wild stone", "Bush", "Flower", "Grass tuft", "Crate", "Barrel", "Ore sack", "Lamp post", "Lamp foot", "Bench seat", "Bench back", "Trunk", "Pine trunk",
         "Palm trunk", "Leaf crown", "Pine crown", "Palm leaf", "Crystal facet", "Cliff ledge", "Ledge turf", "Hanging vine", "Reed", "Fence post", "Fence rail", "Banner cloth",
         "Planter wall", "Step newel", "Falling water", "Current", "Bank stone", "Spring stone", "Whitewater"}


def clipping(parts):
    cell = defaultdict(list)
    for n, p in enumerate(parts):
        if p.alpha < 0.9 and p.name != "Outer cliff boundary":
            for x in range(int(p.lo[0] // 8), int(p.hi[0] // 8) + 1):
                for z in range(int(p.lo[2] // 8), int(p.hi[2] // 8) + 1):
                    cell[x, z].append(n)
    hits, seen = defaultdict(list), set()
    for n, p in enumerate(parts):
        if p.name not in PROPS or p.alpha > 0.9:
            continue
        for x in range(int(p.lo[0] // 8), int(p.hi[0] // 8) + 1):
            for z in range(int(p.lo[2] // 8), int(p.hi[2] // 8) + 1):
                for m in cell[x, z]:
                    q = parts[m]
                    if m == n or (n, m) in seen or (m, n) in seen or (p.obj and p.obj == q.obj):
                        continue
                    seen.add((n, m))
                    if (p.lo >= q.hi - 0.2).any() or (q.lo >= p.hi - 0.2).any():
                        continue
                    # Standing on it, or rooted a little way in, is how props meet the ground.
                    if q.hi[1] - p.lo[1] < 0.75 + 0.12 * (p.hi[1] - p.lo[1]):
                        continue
                    if overlap(p, q) > 0.35:
                        hits[p.path.split("/")[-1], p.name, q.path.split("/")[-1], q.name].append(tuple(np.round(p.pos).astype(int)))
    return hits


def objects(parts):
    """Draw the map again to learn which parts belong to one object."""
    import cove
    import places  # noqa: F401

    cove.b.finish()
    key = {tuple(round(v, 2) for v in r["at"]) + (r["label"],): r["owner"] for r in cove.b.boxes}
    for p in parts:
        p.obj = key.get(tuple(np.round(p.pos, 2)) + (p.name,))


if __name__ == "__main__":
    parts = load()
    objects(parts)
    what = sys.argv[1:] or ["flicker", "clipping", "traps"]
    print(len(parts), "parts")
    if "flicker" in what:
        f = flicker(parts)
        print("FLICKER", len(f), "pairs,", sum(v[0] for v in f.values()), "samples")
        for k, v in sorted(f.items(), key=lambda kv: -kv[1][0])[:60]:
            print("  ", v[0], k, "near", v[1])
    if "clipping" in what:
        c = clipping(parts)
        print("CLIPPING", sum(len(v) for v in c.values()))
        for k, v in sorted(c.items(), key=lambda kv: -len(kv[1]))[:60]:
            print("  ", len(v), k, v[:3])
    if "traps" in what:
        t, _, _ = traps(parts)
        print("TRAPS", len(t), "pockets")
        for p in t[:40]:
            print("  ", p)
