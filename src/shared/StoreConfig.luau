--!strict
-- Game passes and developer products. All purchase IDs live here.
--
-- BEFORE PUBLISHING: create each pass and product on the Creator Dashboard (Monetization) at the
-- listed price and put its ID in `id`. An entry with `id = 0` cannot be bought; in an unpublished
-- Studio test it can be tried for free instead. Double Gold and Prism Trail already exist: give
-- them their existing pass IDs so current owners keep them.
local S = {}

-- `grants` lists the benefit keys a pass turns on. Celestial Miner includes four other passes.
S.passes = {
	{ key = "BiggerPack", id = 0, price = 49, name = "Bigger Pack", detail = "+50% backpack capacity", grants = { "BiggerPack" }, icon = "Pack" },
	{ key = "PrismTrail", id = 0, price = 99, name = "Prism Trail", detail = "A rainbow ribbon behind you as you walk", grants = { "PrismTrail" }, icon = "Trail" },
	{ key = "AutoSell", id = 0, price = 149, name = "Auto-Sell", detail = "Sells your pack the moment it fills, anywhere", grants = { "AutoSell" }, icon = "Coins" },
	{ key = "DoubleGold", id = 0, price = 199, name = "Double Gold", detail = "2× gold on every sale. Stacks with rebirths", grants = { "DoubleGold" }, icon = "Coins" },
	{ key = "FastPick", id = 0, price = 199, name = "Fast Pick", detail = "+15% mining speed", grants = { "FastPick" }, icon = "Speed" },
	{ key = "VIP", id = 0, price = 249, name = "VIP", detail = "Gold VIP tag, +10% gold and a free gem chest every day", grants = { "VIP" }, icon = "Achievements" },
	{ key = "Lucky", id = 0, price = 299, name = "2× Lucky", detail = "Doubles the chance of every ore rarer than 1%, Starfall included", grants = { "Lucky" }, icon = "Crystal", luck = true },
	{ key = "StarfallDrake", id = 0, price = 799, name = "Starfall Drake", detail = "An exclusive pet with glowing gold wings", grants = { "StarfallDrake" }, icon = "Pets" },
	{
		key = "CelestialMiner", id = 0, price = 999, name = "Celestial Miner",
		detail = "Double Gold, 2× Lucky, Auto-Sell and VIP in one, plus the Celestial title and mining trail",
		grants = { "CelestialMiner", "DoubleGold", "Lucky", "AutoSell", "VIP" }, icon = "Achievements", luck = true,
	},
}

-- `once` products can be bought a single time per player. `luck` marks a chance modifier, which
-- players whose region restricts paid random items can't buy.
S.products = {
	{ key = "SellAnywhere", id = 0, price = 15, name = "Sell Anywhere", detail = "Sell your whole pack right now, wherever you are", group = "Boosts" },
	{ key = "GemPouch", id = 0, price = 25, name = "Gem Pouch", gems = 25, group = "Gems" },
	{ key = "StarterPack", id = 0, price = 49, name = "Starter Pack", detail = "60 gems, 3 survey flares and 30 min of 2× gold", gems = 60, once = true, group = "Featured" },
	{ key = "Gold2x15", id = 0, price = 39, name = "2× Gold · 15 min", detail = "Doubles sale value for 15 minutes", boost = "gold2", minutes = 15, group = "Boosts" },
	{ key = "Luck2x15", id = 0, price = 59, name = "2× Luck · 15 min", detail = "Doubles the chance of rare ore for 15 minutes", boost = "luck2", minutes = 15, group = "Boosts", luck = true },
	{ key = "GemBag", id = 0, price = 99, name = "Gem Bag", gems = 120, group = "Gems" },
	{ key = "GoldCrate", id = 0, price = 149, name = "Gold Bundle", detail = "About an hour of your own gold earnings", group = "Boosts" },
	{ key = "GemChest", id = 0, price = 199, name = "Gem Chest", gems = 300, group = "Gems" },
	{ key = "ServerLuck", id = 0, price = 349, name = "Server Luck · 15 min", detail = "2× luck for everyone in this server, with your name on it", minutes = 15, group = "Boosts", luck = true },
	{ key = "GemVault", id = 0, price = 499, name = "Gem Vault", gems = 900, group = "Gems" },
	{ key = "GemHoard", id = 0, price = 999, name = "Gem Hoard", gems = 2000, group = "Gems" },
	{ key = "GemMountain", id = 0, price = 1999, name = "Gem Mountain", gems = 4500, group = "Gems" },
	-- Limited: the first 1,000 buyers across every server, then it goes off sale for good.
	{
		key = "FounderGriffin", id = 0, price = 399, name = "Founder's Griffin", once = true, group = "Featured",
		detail = "Limited pet: only 1,000 will ever exist", limited = 1000, pet = "Griffin",
	},
}
-- Shop ribbons on the gem packs.
S.mostPopular, S.bestValue = "GemChest", "GemMountain"
S.vipChest = { gems = 15, cooldown = 20 * 3600 }

S.passByKey, S.productByKey = {}, {}
for _, pass in S.passes do
	S.passByKey[pass.key] = pass
end
for _, product in S.products do
	S.productByKey[product.key] = product
end

-- What a gem pack would cost at the Gem Pouch's rate (1 gem per Robux): shown struck through.
function S.basePrice(product: any): number
	local base = S.productByKey.GemPouch
	return math.floor(product.gems * base.price / base.gems + 0.5)
end

-- Extra gems per Robux compared with the Gem Pouch, as a whole percent (0 for the pouch itself).
function S.gemBonus(product: any): number
	local base = S.productByKey.GemPouch
	return math.floor((product.gems / product.price) / (base.gems / base.price) * 100 - 100 + 0.5)
end

return S
