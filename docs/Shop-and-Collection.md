# Shop, crates, pets and cosmetics

The Shop sells game passes, developer products, timed boosts and gems. Gems open crates. Crates
hold pets and cosmetics, which are only for looks. The Forge crafts any of them for certain. The
server decides every result; the client only asks.

## Where things live

| What | File |
|---|---|
| Rarities, pets, cosmetics, items, boosts | `src/shared/Collectibles.luau` |
| Crate pools, odds and guarantee | `src/shared/Geodes.luau` (named Geodes for save compatibility) |
| Forge recipes | `src/shared/Recipes.luau` |
| Pass and product IDs, prices, rewards | `src/shared/StoreConfig.luau` |
| How passes and boosts combine | `src/shared/Bonuses.luau` |
| Aura and player-trail looks (server and previews) | `src/shared/CosmeticLooks.luau` |
| The collection in the save | `src/server/Collection.luau` |
| Purchases, receipts, region check, limited stock, VIP chest | `src/server/Store.luau` |
| Shop, Inventory and Pets cards | `src/client/ShopPanel.luau`, `InventoryPanel.luau`, `PetsPanel.luau`, `CollectionGrid.luau` |
| Crate reveal, try-on previews | `src/client/GeodeReveal.luau`, `TryOn.luau` |
| Pet models, pet styles and followers | `src/client/PetModels.luau`, `PetFollowers.luau` |
| Status chips | `src/client/BoostChips.luau` |
| Tests | `tests/Shop.spec.luau` and the play test |

## Where players find it

- **Shop** (side button or **N**, or the Outfitters counter): Featured, Crates, Passes, Boosts and
  Gems. The gem purse in the header, and the gem counter above the gold in the HUD, both open the
  gem packs.
- **Inventory** (side button or **B**): Items (crates, tonics and field supplies), Mining trails,
  Player effects (player trails and auras), the Forge and Titles.
- **Pets** (side button or **T**): Pets and Pet Styles.
- **Statuses**: running boosts show as chips in the bottom right corner (higher up on phones), each
  with a countdown. Tapping one opens the boosts.

## The player's path

1. Every miner owns a **Pocket Rock** pet and can equip it from Pets.
2. The first workshop upgrade gives a **Welcome Crate**. It opens by itself a few seconds later and
   says **Guaranteed: Comet Trail (Legendary)**. Its odds list shows that one reward at 100%.
3. Gems come from mining (see below), daily rewards and orders. **Free crates** come every 5th level
   (a Stone Crate), every 25th level (a Crystal Crate instead) and with every Starfall mined (a
   Starfall Crate).
4. When a crate costs more gems than the miner has, its button reads "Get N more gems" and takes
   them to the gem packs, with the pack that covers it glowing.

## Crates

Weights are stored in hundredths of a percent, so each pool adds up to exactly 100.00%. The Shop's
**Odds & preview** sheet shows these numbers before anything is bought, marks what the player
already owns, and has **Try on** for cosmetics and **View** for pets.

### Stone Crate: 25 gems

| Reward | Kind · rarity | Chance |
|---|---|---|
| Coal Bat, Tunnel Mole, Moss Frog | Pet · Common | 12% each |
| Ember Trail | Mining trail · Common | 9% |
| Copper Crab, Quartz Hedgehog, Pebble Turtle, Frost Penguin | Pet · Uncommon | 7% each |
| Gold Tonic, Haste Tonic | Item · Uncommon | 6% each |
| Mint Ribbon | Player trail · Uncommon | 5% |
| Sparkle Trail | Pet style · Uncommon | 5% |
| Gem Slime, Opal Bunny | Pet · Rare | 2% each |
| Lucky Brew | Item · Rare | 1% |

### Crystal Crate: 75 gems

| Reward | Kind · rarity | Chance |
|---|---|---|
| Gem Slime, Glow Moth, Opal Bunny, Mini Golem | Pet · Rare | 10% each |
| Frost Trail | Mining trail · Uncommon | 8% |
| Verdant Trail | Mining trail · Rare | 8% |
| Sunset Ribbon | Player trail · Rare | 6% |
| Fairy Wings | Pet style · Rare | 6% |
| Spark Ring | Player aura · Rare | 6% |
| Lucky Brew | Item · Rare | 5% |
| Cave Drake, Crystal Fox, Glow Jelly | Pet · Epic | 3.5% each |
| Aurora Trail | Mining trail · Epic | 3% |
| Ember Halo | Player aura · Epic | 2.5% |
| Pet Flames | Pet style · Epic | 2% |
| Prism Owl, Aurora Stag | Pet · Legendary | 1% each |
| Comet Trail | Mining trail · Legendary | 1% |

### Starfall Crate: 220 gems

| Reward | Kind · rarity | Chance | With the guarantee due |
|---|---|---|---|
| Cave Drake, Crystal Fox, Glow Jelly | Pet · Epic | 16% each | — |
| Aurora Trail | Mining trail · Epic | 10% | — |
| Ember Halo | Player aura · Epic | 10% | — |
| Pet Flames | Pet style · Epic | 8% | — |
| Magma Salamander, Prism Owl, Aurora Stag | Pet · Legendary | 3% each | 12.5% each |
| Solar Flare, Comet Trail | Mining trail · Legendary | 2.5% each | 10.42% each |
| Celestial Halo | Player aura · Legendary | 2.5% | 10.42% |
| Starlight Ribbon | Player trail · Legendary | 2.5% | 10.42% |
| Golden Crown, Star Halo | Pet style · Legendary | 2% each | 8.33% each |
| Star Wisp, Ember Phoenix | Pet · Mythic | 0.3% each | 1.25% each |
| Starfall Rift | Mining trail · Mythic | 0.2% | 0.83% |
| Void Ribbon | Player trail · Mythic | 0.1% | 0.42% |
| Nebula | Player aura · Mythic | 0.05% | 0.21% |
| Nebula Cloak | Pet style · Mythic | 0.05% | 0.21% |

**Guarantee:** after 9 Starfall Crates in a row with nothing Legendary or better, the 10th draws only
from the right-hand column. The counter is saved, shown on the crate and resets on any Legendary or
better.

**Duplicates:** a pet or cosmetic already owned becomes Crate Dust (Common 3, Uncommon 8, Rare 20,
Epic 50, Legendary 150, Mythic 500). Dust only crafts at the Forge.

## Paid random items policy

Gems can be bought with Robux, so a crate bought with gems is a paid random item.

- **Odds before buying:** every crate has an **Odds & preview** button listing all outcomes with
  percentages that add up to 100%, the guarantee with the player's own count (and the guaranteed odds
  when it's due), and the duplicate rules.
- **Modifiers:** luck boosts change ore in the mine, not crates, and the sheet says so.
- **Region check:** the server asks `PolicyService:GetPolicyInfoForPlayerAsync` on join. Until it
  answers, and wherever `ArePaidRandomItemsRestricted` is true, paid crates and luck products are
  refused, and the Shop says so and points to the Forge. Free crates still open. Set
  `TestPaidRandomRestricted` on ReplicatedStorage to try this in Studio.

## Pets

Pets are only for looks. One follows at a time; equipping another swaps it. Each species moves its
own way (hop, fly, scuttle, bounce, trot, crawl, float) and wears its pet style.

| Rarity | Pets |
|---|---|
| Common | Pocket Rock (everyone's first), Coal Bat, Tunnel Mole, Moss Frog |
| Uncommon | Copper Crab, Quartz Hedgehog, Pebble Turtle, Frost Penguin |
| Rare | Gem Slime, Glow Moth, Opal Bunny, Mini Golem |
| Epic | Cave Drake (also from drake eggs), Crystal Fox, Glow Jelly |
| Legendary | Magma Salamander, Prism Owl, Aurora Stag |
| Mythic | Star Wisp, Ember Phoenix |
| Exclusive | Starfall Drake (pass) |
| Limited | Founder's Griffin (the first 1,000 buyers) |

**Pet styles** are worn by the pet: Sparkle Trail, Fairy Wings, Pet Flames, Golden Crown, Star Halo
and Nebula Cloak.

All pet models are built from parts, so there are no meshes to upload. Pets far from the camera
aren't drawn, and every pet moves in one `BulkMoveTo` a frame.

## Cosmetics

Each kind has its own slot:

- **Mining trails** colour the pickaxe's swing and sparks: Ember, Frost, Verdant, Aurora, Comet
  (the Welcome Crate reward), Solar Flare, Starfall Rift, and Celestial (Celestial Miner pass).
- **Player trails** are a ribbon as the miner walks: Mint, Sunset, Starlight, Void, and Prism (the
  Prism Trail pass, which was always a walking ribbon).
- **Player auras** glow around the miner: Spark Ring, Frost Mist, Ember Halo, Celestial Halo, Nebula.
- **Pet styles**, above.

**Try on** shows any cosmetic on the player's own miner or pet for 8 seconds, owned or not, from the
Inventory, Pets and the crate odds sheet. A mining trail is shown as a spark circling the miner.
Only the player sees it.

**Reduce effects** (Settings) hides other miners' auras, ribbons and pet styles on that player's
screen.

## Forge

| Group | Recipe |
|---|---|
| Tonics | Gold Tonic (2 Gold, 4 Coal, 4 gems), Haste Tonic (4 Copper, 1 Quartz, 4 gems), Lucky Brew (2 Garnet, 2 Quartz, 12 gems) |
| Pets | Copper Crab (20 Copper, 40 dust), Mini Golem (20 Iron, 6 Quartz, 120 dust), Crystal Fox (16 Quartz, 3 Diamond, 350 dust, 40 gems), Prism Owl (6 Opal, 6 Diamond, 1,100 dust, 120 gems) |
| Mining trails | Frost (4 Quartz, 30 dust), Aurora (3 Opal, 1 Emerald, 450 dust, 60 gems) |
| Player effects | Sunset Ribbon (3 Garnet, 3 Gold, 120 dust), Celestial Halo (4 Platinum, 4 Diamond, 1,300 dust, 150 gems) |
| Pet styles | Fairy Wings (6 Quartz, 3 Silver, 120 dust), Golden Crown (12 Gold, 2 Diamond, 900 dust, 100 gems) |

## Gems

Without paying, gems come from:
- the daily card, playtime gifts and the daily order;
- +3 per level gained and +5 per new ore discovered;
- a 3% chance per ore cut to find one.

In an unpublished Studio session every miner starts with 1,000 gems for trying the Shop (not in
automated tests). The game's owner also gets 1,000 once in the live game.

## Boosts and stacking

- **Luck** multiplies the chance of every ore rarer than 1% in a region, Starfall included:
  `luck = (2 with 2× Lucky) × (2 while 2× Luck, Lucky Brew or Server Luck runs)`. Timed luck boosts
  don't stack with each other. A common cut can turn out to hold a rare ore ("Lucky find!"), so each
  rare ore turns up exactly `luck` times as often. The Ore Index shows the player's own odds.
- **Gold:** `(2 with Double Gold) × (1 + rebirths) × (1 + VIP 10% + Gold Tonic 50%) × (2 with 2× Gold)`.
  Sales are rounded to whole gold.
- **Speed:** cut time is divided by `1 + Fast Pick 15% + Haste Tonic 20%`.
- Timed boosts of the same kind add their time, up to 4 hours.

## Game passes

The Shop always shows the Robux price. An owned pass can't be bought again.

| Pass | R$ | Benefit |
|---|---|---|
| Bigger Pack | 49 | +50% backpack capacity |
| Prism Trail | 99 | Prism Ribbon player trail (existing pass) |
| Auto-Sell | 149 | Sells the pack the moment it fills |
| Double Gold | 199 | 2× sale gold (existing pass) |
| Fast Pick | 199 | +15% mining speed |
| VIP | 249 | Gold VIP tag, +10% gold, 15-gem chest every 20 hours |
| 2× Lucky | 299 | Doubles luck |
| Starfall Drake | 799 | Exclusive pet with glowing gold wings |
| Celestial Miner | 999 | Double Gold, 2× Lucky, Auto-Sell, VIP, the Celestial title and Celestial mining trail |

## Developer products

Each receipt is granted once: its `PurchaseId` is saved with the profile, and `PurchaseGranted` is
only returned after the save succeeds.

| Product | R$ | Reward |
|---|---|---|
| Sell Anywhere | 15 | Sells the whole pack where the miner stands |
| Gem Pouch | 25 | 25 gems |
| Starter Pack | 49 | 60 gems, 3 survey flares, 30 min of 2× gold. Once per player, hidden after |
| 2× Gold · 15 min | 39 | Timed boost |
| 2× Luck · 15 min | 59 | Timed boost (region-checked) |
| Gem Bag | 99 | 120 gems |
| Gold Bundle | 149 | About an hour of the miner's own gold. The Shop shows the exact amount right now |
| Gem Chest | 199 | 300 gems ("Most popular") |
| Server Luck · 15 min | 349 | 2× luck for everyone in the server, announced with the buyer's name (region-checked) |
| Gem Vault | 499 | 900 gems |
| Gem Hoard | 999 | 2,000 gems |
| Gem Mountain | 1,999 | 4,500 gems ("Best value") |
| Founder's Griffin | 399 | Limited pet: the first 1,000 buyers across all servers, then off sale for good |

3× Luck and the Star Compass were removed.

**Gold Bundle formula:** the deepest region's average sale value per block (purity ×1.25), times the
blocks an hour at the miner's Speed, Power and skills at a relaxed pace (half the time cutting, a
30-second trip per full pack), times the rebirth bonus. The minimum is 250. Passes and boosts are left
out, so it can't be inflated.

**Limited stock** is counted in the DataStore `EndlessMining_v1_Limited`, one entry per item, and
published to every server as `Limited<key>` on ReplicatedStorage (re-read every minute). A purchase
that lands after the last one sold is still given, because it was paid for.

### Gem packs

Each pack shows its gems, the price the same gems would cost at the Gem Pouch's rate (1 gem per
Robux) struck through, and its real price.

| Pack | Gems | Was | Price | Bonus |
|---|---|---|---|---|
| Gem Pouch | 25 | — | R$ 25 | — |
| Gem Bag | 120 | R$ 120 | R$ 99 | +21% |
| Gem Chest | 300 | R$ 300 | R$ 199 | +51% |
| Gem Vault | 900 | R$ 900 | R$ 499 | +80% |
| Gem Hoard | 2,000 | R$ 2,000 | R$ 999 | +100% |
| Gem Mountain | 4,500 | R$ 4,500 | R$ 1,999 | +125% |

## Before publishing: IDs to configure

Every pass and product in `src/shared/StoreConfig.luau` has `id = 0` and can't be bought live yet. In
an unpublished Studio test, pressing a price grants the item without Robux.

- **Double Gold and Prism Trail already exist:** give them their current pass IDs so owners keep them.
- **Create the other 7 passes** (Monetization → Passes) at the listed prices.
- **Create the 13 developer products** (Monetization → Developer Products) at the listed prices,
  including Founder's Griffin.

## Leaderboards

The physical boards show **Level** (this server, and global) and **Most Rebirths** (global, from
`EndlessMining_v1_Rebirths`). The depth record is still saved and shows in the profile.
