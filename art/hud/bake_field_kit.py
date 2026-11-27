"""Regenerate the bundled HUD pixels after editing FieldKit.png (Pillow, zstandard)."""

import base64
from pathlib import Path

from PIL import Image
import zstandard


def main():
    folder = Path(__file__).resolve().parent
    with Image.open(folder / "FieldKit.png") as atlas:
        if atlas.size != (1024, 1536):
            raise ValueError("FieldKit.png must be a 1024 by 1536 atlas with 256px tiles")
        preview = atlas.convert("RGBA").resize((512, 768), Image.Resampling.LANCZOS)
    packed = zstandard.ZstdCompressor(level=19).compress(preview.tobytes())
    output = folder.parents[1] / "src" / "client" / "FieldKit" / "Pixels.txt"
    output.write_bytes(base64.b64encode(packed))


if __name__ == "__main__":
    main()
