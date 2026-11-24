# Second-half shot plan

**Locked:** frames 0–383 (0–16.000 s). Frame 383 is the last offshore exposure. The cut into the crater on frame 384 is the first editable picture.

**Idea.** The star broke into the rock at the bottom of its own crater. Millions of years later the mine digs that rock. A miner uncovers a trace, the cove hears about it, and the player walks in and breaks the face open. What they find is a pocket of it. The star itself is still further down, and that is the goal of the game.

| Frames | Shot | Camera | Why it is here |
| --- | --- | --- | --- |
| 384–451 | Crater | One crane over the rim and into the bowl, ending on the deposit | The crystal is in the wound it made, held by broken beds of rock. |
| 452–505 | Crater floor | Low move round the deposit. Its light dies | The light going out is the fade. |
| 506–581 | The island today | Already travelling when the picture arrives, from the offshore mark of the impact | Same place, same lens position, millions of years later. |
| 582–623 | Mine entrance | Accelerating dolly under the sign. The dark takes it at full speed | Carries us in. |
| 624–679 | Working face | The same forward line, still travelling. Contact 648 | A person at work. Pick welded in hand. |
| 680–705 | The blow | Close on the rock, contact 684 | A trace of it. |
| 706–727 | Reaction | Close, violet light rises on the miner | The find matters to someone. |
| 728–781 | Living room and reverse | Push to the TV, then the two faces it lights | The news travels. |
| 782–829 | Phone in the plaza | Over a witness. The player walks through their frame toward the mine | The player goes. |
| 830–871 | Gallery | From beside the rock, the player walks into its light | They are where the miner was. |
| 872–951 | Strike | Side on. Prompt 880, automatic swing 934, contact 944 | The player acts. A press jumps to the swing. |
| 952–969 | The break | On the rock. The cracks run and the slabs let go | Something visibly gives before anyone is introduced. |
| 970–990 | Inside | From the pocket, through the hole, at the person who made it | The lens is in what they opened. |
| 991–1061 | Glass | The same lens comes out of the rock into the portrait | The introduction. |
| 1062–1107 | Road | A pane crosses the lens. The player walks out of the mine | No teleport back to spawn. |
| 1108–1155 | Turn | It sounds behind them. Head, torso, feet, and they face the mine | Find Starfall. |
| 1156–1207 | Handoff | Blend into the gameplay camera | Play. |

**One trajectory.** Every glass slab has a single path from its entrance to its exit (`GlassReveal.luau`). The entrance decays into a drift and the exit is that drift gathering speed. `Origins.spec` fails if a slab stops or loses speed between them.

**Light.** This place renders local lights on a coarse grid with no shadow maps, so a headlamp spotlight next to a wall lights nothing. In the gallery the sun is the shaft: night blue, low, and it casts the shadow of the pick and the body on the rock. The headlamp throws its pool with a point light placed where the miner is looking.

**Tools.** Characters are Roblox R15 rigs baked in Studio with their tools welded to the hand (`bake_cast.py`). Performances are authored as keyed curves (`Acting.luau`) with planted feet and solved limbs. The player keeps their own rig, accessories and welded pick. Glass and crystal pieces are native geometry so they render before any network asset arrives.

## Workflow

- Everything in the film is owned by Rojo. Edit scripts on disk. `CoveCast.rbxm` is rebuilt with `python art/starfall/bake_cast.py`. Nothing lives only in Studio.
- Keep interior sets close to the camera position that cuts to them (see `Film.new`). Roblox lights the region around the lens, and a set hundreds of studs away opens in the dark.
- A cut to a far place takes two or three exposures to relight. Frames 384–391 hide that behind a quarter second of dark and a swell of the crater lights.
- Write each `Lighting` property once per exposure (`Daylight:draw`). Setting a value twice restarts the engine's settling.
- Frames 0–383 are approved. `vibration` in `Film.luau` keeps the literal 420 that the approved tremor used.
