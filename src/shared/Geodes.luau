--!strict
-- Crates: what each one holds and the exact odds. Weights are in hundredths of a percent, so every
-- crate's pool adds up to exactly 100%. The Shop shows these same numbers. (The module keeps its old
-- name, Geodes, and the crate keeps the id "Starfall", so saved crate items and counters stay valid.)
--
-- There is one crate, the Starfall Crate, bought with Robux or earned. Its mix by rarity:
--   Common 40%  ·  Uncommon 28%  ·  Rare 18%  ·  Epic 9.5%  ·  Legendary 4%  ·  Mythic 0.5%
-- and every 10th crate without a Legendary or better is guaranteed one. The Welcome Crate is the
-- day-1 daily reward and always holds the Epic Comet Trail.
local Collectibles = require(script.Parent.Collectibles)
local G = {}

G.list = {
	{
		id = "Starfall", name = "Starfall Crate", color = Color3.fromRGB(150, 100, 255),
		blurb = "Mining trails, player trails, auras, tonics and gold",
		-- After nine opens in a row without a Legendary or better, the tenth is one.
		pity = { after = 9, rank = 5 },
		pool = {
			-- Common 40%
			{ kind = "trail", id = "Copper", weight = 900 },
			{ kind = "trail", id = "Ember", weight = 900 },
			{ kind = "ribbon", id = "Dust", weight = 800 },
			{ kind = "aura", id = "Motes", weight = 700 },
			{ kind = "item", id = "GoldPouch", weight = 700 },
			-- Uncommon 28%
			{ kind = "trail", id = "Frost", weight = 500 },
			{ kind = "trail", id = "Moss", weight = 500 },
			{ kind = "ribbon", id = "Mint", weight = 500 },
			{ kind = "aura", id = "Leaves", weight = 500 },
			{ kind = "item", id = "GoldSack", weight = 300 },
			{ kind = "item", id = "GoldTonic", weight = 250 },
			{ kind = "item", id = "HasteTonic", weight = 250 },
			-- Rare 18%
			{ kind = "trail", id = "Verdant", weight = 350 },
			{ kind = "trail", id = "Sakura", weight = 350 },
			{ kind = "ribbon", id = "Sunset", weight = 300 },
			{ kind = "ribbon", id = "Candy", weight = 300 },
			{ kind = "aura", id = "Sparks", weight = 150 },
			{ kind = "aura", id = "Mist", weight = 150 },
			{ kind = "item", id = "LuckyBrew", weight = 200 },
			-- Epic 9.5%
			{ kind = "trail", id = "Aurora", weight = 200 },
			{ kind = "trail", id = "Thunder", weight = 200 },
			{ kind = "trail", id = "Comet", weight = 150 },
			{ kind = "ribbon", id = "EmberRibbon", weight = 150 },
			{ kind = "aura", id = "Embers", weight = 150 },
			{ kind = "item", id = "GoldChest", weight = 100 },
			-- Legendary 4%
			{ kind = "trail", id = "Solar", weight = 80 },
			{ kind = "trail", id = "Inferno", weight = 80 },
			{ kind = "ribbon", id = "Starlight", weight = 60 },
			{ kind = "ribbon", id = "AuroraRibbon", weight = 60 },
			{ kind = "aura", id = "Halo", weight = 60 },
			{ kind = "aura", id = "Sunburst", weight = 60 },
			-- Mythic 0.5%
			{ kind = "trail", id = "Rift", weight = 15 },
			{ kind = "trail", id = "Galaxy", weight = 15 },
			{ kind = "ribbon", id = "Void", weight = 10 },
			{ kind = "aura", id = "Nebula", weight = 10 },
		},
	},
	-- The Welcome Crate is the day-1 daily reward: one reward, shown as a 100% guarantee. It is never sold.
	{
		id = "Welcome", name = "Welcome Crate", color = Color3.fromRGB(255, 214, 120), gift = true,
		blurb = "Your first crate: a guaranteed Epic Comet Trail",
		pool = { { kind = "trail", id = "Comet", weight = 10000 } },
	},
}
G.byId = {}
for _, geode in G.list do
	G.byId[geode.id] = geode
end
G.main = G.byId.Starfall

-- The entry's catalogue record (cosmetic or item).
function G.entry(reward: any): any
	return Collectibles.find(reward.kind, reward.id)
end
function G.rank(reward: any): number
	return Collectibles.rarities[G.entry(reward).rarity].rank
end

-- The pool this roll draws from: the whole pool, or only Legendary and better when the guarantee is due.
function G.pool(geode: any, pity: number?): { any }
	if geode.pity and (pity or 0) >= geode.pity.after then
		local top = {}
		for _, reward in geode.pool do
			if G.rank(reward) >= geode.pity.rank then table.insert(top, reward) end
		end
		return top
	end
	return geode.pool
end

-- Each outcome's chance in percent, for the odds list. They add up to 100.
function G.odds(geode: any, pity: number?): { { reward: any, percent: number } }
	local pool, total = G.pool(geode, pity), 0
	for _, reward in pool do
		total += reward.weight
	end
	local out = {}
	for _, reward in pool do
		table.insert(out, { reward = reward, percent = reward.weight * 100 / total })
	end
	return out
end

-- The chance of each rarity, in rarity order: { { rarity, percent } }. They add up to 100.
function G.breakdown(geode: any, pity: number?): { { any } }
	local sums = {}
	for _, row in G.odds(geode, pity) do
		local rarity = G.entry(row.reward).rarity
		sums[rarity] = (sums[rarity] or 0) + row.percent
	end
	local out = {}
	for _, rarity in Collectibles.rarityOrder do
		if sums[rarity] then table.insert(out, { rarity, sums[rarity] }) end
	end
	return out
end

-- Draws one reward with `rng` (a Random). Server only.
function G.roll(geode: any, rng: Random, pity: number?): any
	local pool, total = G.pool(geode, pity), 0
	for _, reward in pool do
		total += reward.weight
	end
	local pick = rng:NextInteger(1, total)
	for _, reward in pool do
		pick -= reward.weight
		if pick <= 0 then return reward end
	end
	return pool[#pool]
end

-- Percent with enough places that small odds still show (0.1%, 1.5%, 22%).
function G.percentText(percent: number): string
	if percent >= 10 then return (string.format("%.1f%%", percent):gsub("%.0%%", "%%")) end
	return (string.format("%.2f%%", percent):gsub("0+%%$", "%%"):gsub("%.%%", "%%"))
end

return G
