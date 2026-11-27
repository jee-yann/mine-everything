--!strict
-- Crates: what each one holds and the exact odds. Weights are in hundredths of a percent, so every
-- crate's pool adds up to exactly 100%. The Shop shows these same numbers. (The module keeps its old
-- name, Geodes, so saved crate items and counters stay valid.)
--
-- Stone    common pets, a first trail, ribbon and pet style, and tonics
-- Crystal  rare and epic pets and cosmetics
-- Starfall the legendary and mythic pets and cosmetics, with a guarantee (see `pity`)
local Collectibles = require(script.Parent.Collectibles)
local G = {}

G.list = {
	{
		id = "Pebble", name = "Stone Crate", price = 25, color = Color3.fromRGB(196, 150, 96),
		blurb = "Common pets, a first trail and tonics",
		pool = {
			{ kind = "pet", id = "Bat", weight = 1200 },
			{ kind = "pet", id = "Mole", weight = 1200 },
			{ kind = "pet", id = "Frog", weight = 1200 },
			{ kind = "pet", id = "Crab", weight = 700 },
			{ kind = "pet", id = "Hedgehog", weight = 700 },
			{ kind = "pet", id = "Turtle", weight = 700 },
			{ kind = "pet", id = "Penguin", weight = 700 },
			{ kind = "trail", id = "Ember", weight = 900 },
			{ kind = "ribbon", id = "Mint", weight = 500 },
			{ kind = "style", id = "Sparkle", weight = 500 },
			{ kind = "item", id = "GoldTonic", weight = 600 },
			{ kind = "item", id = "HasteTonic", weight = 600 },
			{ kind = "pet", id = "Slime", weight = 200 },
			{ kind = "pet", id = "Bunny", weight = 200 },
			{ kind = "item", id = "LuckyBrew", weight = 100 },
		},
	},
	{
		id = "Crystal", name = "Crystal Crate", price = 75, color = Color3.fromRGB(176, 120, 255),
		blurb = "Rare and epic pets and cosmetics",
		pool = {
			{ kind = "pet", id = "Slime", weight = 1000 },
			{ kind = "pet", id = "Moth", weight = 1000 },
			{ kind = "pet", id = "Bunny", weight = 1000 },
			{ kind = "pet", id = "Golem", weight = 1000 },
			{ kind = "trail", id = "Frost", weight = 800 },
			{ kind = "trail", id = "Verdant", weight = 800 },
			{ kind = "ribbon", id = "Sunset", weight = 600 },
			{ kind = "style", id = "Wings", weight = 600 },
			{ kind = "aura", id = "Sparks", weight = 600 },
			{ kind = "item", id = "LuckyBrew", weight = 500 },
			{ kind = "pet", id = "Drake", weight = 350 },
			{ kind = "pet", id = "Fox", weight = 350 },
			{ kind = "pet", id = "Jelly", weight = 350 },
			{ kind = "trail", id = "Aurora", weight = 300 },
			{ kind = "aura", id = "Embers", weight = 250 },
			{ kind = "style", id = "Flames", weight = 200 },
			{ kind = "pet", id = "Owl", weight = 100 },
			{ kind = "trail", id = "Comet", weight = 100 },
			{ kind = "pet", id = "Stag", weight = 100 },
		},
	},
	{
		id = "Starfall", name = "Starfall Crate", price = 220, color = Color3.fromRGB(150, 100, 255),
		blurb = "Legendary and Mythic pets and effects",
		-- After nine opens in a row without a Legendary or better, the tenth is one.
		pity = { after = 9, rank = 5 },
		pool = {
			{ kind = "pet", id = "Drake", weight = 1600 },
			{ kind = "pet", id = "Fox", weight = 1600 },
			{ kind = "pet", id = "Jelly", weight = 1600 },
			{ kind = "trail", id = "Aurora", weight = 1000 },
			{ kind = "aura", id = "Embers", weight = 1000 },
			{ kind = "style", id = "Flames", weight = 800 },
			{ kind = "pet", id = "Salamander", weight = 300 },
			{ kind = "pet", id = "Owl", weight = 300 },
			{ kind = "pet", id = "Stag", weight = 300 },
			{ kind = "trail", id = "Solar", weight = 250 },
			{ kind = "trail", id = "Comet", weight = 250 },
			{ kind = "aura", id = "Halo", weight = 250 },
			{ kind = "ribbon", id = "Starlight", weight = 250 },
			{ kind = "style", id = "Crown", weight = 200 },
			{ kind = "style", id = "StarHalo", weight = 200 },
			{ kind = "pet", id = "Wisp", weight = 30 },
			{ kind = "pet", id = "Phoenix", weight = 30 },
			{ kind = "trail", id = "Rift", weight = 20 },
			{ kind = "ribbon", id = "Void", weight = 10 },
			{ kind = "aura", id = "Nebula", weight = 5 },
			{ kind = "style", id = "Cloak", weight = 5 },
		},
	},
	-- The Welcome Crate is the onboarding gift: one reward, shown as a 100% guarantee. It is never sold.
	{
		id = "Welcome", name = "Welcome Crate", color = Color3.fromRGB(255, 214, 120), gift = true,
		blurb = "Your first crate: a guaranteed Legendary Comet Trail",
		pool = { { kind = "trail", id = "Comet", weight = 10000 } },
	},
}
G.byId = {}
for _, geode in G.list do
	G.byId[geode.id] = geode
end

-- The entry's catalogue record (pet, cosmetic or item).
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

-- Percent with enough places that small odds still show (0.05%, 1.5%, 22%).
function G.percentText(percent: number): string
	if percent >= 10 then return (string.format("%.1f%%", percent):gsub("%.0%%", "%%")) end
	return (string.format("%.2f%%", percent):gsub("0+%%$", "%%"):gsub("%.%%", "%%"))
end

return G
