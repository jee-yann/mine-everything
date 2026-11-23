# Ore looks: Ink & Facet

Mine blocks use a Storybook Ink style (flat colour, bold ink lines, hatching). On every ore the
drawing's own ore pieces stand a little out of each face, and from Gold up they glow with a neon
filling.

- `src/shared/OreLooks.luau` holds the look data for every block: palettes, crowns, glow.
- `src/client/DrawnFaces.luau` decodes the face drawings in `src/client/OreDrawings/` and puts
  one on every open face. Stone's drawing is neutral and takes its stone grade colour.
- Every ore has a pieces image in `src/client/OrePieces/` (just its ore pieces on a clear
  background). `OreFaces` raises the pieces by stacking that image in thin layers just off each
  face, darker underneath. `Looks.raised` sets the height.
- Each pieces image also lists up to four glint spots (its brightest highlights). `OreFaces`
  puts a tiny sparkle on each spot of the nearest ores, tilted a little differently, that only
  lights up when it faces the camera, so glints wink as you move. `Looks.glints` tunes them.
- Ores from Gold up also have a glow image in `src/client/OreGlow/` (the pieces with a neon
  filling and a soft halo), which `OreFaces` shows self-lit on the raised pieces of the nearest
  glowing ores. How strongly each ore glows is its `shine` in `OreLooks`; `Looks.glow` holds the
  brightness and the outward light.
- `src/shared/ReliefKit.luau` builds a 3D fallback for every face, including gem crystals, that
  the game uses when it can't show drawings.

## Redraw the faces

```bash
python3 art/ore-looks/draw_faces.py
```

This rewrites `faces/*.png`, `faces-sheet.jpg` and `src/client/OreDrawings/*.txt`, plus the
pieces images (`pieces/*.png`, `src/client/OrePieces/*.txt`) and glow images (`glow/*.png`,
`src/client/OreGlow/*.txt`). It needs numpy and Pillow.

## Add an ore later

1. Add it to `Ores.list` before Starfall. Starfall stays the last and most valuable ore, and
   `tests/Mine.spec.luau` checks this.
2. Add its entry to `OreLooks.ores`.
3. Add its face to `FACES` in `draw_faces.py`, then run the script. If it should glow, give it a
   `glow` colour there and a `glow` and `shine` in `OreLooks.ores`.

## Live game

The game decodes drawings with EditableImage, so the experience needs the in-experience image
APIs turned on in the Creator Dashboard. The Starfall opening needs the same setting. If that
isn't possible, upload the PNGs in `faces/`, `pieces/` and `glow/` and list their ids in
`OreLooks.drawn.uploaded` (a pieces image goes under `"<Ore> pieces"`, a glow image under
`"<Ore> glow"`).
