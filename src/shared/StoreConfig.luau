--!strict
-- Game passes and developer products. Everything in the Shop costs Robux; all purchase IDs live here.
--
-- BEFORE PUBLISHING: create each pass and product on the Creator Dashboard (Monetization) at the
-- listed price and put its ID in `id`. An entry with `id = 0` cannot be bought; in an unpublished
-- Studio test it is given for free instead. Double Gold and Prism Trail already exist: give them
-- their existing pass IDs so current owners keep them.
--
-- `was` is a real reference price, shown struck through: the same thing bought the expensive way
-- (single crates, the smallest gold pack's rate, the passes one by one, or the parts of a pack).
local S = {}

-- `grants` lists the benefit keys a pass turns on. The All Passes Bundle (key "Everything") includes every other pass.
-- A `retired` pass is no longer sold: owners keep it (give it its existing ID), and the Everything
-- Pass still includes it.
S.passes = {
	{ key = "BiggerPack", id = 0, price = 79, name = "Bigger Pack", detail = "+50% backpack capacity", grants = { "BiggerPack" }, icon = "Pack" },
	{ key = "PrismTrail", id = 0, price = 99, name = "Prism Trail", detail = "A rainbow ribbon follows you as you walk", grants = { "PrismTrail" }, icon = "Trail", retired = true },
	{ key = "DoubleGold", id = 0, price = 249, name = "Double Gold", detail = "2× gold on every sale. Stacks with rebirths", grants = { "DoubleGold" }, icon = "Coins" },
	{ key = "FastPick", id = 0, price = 229, name = "Fast Pick", detail = "+15% mining speed", grants = { "FastPick" }, icon = "Speed" },
	{ key = "VIP", id = 0, price = 449, name = "VIP", detail = "Gold VIP tag, +10% gold and a free Starfall Crate every day", grants = { "VIP" }, icon = "Achievements", tag = "POPULAR" },
	{ key = "Lucky", id = 0, price = 349, name = "2× Lucky", detail = "Doubles the chance of every ore rarer than 1%, Starfall included", grants = { "Lucky" }, icon = "Crystal", luck = true },
}
local everything = { "Everything" }
for _, pass in S.passes do
	for _, benefit in pass.grants do table.insert(everything, benefit) end
end
-- Every pass in one, plus the Celestial title, the Celestial mining trail and the Prism Ribbon.
table.insert(S.passes, 1, {
	key = "Everything", id = 0, price = 599, name = "All Passes Bundle", icon = "Achievements", luck = true, tag = "BEST VALUE",
	detail = "Every pass, the Celestial title, the Celestial mining trail and the Prism Ribbon", grants = everything, bundle = true,
})

-- Products. `group` is the Shop section. `crates` gives that many Starfall Crates (the first opens at
-- once). `minutes` on a gold pack pays that many minutes of the buyer's own earnings. `boost` starts a
-- timed boost. `random` marks a paid random item and `luck` a chance modifier: players whose region
-- restricts paid random items can buy neither. `once` products can be bought a single time.
S.products = {
	-- Featured
	{
		key = "StarterPack", id = 0, price = 49, was = 128, name = "Starter Pack", group = "Featured", once = true, random = true,
		detail = "2 Starfall Crates, 30 min of 2× Gold and a Haste Tonic", crates = 2, icon = "Shop",
	},
	{
		key = "FounderHalo", id = 0, price = 249, name = "Founder's Halo", group = "Featured", once = true, limited = 100,
		detail = "Limited aura: only 100 will ever exist", cosmetic = { kind = "aura", id = "FounderHalo" },
	},
	-- Crates
	{ key = "Crate1", id = 0, price = 25, name = "1 Starfall Crate", group = "Crates", crates = 1, random = true },
	{ key = "Crate3", id = 0, price = 65, was = 75, name = "3 Starfall Crates", group = "Crates", crates = 3, random = true, tag = "POPULAR" },
	{ key = "Crate10", id = 0, price = 199, was = 250, name = "10 Starfall Crates", group = "Crates", crates = 10, random = true, tag = "BEST VALUE" },
	-- Boosts
	{ key = "Gold2x15", id = 0, price = 39, name = "2× Gold · 15 min", detail = "Doubles sale value for 15 minutes", boost = "gold2", minutes = 15, group = "Boosts", icon = "Coins" },
	{ key = "Gold2x60", id = 0, price = 99, was = 156, name = "2× Gold · 1 hour", detail = "Doubles sale value for an hour", boost = "gold2", minutes = 60, group = "Boosts", icon = "Coins", tag = "BEST VALUE" },
	{ key = "ServerLuck", id = 0, price = 79, name = "2× Server Luck · 15 min", detail = "Doubles everyone's chance of rare ore, with your name on it", minutes = 15, group = "Boosts", luck = true, icon = "Friends", tag = "FOR EVERYONE" },
	{ key = "Instamine10", id = 0, price = 49, name = "Instamine · 10 min", detail = "Every block you can mine breaks in one hit for 10 minutes", boost = "instamine", minutes = 10, group = "Boosts", icon = "Power", tag = "POPULAR" },
	{ key = "AutoSell30", id = 0, price = 35, name = "Auto Sell · 30 min", detail = "Your pack sells itself the moment it fills, for 30 minutes", boost = "autosell", minutes = 30, group = "Boosts", icon = "Coins", tag = "POPULAR" },
	{ key = "ResetSkills", id = 0, price = 15, name = "Reset Skill Tree", detail = "Get every skill point back to spend again", group = "Boosts", icon = "Skills" },
	-- Gold: minutes of the buyer's own earnings, from smallest to best value.
	{ key = "GoldPouch", id = 0, price = 15, name = "Gold Pouch", minutes = 15, group = "Gold", art = "pouch" },
	{ key = "GoldBag", id = 0, price = 35, was = 60, name = "Gold Bag", minutes = 60, group = "Gold", art = "bag" },
	{ key = "GoldChest", id = 0, price = 79, was = 240, name = "Gold Chest", minutes = 240, group = "Gold", art = "chest", tag = "POPULAR" },
	{ key = "GoldVault", id = 0, price = 199, was = 1440, name = "Gold Vault", minutes = 1440, group = "Gold", art = "vault", tag = "BEST VALUE" },
}
S.vipCrateHours = 20

S.passByKey, S.productByKey = {}, {}
for _, pass in S.passes do
	S.passByKey[pass.key] = pass
end
for _, product in S.products do
	S.productByKey[product.key] = product
end

-- The All Passes Bundle's struck-through price: every pass on sale, bought one by one.
local sum = 0
for _, pass in S.passes do
	if not pass.bundle and not pass.retired then sum += pass.price end
end
S.passByKey.Everything.was = sum

-- How long a stretch of earnings reads: "15 minutes", "an hour", "4 hours", "a whole day".
function S.duration(minutes: number): string
	if minutes >= 1440 then return if minutes == 1440 then "a whole day" else (minutes // 1440) .. " days" end
	if minutes >= 60 then return if minutes == 60 then "an hour" else (minutes // 60) .. " hours" end
	return minutes .. " minutes"
end

-- Percent off the struck-through price, or nil.
function S.off(item: any): number?
	if not item.was or item.was <= item.price then return nil end
	return math.floor((1 - item.price / item.was) * 100 + 0.5)
end

return S
