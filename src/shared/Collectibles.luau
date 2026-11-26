--!strict
-- Everything a miner can collect: rarities, pets, cosmetics (mining trails and auras) and items
-- (pet food, tonics and geodes). Geode reward pools and odds live in Shared.Geodes, crafting in
-- Shared.Recipes. Adding a pet, trail or aura is one entry here (plus its model or effect look).
local rgb = Color3.fromRGB
local C = {}

C.rarities = {
	Common = { rank = 1, color = rgb(200, 206, 222), dust = 3 },
	Uncommon = { rank = 2, color = rgb(110, 230, 120), dust = 8 },
	Rare = { rank = 3, color = rgb(90, 190, 255), dust = 20 },
	Epic = { rank = 4, color = rgb(200, 130, 255), dust = 50 },
	Legendary = { rank = 5, color = rgb(255, 196, 60), dust = 150 },
	Mythic = { rank = 6, color = rgb(255, 96, 140), dust = 500 },
	Exclusive = { rank = 7, color = rgb(110, 240, 230), dust = 0 },
}

-- Pet bonuses. Each pet helps one part of the loop; the totals are capped so no mix runs away.
--   gold   +% sale value        speed  +% mining speed (shorter cuts)
--   luck   +% rare-ore luck     xp     +% mining XP
--   gems   +% gem-find chance
C.bonusText = {
	gold = "Gold", speed = "Speed", luck = "Luck", xp = "XP", gems = "Gem find",
}
C.bonusCaps = { gold = 0.8, speed = 0.35, luck = 0.6, xp = 0.8, gems = 1.5 }

-- `amount` is the bonus at level 1 with no stars. `motion`: hop, fly, scuttle, bounce, trot, crawl, float.
C.pets = {
	{ id = "Rock", name = "Pocket Rock", rarity = "Common", bonus = "gold", amount = 0.03, motion = "hop", starter = true },
	{ id = "Bat", name = "Coal Bat", rarity = "Common", bonus = "xp", amount = 0.05, motion = "fly" },
	{ id = "Crab", name = "Copper Crab", rarity = "Uncommon", bonus = "gold", amount = 0.06, motion = "scuttle" },
	{ id = "Hedgehog", name = "Quartz Hedgehog", rarity = "Uncommon", bonus = "speed", amount = 0.04, motion = "hop" },
	{ id = "Slime", name = "Gem Slime", rarity = "Rare", bonus = "gems", amount = 0.35, motion = "bounce" },
	{ id = "Moth", name = "Glow Moth", rarity = "Rare", bonus = "xp", amount = 0.12, motion = "fly" },
	{ id = "Drake", name = "Cave Drake", rarity = "Epic", bonus = "luck", amount = 0.08, motion = "fly" },
	{ id = "Fox", name = "Crystal Fox", rarity = "Epic", bonus = "speed", amount = 0.08, motion = "trot" },
	{ id = "Salamander", name = "Magma Salamander", rarity = "Legendary", bonus = "gold", amount = 0.16, motion = "crawl" },
	{ id = "Owl", name = "Prism Owl", rarity = "Legendary", bonus = "luck", amount = 0.14, motion = "fly" },
	{ id = "Wisp", name = "Star Wisp", rarity = "Mythic", bonus = "luck", amount = 0.2, motion = "float" },
	{ id = "StarDrake", name = "Starfall Drake", rarity = "Exclusive", bonus = "luck", amount = 0.05, motion = "fly", pass = "StarfallDrake" },
}
C.petSlots = 3
C.maxPetLevel = 30
C.maxStars = 3

-- Mining trails follow the pickaxe through each swing and set the colour of its sparks.
C.trails = {
	{ id = "Ember", name = "Ember Trail", rarity = "Common", colors = { rgb(255, 196, 90), rgb(255, 92, 40) } },
	{ id = "Frost", name = "Frost Trail", rarity = "Uncommon", colors = { rgb(210, 248, 255), rgb(90, 180, 255) } },
	{ id = "Verdant", name = "Verdant Trail", rarity = "Rare", colors = { rgb(190, 255, 150), rgb(40, 190, 110) }, sparkle = true },
	{ id = "Aurora", name = "Aurora Trail", rarity = "Epic", colors = { rgb(110, 255, 200), rgb(150, 110, 255) }, sparkle = true, shimmer = true },
	{ id = "Comet", name = "Comet Trail", rarity = "Legendary", colors = { rgb(255, 255, 240), rgb(255, 205, 90) }, sparkle = true, stars = true },
	{ id = "Solar", name = "Solar Flare", rarity = "Legendary", colors = { rgb(255, 240, 140), rgb(255, 70, 40) }, sparkle = true, flames = true },
	{ id = "Rift", name = "Starfall Rift", rarity = "Mythic", colors = { rgb(236, 222, 255), rgb(150, 90, 255) }, sparkle = true, stars = true, shimmer = true },
	{ id = "Prism", name = "Prism Trail", rarity = "Exclusive", colors = { rgb(74, 240, 255), rgb(255, 97, 159) }, sparkle = true, shimmer = true, pass = "PrismTrail" },
	{ id = "Celestial", name = "Celestial Trail", rarity = "Exclusive", colors = { rgb(255, 236, 160), rgb(110, 240, 230) }, sparkle = true, stars = true, pass = "CelestialMiner" },
}

-- Auras circle the miner, or each equipped pet when worn in the pet aura slot.
C.auras = {
	{ id = "Sparks", name = "Spark Ring", rarity = "Rare", color = rgb(255, 230, 140), look = "ring" },
	{ id = "Embers", name = "Ember Halo", rarity = "Epic", color = rgb(255, 130, 60), look = "embers" },
	{ id = "Halo", name = "Celestial Halo", rarity = "Legendary", color = rgb(255, 240, 180), look = "halo" },
	{ id = "Nebula", name = "Nebula", rarity = "Mythic", color = rgb(190, 120, 255), look = "nebula" },
}

-- Items stack. Boost tonics last their duration; using another adds to it (up to an hour).
C.items = {
	{ id = "Snack", name = "Pet Snack", rarity = "Common", kind = "food", petXp = 150, detail = "+150 XP for each equipped pet" },
	{ id = "Feast", name = "Geode Feast", rarity = "Rare", kind = "food", petXp = 900, detail = "+900 XP for each equipped pet" },
	{ id = "GoldTonic", name = "Gold Tonic", rarity = "Uncommon", kind = "boost", boost = "goldTonic", minutes = 10, detail = "+50% gold from sales for 10 min" },
	{ id = "HasteTonic", name = "Haste Tonic", rarity = "Uncommon", kind = "boost", boost = "speedTonic", minutes = 10, detail = "+20% mining speed for 10 min" },
	{ id = "LuckyBrew", name = "Lucky Brew", rarity = "Rare", kind = "boost", boost = "luck2", minutes = 10, detail = "2× rare-ore luck for 10 min" },
	{ id = "WelcomeGeode", name = "Welcome Geode", rarity = "Legendary", kind = "geode", geode = "Welcome", detail = "Guaranteed: Comet Trail (Legendary)" },
	{ id = "PebbleGeode", name = "Pebble Geode", rarity = "Common", kind = "geode", geode = "Pebble", detail = "A free geode to crack open" },
	{ id = "CrystalGeode", name = "Crystal Geode", rarity = "Rare", kind = "geode", geode = "Crystal", detail = "A free geode to crack open" },
	{ id = "StarfallGeode", name = "Starfall Geode", rarity = "Legendary", kind = "geode", geode = "Starfall", detail = "A free geode to crack open" },
}

-- Timed boosts. Personal luck boosts don't multiply each other: the strongest active one counts.
C.boosts = {
	goldTonic = { name = "Gold Tonic", effect = "gold", amount = 0.5 },
	speedTonic = { name = "Haste Tonic", effect = "speed", amount = 0.2 },
	gold2 = { name = "2× Gold", effect = "goldTimes", amount = 2 },
	luck2 = { name = "2× Luck", effect = "luckTimes", amount = 2 },
	luck3 = { name = "3× Luck", effect = "luckTimes", amount = 3 },
	compass = { name = "Star Compass", effect = "compass" },
}
C.maxBoostMinutes = 240

local function index(list)
	local by = {}
	for i, entry in list do
		entry.order = i
		by[entry.id] = entry
	end
	return by
end
C.petById, C.trailById, C.auraById, C.itemById = index(C.pets), index(C.trails), index(C.auras), index(C.items)

-- What kind of thing an id is, and its entry.
function C.find(kind: string, id: string): any
	if kind == "pet" then return C.petById[id] end
	if kind == "trail" then return C.trailById[id] end
	if kind == "aura" then return C.auraById[id] end
	if kind == "item" then return C.itemById[id] end
	return nil
end

-- A pet's bonus at a level and star count: +3% of the base per level and +20% per star.
function C.petBonus(pet: any, level: number, stars: number): number
	return pet.amount * (1 + 0.03 * (math.clamp(level, 1, C.maxPetLevel) - 1)) * (1 + 0.2 * math.clamp(stars, 0, C.maxStars))
end

-- Pet XP needed to go from `level` to the next one.
function C.petXpFor(level: number): number
	return math.floor(40 * level ^ 1.6 + 0.5)
end

return C
