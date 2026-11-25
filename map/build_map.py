"""Build map/CitrineCove.rbxmx. Run `python map/build_map.py`, then build with Rojo as usual.

"The Amber Steps": honey sandstone terraces wrap the mine in a horseshoe and step down to an
open south shore. `source/CoveCore.rbxmx` holds the parts the game depends on (the mine hall,
the canal, service pads, boards, the tram and the boundary). `places.py` draws the rest.
Coordinates are the game's: +X east, -Z toward the mine, lawn at y 24.
"""

import xml.etree.ElementTree as ET

import cove
import places  # noqa: F401

cove.b.finish()
if cove.b.dropped:
    print("no room for", cove.b.dropped)
out = cove.HERE / "CitrineCove.rbxmx"
ET.indent(cove.b.doc, " ")
ET.ElementTree(cove.b.doc).write(out, encoding="utf-8")
n = sum(1 for i in cove.b.doc.iter("Item") if i.get("class") in ("Part", "WedgePart"))
print(n, "parts,", sum(1 for i in cove.b.doc.iter("Item") if i.get("class") == "PointLight"), "lights,", out.stat().st_size, "bytes")
