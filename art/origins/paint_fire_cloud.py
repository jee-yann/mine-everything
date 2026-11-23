"""Bake the cove's rising fire cloud into two local, alpha-filtered cel sheets.

Requires NumPy, Pillow and zstandard.
"""
import base64
import json
from pathlib import Path

import numpy as np
from PIL import Image
import zstandard

SIZE = (384, 320)
ROOT = Path(__file__).resolve().parents[2] / "src/client/MineOrigins"
# Center, drift, radius, ignition time. The hot stem climbs through the
# left curl first. A second, heavier bank spills over to the right.
BILLOWS = [
    (94, 115, -23, -57, 21, .09), (94, 116, 23, -65, 22, .12),
    (98, 117, 5, -88, 25, .16), (98, 115, 37, -57, 20, .23),
    (95, 115, -41, -48, 23, .18), (95, 117, -22, -65, 22, .26),
    (96, 118, 13, -61, 22, .25), (96, 119, 24, -46, 19, .31),
    (96, 125, -11, -41, 16, .17), (94, 129, 9, -27, 17, .28),
    (92, 136, -37, -14, 17, .17), (97, 135, 43, -10, 19, .26),
    (96, 139, -60, -8, 13, .34), (97, 140, 63, -5, 13, .38),
]

def cloud(t):
    # Paint a continuous density surface through the keyed billows. Each eddy
    # has its own depth, shear and ignition time. Light from the vent catches
    # the undersides while a cooler rim describes the sunward edge of the ash.
    y, x = np.mgrid[:640, :768].astype("float32") / 4
    xx = x + 1.7*np.sin(.14*y + 4*t + 1.5*np.sin(.077*x)) + .83*np.sin(.31*y-.13*x+3*t)
    yy = y + 1.5*np.cos(.12*x - 3*t + 1.2*np.cos(.13*y)) + .78*np.sin(.25*x+.17*y)
    depth = np.full(x.shape, -25.0, dtype="float32")
    for i, (cx, cy, dx, dy, r, start) in enumerate(BILLOWS):
        u = min(1, max(0, (t-start)/(1-start)))
        if not u:
            continue
        spread = 1-(1-u)**2.25
        cx += dx*spread + 8*u*u
        cy += dy*spread - 5*u
        radius = r*spread**.53 * (1.21 if i<10 else 1.17)
        vx, vy = xx-cx, yy-cy
        angle = np.arctan2(vy, vx)
        ruffled = radius*(1+.075*np.sin(4*angle+1.7*i+3*u)+.04*np.cos(7*angle-i-3*u))
        dist = np.hypot(vx*.94, vy) / np.maximum(ruffled,.01)
        bulge = 1-dist**2
        surface = radius*np.sqrt(np.maximum(0,bulge)) + np.minimum(0,bulge)*radius*2.8
        # Round the valleys between lobes without losing their inner folds.
        k = 4.6
        depth = np.maximum(depth,surface) + np.maximum(0,k-np.abs(depth-surface))**2/(4*k)
    mask = depth>0
    gy, gx = np.gradient(depth, .25)
    normal = np.sqrt(gx*gx+gy*gy+1)
    underlight = (-gy*.85-gx*.36+.16)/normal
    skylight = (gy*.78+gx*.41+.30)/normal
    heat = np.clip(1.54-1.85*t+1.18*(y/160-.55)+.12*np.sin(xx*.13+np.sin(yy*.15)),0,1)
    flow = underlight*.69 + heat*.83 + .06*np.sin(.22*xx+.17*yy+3*t)
    # The luminous fissures narrow to ribbons as the upper crown cools.
    palette = np.array([[56,48,69],[85,65,77],[128,88,88],[173,117,91],
                        [213,103,57],[247,135,48],[255,194,69],[255,234,152]],dtype=np.uint8)
    bands = np.digitize(flow,[-.13,.04,.21,.40,.63,.86,1.05])
    rgb = palette[bands].copy()
    cap = (skylight>.66) & (heat<.83) & (flow<.63)
    rgb[cap] = [140,116,126]
    rgb[cap & (skylight>.88)] = [187,151,141]
    # Soften the paint within a value band while preserving its ink edge.
    glaze = (.95+.075*skylight)[...,None]
    rgb = np.clip(rgb.astype("float32")*glaze,0,255).astype(np.uint8)
    rgba = np.empty((*mask.shape,4),dtype=np.uint8)
    rgba[:,:,:3], rgba[:,:,3] = rgb, mask*255
    return Image.fromarray(rgba).resize(SIZE,Image.Resampling.LANCZOS)


def bake():
    for page in range(2):
        sheet = Image.new("RGBA",(SIZE[0]*2,SIZE[1]*3))
        for slot in range(6):
            cel=page*6+slot
            sheet.paste(cloud(.17+.83*cel/11),(slot%2*SIZE[0],slot//2*SIZE[1]))
        packed=zstandard.ZstdCompressor(level=19).compress(sheet.tobytes())
        data={"ClassName":"StringValue","Properties":{"Value":base64.b64encode(packed).decode("ascii")}}
        (ROOT/f"FireCloud{page+1}.model.json").write_text(json.dumps(data,separators=(",",":"))+"\n")
if __name__ == "__main__":
    bake()
