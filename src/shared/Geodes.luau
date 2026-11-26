--!strict
-- Geodes: what each one holds and the exact odds. Weights are in hundredths of a percent, so every
-- geode's pool adds up to exactly 100%. The shop shows these same numbers.
--
-- Pebble   the first pets, food and tonics
-- Crystal  cosmetics: trails and auras, with some pets
-- Starfall the rare pets and the best cosmetics, with a guarantee (see `pity`)
local Collectibles = require(script.Parent.Collectibles)
local G = {}

G.list = {
	{
		id = "Pebble", name = "Pebble Geode", price = 25, color = Color3.fromRGB(176, 168, 158),
		blurb = "Starter pets, food and tonics",
		pool = {
			{ kind = "pet", id = "Bat", weight = 1800 },
			{ kind = "pet", id = "Crab", weight = 1200 },
			{ kind = "pet", id = "Hedgehog", weight = 1200 },
			{ kind = "pet", id = "Slime", weight = 400 },
			{ kind = "pet", id = "Moth", weight = 400 },
			{ kind = "item", id = "Snack", count = 3, weight = 2000 },
			{ kind = "item", id = "GoldTonic", weight = 800 },
			{ kind = "item", id = "HasteTonic", weight = 800 },
			{ kind = "trail", id = "Ember", weight = 800 },
			{ kind = "trail", id = "Frost", weight = 500 },
			{ kind = "item", id = "LuckyBrew", weight = 100 },
		},
	},
	{
		id = "Crystal", name = "Crystal Geode", price = 75, color = Color3.fromRGB(176, 120, 255),
		blurb = "Trails and auras, with rarer pets",
		pool = {
			{ kind = "trail", id = "Verdant", weight = 1400 },
			{ kind = "aura", id = "Sparks", weight = 1400 },
			{ kind = "pet", id = "Slime", weight = 1400 },
			{ kind = "pet", id = "Moth", weight = 1400 },
			{ kind = "item", id = "Feast", weight = 1000 },
			{ kind = "item", id = "LuckyBrew", weight = 700 },
			{ kind = "trail", id = "Aurora", weight = 600 },
			{ kind = "aura", id = "Embers", weight = 600 },
			{ kind = "pet", id = "Drake", weight = 600 },
			{ kind = "pet", id = "Fox", weight = 600 },
			{ kind = "trail", id = "Comet", weight = 150 },
			{ kind = "pet", id = "Owl", weight = 150 },
		},
	},
	{
		id = "Starfall", name = "Starfall Geode", price = 220, color = Color3.fromRGB(150, 100, 255),
		blurb = "Legendary and Mythic pets and effects",
		-- After nine opens in a row without a Legendary or better, the tenth is one.
		pity = { after = 9, rank = 5 },
		pool = {
			{ kind = "pet", id = "Drake", weight = 2200 },
			{ kind = "pet", id = "Fox", weight = 2200 },
			{ kind = "trail", id = "Aurora", weight = 1600 },
			{ kind = "aura", id = "Embers", weight = 1600 },
			{ kind = "pet", id = "Salamander", weight = 400 },
			{ kind = "pet", id = "Owl", weight = 400 },
			{ kind = "trail", id = "Solar", weight = 400 },
			{ kind = "trail", id = "Comet", weight = 400 },
			{ kind = "aura", id = "Halo", weight = 400 },
			{ kind = "pet", id = "Wisp", weight = 200 },
			{ kind = "trail", id = "Rift", weight = 150 },
			{ kind = "aura", id = "Nebula", weight = 50 },
		},
	},
}
-- The Welcome Geode is the onboarding gift: one reward, shown as a 100% guarantee. It is never sold.
table.insert(G.list, {
	id = "Welcome", name = "Welcome Geode", color = Color3.fromRGB(255, 214, 120), gift = true,
	blurb = "Your first geode: a guaranteed Legendary Comet Trail",
	pool = { { kind = "trail", id = "Comet", weight = 10000 } },
})
G.byId = {}
for _, geode in G.list do
	G.byId[geode.id] = geode
end

-- The entry's catalogue record (pet, trail, aura or item).
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

-- Percent with enough places that small odds still show (0.5%, 1.5%, 22%).
function G.percentText(percent: number): string
	if percent >= 10 then return (string.format("%.1f%%", percent):gsub("%.0%%", "%%")) end
	return (string.format("%.2f%%", percent):gsub("0+%%$", "%%"):gsub("%.%%", "%%"))
end

return G
