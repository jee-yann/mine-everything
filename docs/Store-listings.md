# Store listings

What to put on the Creator Dashboard (Monetization → Passes, and Monetization → Developer Products)
for every item in `src/shared/StoreConfig.luau`. Images are 512 × 512 PNGs in `art/listings/`, drawn
from the Shop's own art by `art/listings/render_listings.py` (rerun it after changing the Field Kit).

After creating each one, copy its ID into the matching `key` in `StoreConfig.luau` (`id = 0` today).
**Set each Robux price to exactly the one below:** the Shop shows the `price` from `StoreConfig`, but
Roblox charges what the dashboard says, so the two must match.

**Double Gold** and **Prism Trail** already exist as passes. Don't make new ones: update the existing
Double Gold pass's image, description and price, and put both existing IDs in `StoreConfig` so their
owners keep them. Prism Trail is retired (off sale); owners keep it and the bundle includes it.

## Game passes

| Key | Name | Robux | Image |
|---|---|---|---|
| `Everything` | All Passes Bundle | 1199 | `Everything.png` |
| `BiggerPack` | Bigger Pack | 79 | `BiggerPack.png` |
| `DoubleGold` | Double Gold | 249 | `DoubleGold.png` |
| `FastPick` | Fast Pick | 229 | `FastPick.png` |
| `VIP` | VIP | 449 | `VIP.png` |
| `Lucky` | 2× Lucky | 349 | `Lucky.png` |
| `StarfallCompass` | Starfall Compass | 449 | `StarfallCompass.png` |

**All Passes Bundle**
> Every game pass in one: Double Gold, Fast Pick, Bigger Pack, VIP, 2× Lucky and the Starfall Compass, plus the Celestial title, the Celestial Mining FX and the Prism Ribbon. Less than buying the passes one by one.

**Bigger Pack**
> +50% backpack capacity. Carry more ore on every trip before you head up to sell.

**Double Gold**
> 2× gold on every sale, for good. Stacks with your rebirth bonuses.

**Fast Pick**
> +30% mining speed on every block.

**VIP**
> +20% gold and +20% XP, a free Starfall Crate every 20 hours, and a gold VIP tag over your name.

**2× Lucky**
> Doubles the chance of every ore rarer than 1%, Starfall included.

**Starfall Compass**
> Every 3 minutes underground, the compass checks the rock within 2 blocks of you and points to any Starfall there, even if it's buried.

## Developer products

| Key | Name | Robux | Image |
|---|---|---|---|
| `StarterPack` | Starter Pack | 49 | `StarterPack.png` |
| `FounderHalo` | Founder's Halo | 249 | `FounderHalo.png` |
| `Crate1` | 1 Starfall Crate | 25 | `Crate1.png` |
| `Crate3` | 3 Starfall Crates | 65 | `Crate3.png` |
| `Crate10` | 10 Starfall Crates | 199 | `Crate10.png` |
| `Gold2x15` | 2× Gold · 15 min | 39 | `Gold2x15.png` |
| `Gold2x60` | 2× Gold · 1 hour | 99 | `Gold2x60.png` |
| `ServerLuck` | 2× Server Luck · 15 min | 79 | `ServerLuck.png` |
| `Instamine10` | Instamine · 10 min | 99 | `Instamine10.png` |
| `AutoSell30` | Auto Sell · 30 min | 59 | `AutoSell30.png` |
| `Fling` | Fling | 3 | `Fling.png` |
| `ResetSkills` | Reset Skill Tree | 15 | `ResetSkills.png` |
| `GoldPouch` | Gold Pouch | 15 | `GoldPouch.png` |
| `GoldBag` | Gold Bag | 35 | `GoldBag.png` |
| `GoldChest` | Gold Chest | 99 | `GoldChest.png` |
| `GoldVault` | Gold Vault | 349 | `GoldVault.png` |

**Starter Pack**
> One time only: 3 Starfall Crates, 30 minutes of 2× Gold and a Haste Tonic (+20% mining speed for 10 minutes). Crates hold a random effect, tonic or gold; the odds are shown in the game before you buy.

**Founder's Halo**
> A Limited aura: only 100 will ever be sold, across every server. A gold crown inside a rose ring, wings of light and a pulse at your feet, plus +16% movement speed while you wear it.

**1 Starfall Crate**
> One Starfall Crate: a random Mining FX, Player FX, tonic or gold. The odds are shown in the game before you buy.

**3 Starfall Crates**
> Three Starfall Crates, each a random Mining FX, Player FX, tonic or gold. The odds are shown in the game before you buy.

**10 Starfall Crates**
> Ten Starfall Crates, each a random Mining FX, Player FX, tonic or gold. The odds are shown in the game before you buy.

**2× Gold · 15 min**
> Doubles the gold from every sale for 15 minutes.

**2× Gold · 1 hour**
> Doubles the gold from every sale for an hour.

**2× Server Luck · 15 min**
> Doubles everyone's chance of rare ore in this server for 15 minutes, with your name on it.

**Instamine · 10 min**
> For 10 minutes, every block your pick can mine breaks in one hit.

**Auto Sell · 30 min**
> For 30 minutes your pack sells itself the moment it fills, wherever you are.

**Fling**
> Send a nearby miner flying.

**Reset Skill Tree**
> Get every skill point back to spend again.

**Gold Pouch**
> Gold equal to 15 minutes of your own recent earnings.

**Gold Bag**
> Gold equal to an hour of your own recent earnings.

**Gold Chest**
> Gold equal to 4 hours of your own recent earnings.

**Gold Vault**
> Gold equal to a whole day of your own recent earnings.
