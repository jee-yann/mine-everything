# Second-half shot plan

**Locked:** frames 0–383 (0–16.000 s). Frame 383 is the last offshore exposure. The cut into the crater on frame 384 is the first editable picture.

**Idea.** The star broke into the rock at the bottom of its own crater. Millions of years later the mine digs that rock. A miner uncovers a trace, the cove hears about it, and the player walks in and breaks the face open. What they find is a pocket of it. The star itself is still further down, and that is the goal of the game.

| Frames | Shot | Camera | Why it is here |
| --- | --- | --- | --- |
| 384–451 | Crater | One crane over the rim and into the bowl, ending on the deposit | The crystal is in the wound it made, held by broken beds of rock. |
| 452–505 | Crater floor | Low move round the deposit. Its light dies | The light going out is the fade. |
| 506–571 | The island today | Already travelling when the picture arrives, from the offshore mark of the impact | Same place, same lens position, millions of years later. |
| 572–613 | Mine entrance | Accelerating dolly under the sign. The dark takes it at full speed | Carries us in. |
| 614–669 | Working face | The same forward line, still travelling. Contact 638 | A person at work. Pick welded in hand. |
| 670–695 | The blow | Close on the rock, contact 674 | A trace of it. |
| 696–717 | Reaction | Close, violet light rises on the miner | The find matters to someone. |
| 718–759 | Doorway | Low on the paving, going toward the mine as light builds inside and comes out | The cove can see it. The report has something to report. |
| 760–801 | Living room | Over both shoulders, easing toward the television | The news travels. |
| 802–843 | Two faces | From the screen. A look round, a look back, and both lean in and stay there | The reaction has an end. |
| 844–891 | Phone in the plaza | From beside the phone, round behind it. Its lens follows the player | The player goes, and people watch. |
| 892–933 | Gallery | From beside the rock, the player walks into its light | They are where the miner was. |
| 934–1013 | Strike | Side on. Prompt 942, automatic swing 996, contact 1006 | The player acts. A press jumps to the swing. |
| 1014–1031 | The break | On the rock. The cracks run and the slabs let go | Something visibly gives before anyone is introduced. |
| 1032–1052 | Inside | From the pocket, through the hole, at the person who made it | The lens is in what they opened. |
| 1053–1123 | Glass | The same lens comes out of the rock into the portrait | The introduction. |
| 1124–1169 | Road | A pane crosses the lens. The player walks out of the mine | No teleport back to spawn. |
| 1170–1217 | Turn | It sounds behind them. Head, torso, feet, and they face the mine | Find Starfall. |
| 1218–1269 | Handoff | Blend into the gameplay camera | Play. |

**One trajectory.** Every glass slab has a single path from its entrance to its exit (`GlassReveal.luau`). The entrance decays into a drift and the exit is that drift gathering speed. `Origins.spec` fails if a slab stops or loses speed between them.

**Light.** This place renders local lights on a coarse grid with no shadow maps, so a headlamp spotlight next to a wall lights nothing. In the gallery the sun is the shaft: night blue, low, and it casts the shadow of the pick and the body on the rock. The headlamp throws its pool with a point light placed where the miner is looking.

**A local light is late on a cut.** The engine queues them and applies them three to six rendered frames after the lens jumps, and sometimes many more. Sun, ambient, exposure and the grade land on the first one. Nothing that must be right on a cut may depend on a local light. The living room has none. Its wide is late sun through a window the lens never sees. The reverse is a second copy of the room, turned until the same sun comes from the screen. The doorway, the gallery and the portrait bring their lamps up from nothing. `Origins.spec` fails if the room gains a light or changes its lighting after its first exposure.

**The broadcast.** The television is an opening in the wall. Behind its glass stands a one-fifth model of the cove built from `CoveReplay`, the same copy a distant replay plays in, in the same sun, with `MouthGlow` at its own scale. It is rebuilt from that file every time, so it follows the map. A viewport has no shadows, no signs and no effects.

**The phone.** `bake_cast.py` builds it into the witness's hand. Its dark face is solid parts and its app is a `SurfaceGui`, which can be a frame late. Its picture is the street seen through it, so the lens lines up the eye, the phone and the player. The parts behind the glass are hidden in this shot.

**The prompt.** `BeaconPrompt.luau` is a function of a fractional frame and is drawn at the display's rate. The cap is down in the same draw that takes the press. Only its afterimages are late. The press sound plays from the input, outside the cue list.

**Tools.** Characters are Roblox R15 rigs baked in Studio with their tools welded to the hand (`bake_cast.py`). Performances are authored as keyed curves (`Acting.luau`) with planted feet and solved limbs. The player keeps their own rig, accessories and welded pick. Glass and crystal pieces are native geometry so they render before any network asset arrives.

## Workflow

- Everything in the film is owned by Rojo. Edit scripts on disk. `CoveCast.rbxm` is rebuilt with `python art/starfall/bake_cast.py`. Nothing lives only in Studio.
- A set that waits for its cut must be behind every lens that is open meanwhile (see `Film.new`).
- Frames 384–391 hide the relight behind a quarter second of dark and a swell of the crater lights.
- Write each `Lighting` property once per exposure (`Daylight:draw`). Setting a value twice restarts the engine's settling.
- Frames 0–383 are approved. `vibration` in `Film.luau` keeps the literal 420 that the approved tremor used.
