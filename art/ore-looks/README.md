# Ore looks: Ink & Facet

Mine blocks use a Storybook Ink style (flat colour, bold ink lines, hatching). On gem ores the
drawing's own ore pieces stand a little out of every face.

- `src/shared/OreLooks.luau` holds the look data for every block: palettes, crowns, glow.
- `src/client/DrawnFaces.luau` decodes the face drawings in `src/client/OreDrawings/` and puts
  one on every open face. Stone's drawing is neutral and takes its stone grade colour.
- Ores from Gold up glow from their ore pieces. Each has a glow image in `src/client/OreGlow/`
  (just its ore pieces and a soft halo), which `OreFaces` shows self-lit on the nearest glowing
  ores. How strongly each ore glows is its `shine` in `OreLooks`.
- `OreFaces` raises a gem's ore pieces by stacking its pieces image (the glow image without the
  halo) in thin layers just off each face, darker underneath. `Looks.raised` sets the height.
- `src/shared/ReliefKit.luau` builds a 3D fallback for every face, including gem crystals, that
  the game uses when it can't show drawings.

## Redraw the faces

```bash
python3 art/ore-looks/draw_faces.py
```

This rewrites `faces/*.png`, `faces-sheet.jpg` and `src/client/OreDrawings/*.txt`, plus the glow
images in `glow/*.png` and `src/client/OreGlow/*.txt`. It needs numpy and Pillow.

## Add an ore later

1. Add it to `Ores.list` before Starfall. Starfall stays the last and most valuable ore, and
   `tests/Mine.spec.luau` checks this.
2. Add its entry to `OreLooks.ores`.
3. Add its face to `FACES` in `draw_faces.py`, then run the script. If it should glow, give it a
   `glow` colour there and a `glow` and `shine` in `OreLooks.ores`.

## Live game

The game decodes drawings with EditableImage, so the experience needs the in-experience image
APIs turned on in the Creator Dashboard. The Starfall opening needs the same setting. If that
isn't possible, upload the PNGs in `faces/` and `glow/` and list their ids in
`OreLooks.drawn.uploaded` (a glow image goes under `"<Ore> glow"`).
