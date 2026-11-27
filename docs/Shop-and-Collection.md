# Shop, crates and cosmetics

Everything in the Shop costs Robux. There are no gems, pets or Forge. The one crate, the
**Starfall Crate**, holds Mining FX, Player FX (trails and auras), tonics and gold. Effects make you a
little faster (see below); otherwise they're for looks. The server decides every result; the client
only asks.

**Playtesting:** while `AllFxForTesting` is true in `src/shared/GameConfig.luau`, every miner can wear
every Mining FX and Player FX, even in the published game (the Inventory says "Unlocked for
playtesting"). Crates still roll and grant normally, and duplicates still count against what you
really own. It is off for release; turn it on only for a playtest.

**Free purchases while playtesting:** while `FreeUnconfiguredItems` is true (same file), anything in
the Shop without a Robux ID yet is given free when bought, even in the published game, so crates,
boosts and passes can be tried. Items with an ID always go through Roblox's checkout. It is off for
release (an unpublished Studio test still gives them free). Images and descriptions for the Creator
Dashboard are in [Store-listings.md](Store-listings.md).

## Where things live

| What | File |
|---|---|
| Rarities, cosmetics, items, boosts, keyword colours | `src/shared/Collectibles.luau` |
| The crate pool, odds, rarity mix and guarantee | `src/shared/Geodes.luau` (named Geodes for save compatibility) |
| Pass and product IDs, prices, "Worth" values | `src/shared/StoreConfig.luau` |
| A miner's gold per hour (gold packs, gold rewards) | `src/shared/Earnings.luau` |
| Daily card and playtime gifts | `src/shared/FieldRewards.luau` |
| How passes and boosts combine | `src/shared/Bonuses.luau` |
| Aura and player-trail looks (server and previews) | `src/shared/CosmeticLooks.luau` |
| The collection in the save | `src/server/Collection.luau` |
| Purchases, receipts, region check, limited stock, VIP crate | `src/server/Store.luau` |
| Shop and Inventory cards | `src/client/ShopPanel.luau`, `InventoryPanel.luau`, `CollectionGrid.luau` |
| Crate reveal, try-on previews | `src/client/GeodeReveal.luau`, `TryOn.luau` |
| Ore compass over the miner's head | `src/client/OreCompass.luau` |
| Status chips | `src/client/BoostChips.luau` |
| Tests | `tests/Shop.spec.luau`, `tests/FieldRewards.spec.luau` and the play test |

## Where players find it

- **Shop** (top of the right-hand rail, **N**, or the Outfitters counter): one scrolling page with
  Featured, Crate, Passes, Boosts and Gold sections. The tabs along the top jump to a section and
  light up as the page scrolls past it. A jump puts the section's header at the top; when the whole
  section can't fit but its cards can, it scrolls on until every card shows. Positions are measured
  from the screen, so jumps land the same at any resolution.
- **Gold**: the Gold Pouch and Gold Bag top left, the Gold Chest under them, and the Gold Vault large
  on the right.
- **Featured offers** (`src/client/FeaturedOffers.luau`): animated tiles beside the right-hand rail,
  for now the Founder's Halo (with how many are left) and the Starter Pack (with its discount). Each
  opens its own offer card: art, what's inside, what it's worth bought separately and a big Robux
  button; the Starter Pack card also links to the crate odds. The
  Founder's Halo card keeps its background calm (faint, slow rays, no shine) so the live aura stands
  out, and so does its Shop card; the Starter Pack card has a header band with its name. A tile goes
  away once its offer is bought or sold out. Add an entry to `offers` to feature something else.
- **Checkout** (`src/client/Checkout.luau`): every Robux button shows a waiting screen while Roblox's
  checkout is open and while the server delivers, then a thank-you saying what arrived, with a button
  straight to it (the Inventory tab to see an effect, "Open a crate" for crates, the skill tree after a
  reset). Closing Roblox's window without buying, or the server refusing (including "one moment" for a
  purchase asked for again within a second), ends the wait. It can't get stuck: a Close button shows
  after 4 seconds, a free playtest purchase gives up after 8 seconds without an answer, and any
  purchase after two minutes (if it still goes through, the thank-you shows when it arrives). Bought
  crates go to the Inventory unopened. A purchase that didn't start from a Robux button (a pass bought
  on the website, say) gets a short notice instead.
- **Inventory** (side button or **B**): Items (crates and tonics), Mining FX, Player FX and Titles.
  Every tile is a live preview of the effect.
- **Skill tree** (**Q**): the green **Reset** button (15 Robux) gives every skill point back. The skill
  under the pointer lifts and glows gold.
- **Keys**: Inventory B, Skills Q, Index C, Awards H, Rebirth U, Profile F, Settings P, Shop N, Daily L,
  Gift G.
- **Outfitters stall** (`src/client/ShopSign.luau`): a painted FEATURED signboard stands on its roof with the featured
  offers (the Founder's Halo with a live aura and how many are left, the Starter Pack and its
  discount); tap one to open it. Once both are gone it points to the Shop.
- **Featured slot**: once the Starter Pack is bought, Instamine takes its place in the Shop.
- **Gold**: a small + on the gold coin opens the gold packs; an upgrade you can't afford says
  **Get gold ▸** and opens them too.
- **Profile**: the Friends tab carries a "+25% XP" badge, the real bonus for mining with a friend in
  the server.
- **Bottom right corner** (higher up on phones): chips for running boosts, each counting down, and
  under them a row of circles for lasting bonuses: rebirths (×gold, with XP and cutting in the tap),
  your Player FX movement speed (green), your Mining FX mining speed (orange), Double Gold, VIP,
  2× Lucky, Fast Pick and Bigger Pack. Tap a circle to see what it does.
- **Shop size**: cards are compact so that after a tab jump at least two rows of a section show
  (the All Passes Bundle and the first row of passes; both rows of boosts; all the gold packs).

Every price is a green button with the Robux icon. Where buying the same thing the expensive way
costs more, "Worth R$ …" shows above the button with the percent off. It's a value, never shown as
a former price, since nothing was sold at it. Anything holding crates (the Starfall Crate and the
Starter Pack) has its odds one tap away before buying. Rarity names and **Starfall** are coloured
wherever they appear in text.

## The player's path

1. **Day 1** of the daily card is the **Welcome Crate**: it holds the Epic Comet Trail (the game
   itself doesn't say what's inside; it's a gift). A miner who already had it gets a Starfall Crate on
   a later day 1.
2. **Free Starfall Crates** come from day 4 and day 7 of the daily card, the last playtime gift,
   every 5th level (2 every 25th), every Starfall mined, a Cave Egg, and VIP once every 20 hours.
3. More crates cost Robux: 1 for 25, 3 for 65, 10 for 199.

## Daily card and gifts

| Day | Reward |
|---|---|
| 1 | Welcome Crate |
| 2 | 2 Gold Tonics |
| 3 | 2 Haste Tonics |
| 4 | 1 Starfall Crate |
| 5 | 2 Lucky Brews |
| 6 | Pickaxe Bounty: half the price of the miner's next Power upgrade in gold (at least 100) |
| 7 | Starfall Haul: 3 Starfall Crates |

Playtime gifts at 5, 10, 20, 30, 40, 50 and 60 minutes: 3 minutes of earnings, a Haste Tonic, 6
minutes of earnings, a Gold Tonic, 10 minutes of earnings, a Lucky Brew, and a Starfall Crate. No
reward is a survey flare or a field supply.

## The Starfall Crate

Weights are stored in hundredths of a percent, so the pool adds up to exactly 100.00%.

**Rarity mix** (shown on the crate as a coloured bar and as numbers, before anything is bought):

| Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|
| 40% | 28% | 18% | 9.5% | 4% | 0.5% |

The **Odds & preview** sheet lists every item with its own chance and a live preview of each effect,
and marks what the player owns:

| Reward | Kind · rarity | Chance | With the guarantee due |
|---|---|---|---|
| Copper Spark, Ember Trail | Mining FX · Common | 9% each | — |
| Dust Trail | Player FX · Common | 8% | — |
| Dust Motes | Player FX · Common | 7% | — |
| Gold Pouch (10 min of earnings) | Item · Common | 7% | — |
| Frost Trail, Moss Trail | Mining FX · Uncommon | 5% each | — |
| Mint Trail | Player FX · Uncommon | 5% | — |
| Leaf Swirl | Player FX · Uncommon | 5% | — |
| Gold Sack (30 min of earnings) | Item · Uncommon | 3% | — |
| Gold Tonic, Haste Tonic | Item · Uncommon | 2.5% each | — |
| Verdant Trail, Sakura Trail | Mining FX · Rare | 3.5% each | — |
| Sunset Trail, Candy Trail | Player FX · Rare | 3% each | — |
| Lucky Brew | Item · Rare | 2% | — |
| Spark Ring, Frost Mist | Player FX · Rare | 1.5% each | — |
| Aurora Trail, Thunder Trail | Mining FX · Epic | 2% each | — |
| Comet Trail | Mining FX · Epic | 1.5% | — |
| Blaze Trail | Player FX · Epic | 1.5% | — |
| Ember Halo | Player FX · Epic | 1.5% | — |
| Gold Chest (an hour of earnings) | Item · Epic | 1% | — |
| Solar Flare, Inferno Trail | Mining FX · Legendary | 0.8% each | 17.78% each |
| Starlight Trail, Borealis Trail | Player FX · Legendary | 0.6% each | 13.33% each |
| Celestial Halo, Sunburst | Player FX · Legendary | 0.6% each | 13.33% each |
| Starfall Rift, Galaxy Trail | Mining FX · Mythic | 0.15% each | 3.33% each |
| Void Trail | Player FX · Mythic | 0.1% | 2.22% |
| Nebula | Player FX · Mythic | 0.1% | 2.22% |

**Guarantee:** after 9 Starfall Crates in a row with nothing Legendary or better, the 10th draws only
from the right-hand column. The counter is saved, shown on the crate ("Legendary or better
guaranteed within N crates") and resets on any Legendary or better. So the 10-crate pack always holds
at least one Legendary.

**Opening:** a reel of rewards scrolls past a marker and slows to a stop on what the server rolled,
then the reward card opens. The tiles going past are drawn from the crate's pool by its real
weights. Tap or **Skip** to jump to the reward; with menu motion off there's no reel.

**Effects give a small bonus, by rarity.** Player FX give movement speed: Common +2%, Uncommon +4%,
Rare +6%, Epic +9%, Legendary +12%, Mythic, Exclusive and Limited +16%. Mining FX give mining speed (a
cut takes less time): Common +1%, Uncommon +2%, Rare +3%, Epic +5%, Legendary +7%, Mythic, Exclusive
and Limited +10%, added to Fast Pick and the Haste Tonic. Badges are colour-coded: green for movement,
orange for mining. They show on Inventory tiles, each effect's detail, the reward card, the circles in
the bottom right, and on what's sold directly; not on the crate or its odds.

**Duplicates:** an effect already owned turns into gold: minutes of the miner's own earnings
(Common 2, Uncommon 4, Rare 8, Epic 15, Legendary 30, Mythic 60).

### Why these prices and odds

- One crate is R$25, a small impulse buy. About 1 in 22 is Legendary or better, and the guarantee
  caps the worst case at 10 crates, which is exactly the R$199 pack.
- The 3- and 10-packs are worth 25 a crate (75 and 250), so bulk reads as 13% and 20% off.
- Most commons are worth wearing (a trail or an aura), and duplicates pay gold, so a bad roll still
  gives something.

## Paid random items policy

The Starfall Crate is bought with Robux, so it is a paid random item.

- **Odds before buying:** the crate shows its rarity mix, and **Odds & preview** lists all outcomes
  with percentages that add up to 100%, the guarantee with the player's own count (and the guaranteed
  odds when it's due), and the duplicate rule.
- **Modifiers:** luck boosts change ore in the mine, not crates, and the sheet says so.
- **Region check:** the server asks `PolicyService:GetPolicyInfoForPlayerAsync` on join. Until it
  answers, and wherever `ArePaidRandomItemsRestricted` is true, crate products, the Starter Pack and
  luck products are refused, and the Shop says so. Free crates still open. Set
  `TestPaidRandomRestricted` on ReplicatedStorage to try this in Studio.

## Cosmetics

Two slots:

- **Mining FX** colour the pickaxe's swing and sparks: Copper Spark, Ember, Frost, Moss, Verdant,
  Sakura, Aurora, Comet (the Welcome Crate), Thunder, Solar Flare, Inferno, Starfall Rift, Galaxy,
  and Celestial (All Passes Bundle).
- **Player FX**, one at a time (wearing one takes the other off), listed by rarity like Mining FX: trails that follow the miner (Dust,
  Mint, Sunset, Candy, Blaze, Starlight, Borealis, Void, and Prism from the All Passes Bundle) and auras
  that glow around them (Dust Motes, Leaf Swirl, Spark Ring, Frost Mist, Ember Halo, Celestial Halo,
  Sunburst, Nebula, and Founder's Halo, limited). An older save wearing both keeps the trail.

**Effects by rarity** (`src/shared/CosmeticLooks.luau`, textures from the VFX pack in
`build/Shop-Pets-VFX.rbxlx`: its four-point star, glint, sparkle, glow, lens flare, light rays, swirl,
rings, ice shard and hot spark; the old Roblox sparkle is gone):
every trail is a streak in its full palette (Prism runs the whole rainbow); Uncommon and up shed
sparkles; Rare and up add a themed layer (embers, frost, petals, sparks or star twinkles); Epic and up
a bright core; Legendary and up a soft glow; Mythic and up a turning vortex and shockwave rings.
Auras gain motes, a glow and a vortex the same way. Colours are kept saturated so they don't wash out
to white against the sky. The four showpiece auras have their own signature layers on top: the
**Celestial Halo** is a real ring of light over the head (glowing pieces welded to the aura) with jewels
twinkling round it, a shaft of light rising from it, motes drifting down and a warm light on the
miner; the **Founder's Halo** wears a crown (points on the gold ring inside a second, rose ring), wings
of light fanned behind the shoulders, ripples spreading from the halo, rising sparks and a pulse on the
ground; **Sunburst** turns a sun of rays, a ring and a corona behind the miner (always behind them, from
any side) with lens flares and streaming sparks; **Nebula** adds a deeper cloud, a galaxy turning
behind the miner, blinking stars and the odd comet. Layers on clear textures are only half additive, so
they keep their colour in daylight; those on black textures stay additive. A miner wearing a halo has
their nameplate lifted above it.

**Previews** (`src/client/FxPreview.luau`): particles can't be drawn inside UI, so each effect is
redrawn there with the same pack textures, palette, lifetime, taper and fade: Mining FX as a small
pick chopping fast, its head sweeping a wide band (the trail runs between the two ends of the head,
so it's a surface, not a line; white-hot core for Epic and up); player trails as a miner on the left
with the ribbon streaming from their back, fluttering and fading, as if running; auras as a pulsing
glow with a turning ring and circling stars, plus the signature bits (the halos' shaft, the Founder's
Halo's rose ring and beating wings, Sunburst's turning rays, Nebula's drifting clouds); plus the rarity layers. They animate only while on screen, and
the crate reel uses still frames. There's no Try on any more.

**Reduce effects** (Settings) hides other miners' auras and trails on that player's screen.

**First person** (`src/client/FirstPersonPick.luau`): Roblox hides your own character when the camera
is in your head, and your real arm doesn't follow the camera up and down. So while you're zoomed all
the way in, a smaller copy of your pickaxe is held in the bottom right of the view wherever you look,
swings in time with your mining and carries your Mining FX. Only you see it. It also counts as
zoomed in when the mine nudges the camera, and moves closer when a block you're mining at your feet
would hide it. Your own name and title hide while you're zoomed in.

## Boosts and stacking

- **Luck** multiplies the chance of every ore rarer than 1% in a region, Starfall included:
  `luck = (2 with 2× Lucky) × (2 while 2× Luck, Lucky Brew or Server Luck runs)`. Timed luck boosts
  don't stack with each other. A common cut can turn out to hold a rare ore ("Lucky find!"), so each
  rare ore turns up exactly `luck` times as often. The Ore Index shows the player's own odds.
- **Gold:** `(2 with Double Gold) × (1 + rebirths) × (1 + VIP 20% + Gold Tonic 50%) × (2 with 2× Gold)`.
  Sales are rounded to whole gold.
- **Speed:** cut time is divided by `1 + Fast Pick 30% + Haste Tonic 20% + Mining FX`.
- **XP:** VIP gives +20% XP, on top of rebirths and the friend bonus.
- **Luck and rebirth.** Starfall is rarer than 1%, so luck makes it turn up more often, and with it
  rebirths come sooner. Starfall is a natural find in the Starfall Crater (see the README); nothing
  guarantees one.
- Timed boosts of the same kind add their time, up to 4 hours.

## Game passes

An owned pass can't be bought again.

| Pass | Robux | Benefit |
|---|---|---|
| All Passes Bundle | 1,199 (worth 1,804) | Every pass below, plus the Celestial title, the Celestial Mining FX and the Prism Trail. "Best value" |
| Bigger Pack | 79 | +50% backpack capacity |
| Double Gold | 249 | 2× sale gold (existing pass) |
| Fast Pick | 229 | +30% mining speed |
| VIP | 449 | +20% gold, +20% XP, a free Starfall Crate every 20 hours and a gold VIP tag. "Popular" |
| 2× Lucky | 349 | Doubles luck |
| Starfall Compass | 449 | Every 3 minutes underground, points to any Starfall within 2 blocks (buried too) with a star seen through the rock. "New" |

**Why the Starfall Compass's numbers.** A ping checks 81 cells (every cell within 2 blocks); every
3 minutes that is about 1,600 cells an hour, against the ~900 a miner digs, so Starfall turns up a
bit under three times as often, a little more than 2× Lucky, and a find is never certain. The first
version (3 blocks every 2 minutes, ~3,700 cells an hour) was 3-5× and too strong.
`S.compassRadius` and `S.compassEvery` in StoreConfig tune it.

The All Passes Bundle's "Worth" value is the passes on sale added up, so it stays right if a
price changes.

**Prism Trail** (the old 99 Robux pass) is retired: it isn't sold any more, but players who bought it
keep the Prism Trail effect, and the All Passes Bundle includes it. Give it its existing pass ID so owners are
recognised.

## Developer products

Each receipt is granted once: its `PurchaseId` is saved with the profile, and `PurchaseGranted` is
only returned after the save succeeds.

| Product | Robux | Worth | Reward |
|---|---|---|---|
| Founder's Halo | 249 | — | Limited aura (+16% movement speed): on sale until 100 are sold across all servers, then retired |
| Starter Pack | 49 | 128 | 2 Starfall Crates, 30 min of 2× Gold, a Haste Tonic. Once per player |
| 1 Starfall Crate | 25 | — | Goes to the Inventory |
| 3 Starfall Crates | 65 | 75 | "Popular" |
| 10 Starfall Crates | 199 | 250 | "Best value" |
| 2× Gold · 15 min | 39 | — | Timed boost |
| 2× Gold · 1 hour | 99 | 156 | Timed boost |
| 2× Server Luck · 15 min | 79 | — | Doubles everyone's chance of rare ore, announced with the buyer's name (region-checked) |
| Instamine · 10 min | 99 | — | Every block the pick can mine breaks in one quick hit (0.12 s); depth and Power limits still apply. "Popular" |
| Auto Sell · 30 min | 59 | — | The pack sells itself the moment it fills, and a pack already full when it starts sells within a second. "Popular" |
| Reset Skill Tree | 15 | — | Every skill point back to spend again |
| Gold Pouch | 15 | — | 15 minutes of the miner's earnings |
| Gold Bag | 35 | 60 | An hour of earnings |
| Gold Chest | 99 | 240 | 4 hours of earnings. "Popular" |
| Gold Vault | 349 | 1,440 | A whole day of earnings. "Best value" |

The Starter Pack's "Worth" is what its parts cost separately (2 crates for 50, plus 30 minutes of
2× Gold at the 15-minute rate, 78). The 1-hour 2× Gold is worth 4× the 15-minute price.
The only luck you can buy is Server Luck (and the 2× Lucky pass); Lucky Brews still come from crates
and rewards.
Gold packs are worth the Gold Pouch's rate (1 Robux per minute of earnings).

**Earnings formula** (gold packs, duplicate gold and the minutes-of-earnings rewards): the average
sale value per block (purity ×1.25) of the deepest region the miner has reached *and* their current
pick can mine. A Power 1 miner who rode down someone else's shaft, or one fresh from a rebirth, is
valued at what they can dig, so gold gifts can't jump them up the pick tree. That value is times the blocks an hour at the miner's Speed,
Power and skills at a relaxed pace (half the time cutting, a 30-second trip per full pack), times the
rebirth bonus. The minimum is 250 an hour. Passes and boosts are left out, so it can't be inflated.
The Shop shows the exact amount each pack pays right now.

**Limited stock** is counted in the DataStore `EndlessMining_v1_Limited`, one entry per item, and
published to every server as `Limited<key>` on ReplicatedStorage (re-read every minute). A purchase
that lands after the last one sold is still given, because it was paid for, so the wording is "on
sale until 100 are sold", never "only 100 will ever exist".

## Removed

- **Gems:** gem packs, gem prices and gem finds are gone. Old saves keep their gem count, but it
  isn't shown or used.
- **Pets** and pet styles: old pets, styles and names are dropped from saves. The ore compass that
  pets used to carry now floats over the miner's head.
- **The Forge**, its recipes and Crate Dust.
- **Stone and Crystal Crates:** any left in a save become Starfall Crates.
- **Starfall Drake and Celestial Miner** passes: replaced by the All Passes Bundle.
- **2× Luck boosts** (15 minutes and an hour): Server Luck is the luck boost on sale.
- **Sell Anywhere** (Auto Sell replaces it).
- **Try on**, replaced by live previews.
- The **STATUS** and **RARE ORE** tags.
- **Auto-Sell** pass (never sold live).

## Before publishing: IDs to configure

Every pass and product in `src/shared/StoreConfig.luau` has `id = 0` and can't be bought live yet. In
an unpublished Studio test, pressing a price grants the item without Robux.

- **Double Gold and Prism Trail already exist:** give them their current pass IDs so owners keep them
  (Prism Trail stays off sale).
- **Create the other 5 passes** (Monetization → Passes) at the listed prices, including the
  All Passes Bundle.
- **Create the 15 developer products** (Monetization → Developer Products) at the listed prices.

## Leaderboards

The physical boards show **Level** (this server, and global) and **Most Rebirths** (global, from
`EndlessMining_v1_Rebirths`). The depth record is still saved and shows in the profile.
