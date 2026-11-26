# Shop, geodes, pets and collection

This update adds a Shop, gem-priced geodes (the game's crates), pets with levels and stars,
cosmetics, a Forge for deterministic crafting, game passes, developer products and timed boosts.
The server decides every result. The client only asks.

## Where things live

| What | File |
|---|---|
| Rarities, pets, trails, auras, items, boosts | `src/shared/Collectibles.luau` |
| Geode pools, odds and guarantee | `src/shared/Geodes.luau` |
| Forge recipes | `src/shared/Recipes.luau` |
| Pass and product IDs, prices, rewards | `src/shared/StoreConfig.luau` |
| How passes, pets and boosts combine | `src/shared/Bonuses.luau` |
| The collection in the save (open, craft, equip, boosts) | `src/server/Collection.luau` |
| Purchases, receipts, region check, VIP chest, Gold Crate | `src/server/Store.luau` |
| Trail ribbons and auras other miners see | `src/server/Cosmetics.luau` |
| Shop card, Pets & Collection card, geode reveal | `src/client/ShopPanel.luau`, `CollectionPanel.luau`, `GeodeReveal.luau` |
| Pet models and followers | `src/client/PetModels.luau`, `PetFollowers.luau` |
| Boost timers under the region name | `src/client/BoostChips.luau` |
| Tests | `tests/Shop.spec.luau`, plus updates to the play test |

## The player's path

1. A new miner owns a **Pocket Rock** pet. It follows them once they equip it from **Pets**.
2. The first workshop upgrade gives a **Welcome Geode**. It opens by itself a few seconds later. The
   reveal says **Guaranteed: Comet Trail (Legendary)**, and its odds list shows one reward at 100%.
   **Wear** puts the trail on the pick right away. It replaces the old First Light aura. Miners who
   already had First Light get the Comet Trail directly and no second gift.
3. After that, gems come from mining (see the gem economy below), daily rewards and orders. Gems buy
   geodes. Ore, Geode Dust and gems craft rewards at the Forge.
4. Every other geode uses its normal odds.

## Geodes

Weights are stored in hundredths of a percent, so each pool adds up to exactly 100.00%. The Shop's
**Odds & details** sheet reads these same numbers before anything is bought.

### Pebble Geode: 25 gems (starter pets, food and tonics)

| Reward | Kind · rarity | Chance |
|---|---|---|
| Coal Bat | Pet · Common | 18% |
| Pet Snack ×3 | Item · Common | 20% |
| Copper Crab | Pet · Uncommon | 12% |
| Quartz Hedgehog | Pet · Uncommon | 12% |
| Gold Tonic | Item · Uncommon | 8% |
| Haste Tonic | Item · Uncommon | 8% |
| Ember Trail | Trail · Common | 8% |
| Frost Trail | Trail · Uncommon | 5% |
| Gem Slime | Pet · Rare | 4% |
| Glow Moth | Pet · Rare | 4% |
| Lucky Brew | Item · Rare | 1% |

### Crystal Geode: 75 gems (trails and auras, with rarer pets)

| Reward | Kind · rarity | Chance |
|---|---|---|
| Verdant Trail | Trail · Rare | 14% |
| Spark Ring | Aura · Rare | 14% |
| Gem Slime | Pet · Rare | 14% |
| Glow Moth | Pet · Rare | 14% |
| Geode Feast | Item · Rare | 10% |
| Lucky Brew | Item · Rare | 7% |
| Aurora Trail | Trail · Epic | 6% |
| Ember Halo | Aura · Epic | 6% |
| Cave Drake | Pet · Epic | 6% |
| Crystal Fox | Pet · Epic | 6% |
| Comet Trail | Trail · Legendary | 1.5% |
| Prism Owl | Pet · Legendary | 1.5% |

### Starfall Geode: 220 gems (Legendary and Mythic pets and effects)

| Reward | Kind · rarity | Chance | With the guarantee due |
|---|---|---|---|
| Cave Drake | Pet · Epic | 22% | — |
| Crystal Fox | Pet · Epic | 22% | — |
| Aurora Trail | Trail · Epic | 16% | — |
| Ember Halo | Aura · Epic | 16% | — |
| Magma Salamander | Pet · Legendary | 4% | 16.67% |
| Prism Owl | Pet · Legendary | 4% | 16.67% |
| Solar Flare | Trail · Legendary | 4% | 16.67% |
| Comet Trail | Trail · Legendary | 4% | 16.67% |
| Celestial Halo | Aura · Legendary | 4% | 16.67% |
| Star Wisp | Pet · Mythic | 2% | 8.33% |
| Starfall Rift | Trail · Mythic | 1.5% | 6.25% |
| Nebula | Aura · Mythic | 0.5% | 2.08% |

**Guarantee:** after 9 Starfall Geodes in a row with nothing Legendary or better, the 10th draws
only from the Legendary-and-better rewards in the right-hand column. The counter is saved, shown on
the geode ("Legendary+ guaranteed in N") and resets on any Legendary or better. When the guarantee
is due, the odds sheet shows the right-hand column.

### Duplicates

- **Pet you already own:** it gains a star, up to ★3. Each star adds +20% to its bonus. After ★3, a
  duplicate becomes Geode Dust.
- **Trail or aura you already own:** it becomes Geode Dust.
- **Dust per duplicate:** Common 3, Uncommon 8, Rare 20, Epic 50, Legendary 150, Mythic 500.

Geode Dust only crafts at the Forge. It is not a second currency to buy.

### Free geodes

Pebble, Crystal and Starfall geodes also come free as items, opened from **Pets → Items** or the
geode's own button:

- a **Pebble Geode** at every 5th level,
- a **Crystal Geode** at every 25th level (instead of the Pebble),
- a **Starfall Geode** for every Starfall mined.

Free geodes are earned rewards, so they open everywhere, including regions that restrict paid random
items.

## Roblox paid random items policy

Gems can be bought with Robux, so a geode bought with gems is a paid random item.

- **Odds before buying:** every geode has an **Odds & details** button showing all outcomes with
  numeric percentages that add up to 100%. The sheet also explains the guarantee and the duplicate
  rules, and shows the guaranteed odds live when the guarantee is due.
- **Probability modifiers:** luck boosts affect ore in the mine, not geodes (the sheet says so). The
  geode guarantee is explained with numbers, and the miner's own counter is shown.
- **Region check:** on join, the server asks `PolicyService:GetPolicyInfoForPlayerAsync`, with three
  retries. Until Roblox answers, and wherever `ArePaidRandomItemsRestricted` is true, the server
  refuses paid geode opens and luck products. The Shop shows "Unavailable here" and points to the
  Forge, which crafts any reward directly. Free geodes, such as the Welcome Geode, still open.
- **Testing the restricted path in Studio:** set the `TestPaidRandomRestricted` attribute on
  ReplicatedStorage to `true` before joining.

## Pets

Up to 3 pets follow at once. Each helps one part of the loop. Bonuses grow +3% of base per level
(levels 1–30) and +20% per star. Each bonus type's total across equipped pets is capped.

| Pet | Rarity | Bonus at Lv 1 | Motion |
|---|---|---|---|
| Pocket Rock | Common (everyone owns one) | +3% gold | hops |
| Coal Bat | Common | +5% XP | flies |
| Copper Crab | Uncommon | +6% gold | scuttles |
| Quartz Hedgehog | Uncommon | +4% speed | hops |
| Gem Slime | Rare | +35% gem find | bounces |
| Glow Moth | Rare | +12% XP | flies |
| Cave Drake | Epic | +8% luck | flies (also from drake eggs) |
| Crystal Fox | Epic | +8% speed | trots |
| Magma Salamander | Legendary | +16% gold | crawls |
| Prism Owl | Legendary | +14% luck | flies |
| Star Wisp | Mythic | +20% luck | floats and glows |
| Starfall Drake | Exclusive (pass) | +5% luck | flies with gold wings |

- **Caps on totals:** gold +80%, speed +35%, luck +60%, XP +80%, gem find +150%.
- **Pet XP:** equipped pets gain the same XP their miner earns from each cut (at least 1).
- **Pet food:** Pet Snack gives +150 XP and Geode Feast +900 XP, to every equipped pet. A level
  needs `40 × level^1.6` XP.
- **Lead pet:** the first equipped pet wears the pet's name. The ore compass supply still works
  through it.
- **Models:** pets are built from parts in the cove's chunky style, so there are no meshes to upload.
  All pets move with a single `BulkMoveTo` each frame. Pets more than 125 studs from the camera
  aren't drawn.

## Cosmetics

Cosmetics never change gameplay.

**Trails** colour the pickaxe's swing arc and sparks. Legendary and better also leave a ribbon
behind the miner as they walk.

| Trail | Rarity |
|---|---|
| Ember | Common |
| Frost | Uncommon |
| Verdant | Rare |
| Aurora | Epic |
| Comet | Legendary (the Welcome Geode reward) |
| Solar Flare | Legendary |
| Starfall Rift | Mythic |
| Prism | Exclusive (Prism Trail pass) |
| Celestial | Exclusive (Celestial Miner pass) |

**Auras** can be worn on the miner, or on each of their pets through a separate pet aura slot:
Spark Ring (Rare), Ember Halo (Epic), Celestial Halo (Legendary) and Nebula (Mythic).

**Reduce effects** (Settings) hides other miners' auras, trail ribbons and every pet but their lead
pet, on that player's screen only.

## Forge and the gem economy

The Forge crafts a chosen reward for sure, from ore in the pack, Geode Dust and gems:

| Group | Recipe |
|---|---|
| Pet food | Snack ×2 (6 Coal, 2 Copper) |
| Pet food | Feast (4 Iron, 2 Quartz, 6 gems) |
| Tonics | Gold Tonic (2 Gold, 4 Coal, 4 gems) |
| Tonics | Haste Tonic (4 Copper, 1 Quartz, 4 gems) |
| Tonics | Lucky Brew (2 Garnet, 2 Quartz, 12 gems) |
| Pets | Copper Crab (20 Copper, 40 dust) |
| Pets | Crystal Fox (16 Quartz, 3 Diamond, 350 dust, 40 gems) |
| Pets | Prism Owl (6 Opal, 6 Diamond, 1,100 dust, 120 gems) |
| Cosmetics | Frost Trail (4 Quartz, 30 dust) |
| Cosmetics | Aurora Trail (3 Opal, 1 Emerald, 450 dust, 60 gems) |
| Cosmetics | Celestial Halo (4 Platinum, 4 Diamond, 1,300 dust, 150 gems) |

Crafting a pet you already own adds a star.

**Ways to earn gems without paying:**
- Daily card, playtime gifts and daily order (as before).
- +3 gems per level gained.
- +5 gems per new ore discovered.
- A 3% chance per ore cut to find a gem. Gem Slime raises it.

A steady free player earns roughly one Pebble Geode an hour, a Crystal Geode every few hours and a
Starfall Geode in about a day of play. Gem sinks are geodes, Forge recipes and field supplies.

## Boosts and stacking

- **Luck** multiplies the chance of every ore rarer than 1% in a region, Starfall included:
  `luck = (1 + pets) × (2 with 2× Lucky) × strongest of {2× Luck, 3× Luck, Lucky Brew, Server Luck}`.
  - Timed luck boosts don't multiply each other: the strongest one counts. The total is capped at 12×.
  - In the mine, a cut that came up common can turn out to hold one of the region's rare ores, so each
    rare ore turns up exactly `luck` times as often (proved in `Shop.spec`). The miner sees
    "Lucky find! Diamond inside the Stone".
  - The Ore Index's Odds tab shows the miner's own luck-adjusted odds in green, still adding up to
    100%.
- **Gold:** `(2 with Double Gold) × (1 + rebirths) × (1 + pets + VIP 10% + Gold Tonic 50%) × (2 with 2× Gold)`.
- **Speed:** cut time is divided by `1 + pets + Fast Pick 15% + Haste Tonic 20%`.
- **Timed boosts** of the same kind add their time together, up to 4 hours from now. They tick in real
  time and count down in chips under the region name.

## Game passes

Prices are as briefed and set in `StoreConfig`. Ownership is checked with
`UserOwnsGamePassAsync` on join and granted on `PromptGamePassPurchaseFinished`. An owned pass can't
be bought again: the button shows Owned, or Included under Celestial Miner.

| Pass | R$ | Benefit |
|---|---|---|
| Bigger Pack | 49 | +50% backpack capacity |
| Prism Trail | 99 | Prism Trail cosmetic (existing pass) |
| Auto-Sell | 149 | Sells the pack the moment it fills |
| Double Gold | 199 | 2× sale gold (existing pass) |
| Fast Pick | 199 | +15% mining speed |
| VIP | 249 | Gold VIP name tag, +10% gold, 15-gem chest every 20 hours (server cooldown, saved) |
| 2× Lucky | 299 | Doubles luck (see stacking) |
| Starfall Drake | 799 | Exclusive pet: +5% luck, levels like any pet |
| Celestial Miner | 999 | Double Gold, 2× Lucky, Auto-Sell, VIP, the Celestial title on the nameplate and the Celestial Trail |

## Developer products

Receipts are idempotent:
- Each `PurchaseId` is saved with the profile (the last 500 are kept).
- The reward is given once.
- `PurchaseGranted` is returned only after the save succeeds.

If the save fails, Roblox retries the receipt, and the stored ID stops it paying twice in that
session.

| Product | R$ | Reward |
|---|---|---|
| Sell Anywhere | 15 | Sells the whole pack where the miner stands |
| Gem Pouch | 25 | 25 gems |
| Starter Pack | 49 | 60 gems, 3 survey flares, 30 min of 2× gold. Once per player, enforced and saved by the server, hidden after purchase |
| 2× Gold · 15 min | 39 | Timed boost |
| 2× Luck · 15 min | 59 | Timed boost (region-checked) |
| Gem Bag | 99 | 120 gems |
| Star Compass · 10 min | 99 | Beam to the nearest real Starfall within 40 blocks. The server searches the crater's actual cells |
| Gold Crate | 149 | About an hour of the miner's own earnings (formula below) |
| Gem Chest | 199 | 300 gems |
| 3× Luck · 30 min | 199 | Timed boost (region-checked) |
| Server Luck · 15 min | 349 | 2× luck for everyone in the server, announced in chat and on screen with the buyer's name, with a shared timer chip (region-checked) |
| Gem Vault | 499 | 900 gems |
| Gem Hoard | 999 | 2,000 gems |
| Gem Mountain | 1,999 | 4,500 gems |

**Gold Crate formula:** the deepest region reached, its average sale value per block (purity
×1.25), and blocks per hour at the miner's Speed, Power and skills at a relaxed pace (half the time
cutting, a 30-second trip per full pack), times the rebirth multiplier. The minimum is 250. Passes,
pets and boosts are left out, so it can't be inflated. It is about 1,160 gold for a new miner (about 20,800 for a well-upgraded one at depth 200) and
grows with progress.

### Gem pack bonus audit

Measured against the Gem Pouch's 1 gem per Robux. The Shop shows these labels. Prices and gem
amounts are unchanged.

| Pack | Gems / R$ | Bonus |
|---|---|---|
| Gem Pouch | 1.00 | — |
| Gem Bag | 1.21 | +21% |
| Gem Chest | 1.51 | +51% |
| Gem Vault | 1.80 | +80% |
| Gem Hoard | 2.00 | +100% |
| Gem Mountain | 2.25 | +125% |

## Before publishing: IDs to configure

Every pass and product in `src/shared/StoreConfig.luau` has `id = 0` and can't be bought live. The
Shop shows "Coming soon". In an unpublished Studio test, "Try free (Studio)" grants it without Robux.

- **Double Gold and Prism Trail already exist:** put their current pass IDs in, so existing owners
  keep them.
- **Create the other 7 passes** on the Creator Dashboard (Monetization → Passes) at the listed
  prices: Bigger Pack, Auto-Sell, Fast Pick, VIP, 2× Lucky, Starfall Drake, Celestial Miner.
- **Create the 14 developer products** (Monetization → Developer Products) at the listed prices and
  put each ID in.
- **Optional:** upload `art/hud/FieldKit.png` and set the `ImageId` attribute it mentions. The
  bundled pixels work without it.

## Leaderboards

- **The physical boards** now show **Level** (this server, and global) and **Most Rebirths**
  (global, from the new ordered store `EndlessMining_v1_Rebirths`). The global board alternates
  between the two every 20 seconds.
- **Podiums and scroll lists** follow the same two rankings.
- **Depth:** the depth record is still saved and indexed, and shows in the profile ("Deepest mined").

## Balancing decisions

- **Geodes are cosmetics-and-convenience first:** the strongest pet bonuses are capped per type, so
  stacking Mythic pets can't run away (luck +60%, gold +80%).
- **Every paid random reward can also be crafted** at the Forge (except passes and Mythics), which
  is the deterministic path for players who don't want chance, and in restricted regions.
- **The Starfall guarantee** caps the worst case at 10 geodes (2,200 gems) for a Legendary.
- **Luck is capped at 12×**, and personal timed luck boosts take the strongest rather than
  multiplying, so 2× Lucky + 3× Luck + pets peaks around 9.6×.
- **Gem pack quantities were left exactly as briefed.** The bonus labels now state the true
  percentages.
