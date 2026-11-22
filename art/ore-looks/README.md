# Ore looks: Ink & Facet

Mine blocks use a Storybook Ink style (flat colour, bold ink lines, hatching). Gem ores grow
low-poly 3D crystals out of one face.

- `src/shared/OreLooks.luau` holds the look data for every block: palettes, crowns, glow.
- `src/client/DrawnFaces.luau` decodes the face drawings in `src/client/OreDrawings/` and puts
  one on every open face. Stone's drawing is neutral and takes its stone grade colour.
- `src/shared/ReliefKit.luau` builds the 3D crystals, plus a 3D fallback for every face that the
  game uses when it can't show drawings.

## Redraw the faces

```bash
python3 art/ore-looks/draw_faces.py
```

This rewrites `faces/*.png`, `faces-sheet.jpg` and `src/client/OreDrawings/*.txt`. It needs
numpy and Pillow.

## Add an ore later

1. Add it to `Ores.list` before Starfall. Starfall stays the last and most valuable ore, and
   `tests/Mine.spec.luau` checks this.
2. Add its entry to `OreLooks.ores`.
3. Add its face to `FACES` in `draw_faces.py`, then run the script.

## Live game

The game decodes drawings with EditableImage, so the experience needs the in-experience image
APIs turned on in the Creator Dashboard. The Starfall opening needs the same setting. If that
isn't possible, upload the PNGs in `faces/` and list their ids in `OreLooks.drawn.uploaded`.
