"""Regenerate the bundled HUD pixels after editing FieldKit.png (Pillow, zstandard).

FieldKit.png holds 256px tiles four to a row. The bundled copy halves them to 128px and repacks
them eight to a row, because Roblox's EditableImage is limited to 1024 by 1024 pixels.
"""

import base64
from pathlib import Path

from PIL import Image
import zstandard

SOURCE_COLUMNS, SOURCE_ROWS, SOURCE_TILE = 4, 10, 256
BUNDLED_COLUMNS, BUNDLED_TILE = 8, 128


def main():
    folder = Path(__file__).resolve().parent
    tiles = SOURCE_COLUMNS * SOURCE_ROWS
    rows = -(-tiles // BUNDLED_COLUMNS)
    size = (BUNDLED_COLUMNS * BUNDLED_TILE, rows * BUNDLED_TILE)
    if max(size) > 1024:
        raise ValueError(f"bundled atlas {size} exceeds the 1024px EditableImage limit")
    with Image.open(folder / "FieldKit.png") as atlas:
        if atlas.size != (SOURCE_COLUMNS * SOURCE_TILE, SOURCE_ROWS * SOURCE_TILE):
            raise ValueError("FieldKit.png must be a 1024 by 2560 atlas with 256px tiles")
        atlas = atlas.convert("RGBA")
        bundled = Image.new("RGBA", size, (0, 0, 0, 0))
        for index in range(tiles):
            sx, sy = index % SOURCE_COLUMNS * SOURCE_TILE, index // SOURCE_COLUMNS * SOURCE_TILE
            tile = atlas.crop((sx, sy, sx + SOURCE_TILE, sy + SOURCE_TILE))
            tile = tile.resize((BUNDLED_TILE, BUNDLED_TILE), Image.Resampling.LANCZOS)
            bx, by = index % BUNDLED_COLUMNS * BUNDLED_TILE, index // BUNDLED_COLUMNS * BUNDLED_TILE
            bundled.paste(tile, (bx, by))
    packed = zstandard.ZstdCompressor(level=19).compress(bundled.tobytes())
    output = folder.parents[1] / "src" / "client" / "FieldKit" / "Pixels.txt"
    output.write_bytes(base64.b64encode(packed))


if __name__ == "__main__":
    main()
