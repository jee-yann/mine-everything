--!strict
-- Everything a miner can collect: rarities, pets, cosmetics and items. Pets and cosmetics are purely
-- for looks; only tonics and passes change play. Crate reward pools and odds live in Shared.Geodes,
-- crafting in Shared.Recipes. Adding a pet or cosmetic is one entry here (plus its model or look).
--
-- Cosmetic kinds, each worn in its own slot:
--   trail   mining trail: colours the pickaxe's swing and sparks
--   ribbon  player trail: a ribbon behind the miner as they walk
--   aura    player aura: particles around the miner
--   style   pet style: wings, flames, a crown and more, worn by the miner's pet
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
	Limited = { rank = 8, color = rgb(255, 150, 60), dust = 0 },
}
C.rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive", "Limited" }

-- What each kind is called on screen.
C.kindNames = { pet = "Pet", trail = "Mining trail", ribbon = "Player trail", aura = "Player aura", style = "Pet style", item = "Item" }

-- One pet follows at a time. `motion`: hop, fly, scuttle, bounce, trot, crawl, float.
C.pets = {
	{ id = "Rock", name = "Pocket Rock", rarity = "Common", motion = "hop", starter = true },
	{ id = "Bat", name = "Coal Bat", rarity = "Common", motion = "fly" },
	{ id = "Mole", name = "Tunnel Mole", rarity = "Common", motion = "hop" },
	{ id = "Frog", name = "Moss Frog", rarity = "Common", motion = "hop" },
	{ id = "Crab", name = "Copper Crab", rarity = "Uncommon", motion = "scuttle" },
	{ id = "Hedgehog", name = "Quartz Hedgehog", rarity = "Uncommon", motion = "hop" },
	{ id = "Turtle", name = "Pebble Turtle", rarity = "Uncommon", motion = "crawl" },
	{ id = "Penguin", name = "Frost Penguin", rarity = "Uncommon", motion = "trot" },
	{ id = "Slime", name = "Gem Slime", rarity = "Rare", motion = "bounce" },
	{ id = "Moth", name = "Glow Moth", rarity = "Rare", motion = "fly" },
	{ id = "Bunny", name = "Opal Bunny", rarity = "Rare", motion = "hop" },
	{ id = "Golem", name = "Mini Golem", rarity = "Rare", motion = "trot" },
	{ id = "Drake", name = "Cave Drake", rarity = "Epic", motion = "fly" },
	{ id = "Fox", name = "Crystal Fox", rarity = "Epic", motion = "trot" },
	{ id = "Jelly", name = "Glow Jelly", rarity = "Epic", motion = "float" },
	{ id = "Salamander", name = "Magma Salamander", rarity = "Legendary", motion = "crawl" },
	{ id = "Owl", name = "Prism Owl", rarity = "Legendary", motion = "fly" },
	{ id = "Stag", name = "Aurora Stag", rarity = "Legendary", motion = "trot" },
	{ id = "Wisp", name = "Star Wisp", rarity = "Mythic", motion = "float" },
	{ id = "Phoenix", name = "Ember Phoenix", rarity = "Mythic", motion = "fly" },
	{ id = "StarDrake", name = "Starfall Drake", rarity = "Exclusive", motion = "fly", pass = "StarfallDrake" },
	{ id = "Griffin", name = "Founder's Griffin", rarity = "Limited", motion = "fly", product = "FounderGriffin" },
}
C.petSlots = 1

-- Mining trails follow the pickaxe through each swing and set the colour of its sparks.
C.trails = {
	{ id = "Ember", name = "Ember Trail", rarity = "Common", colors = { rgb(255, 196, 90), rgb(255, 92, 40) } },
	{ id = "Frost", name = "Frost Trail", rarity = "Uncommon", colors = { rgb(210, 248, 255), rgb(90, 180, 255) } },
	{ id = "Verdant", name = "Verdant Trail", rarity = "Rare", colors = { rgb(190, 255, 150), rgb(40, 190, 110) } },
	{ id = "Aurora", name = "Aurora Trail", rarity = "Epic", colors = { rgb(110, 255, 200), rgb(150, 110, 255) } },
	{ id = "Comet", name = "Comet Trail", rarity = "Legendary", colors = { rgb(255, 255, 240), rgb(255, 205, 90) } },
	{ id = "Solar", name = "Solar Flare", rarity = "Legendary", colors = { rgb(255, 240, 140), rgb(255, 70, 40) } },
	{ id = "Rift", name = "Starfall Rift", rarity = "Mythic", colors = { rgb(236, 222, 255), rgb(150, 90, 255) } },
	{ id = "Celestial", name = "Celestial Trail", rarity = "Exclusive", colors = { rgb(255, 236, 160), rgb(110, 240, 230) }, pass = "CelestialMiner" },
}

-- Player trails: a ribbon behind the miner as they walk.
C.ribbons = {
	{ id = "Mint", name = "Mint Ribbon", rarity = "Uncommon", colors = { rgb(200, 255, 220), rgb(60, 210, 160) } },
	{ id = "Sunset", name = "Sunset Ribbon", rarity = "Rare", colors = { rgb(255, 210, 120), rgb(255, 90, 140) } },
	{ id = "Starlight", name = "Starlight Ribbon", rarity = "Legendary", colors = { rgb(255, 250, 220), rgb(120, 170, 255) }, glints = true },
	{ id = "Void", name = "Void Ribbon", rarity = "Mythic", colors = { rgb(180, 120, 255), rgb(30, 20, 60) }, glints = true },
	{ id = "Prism", name = "Prism Ribbon", rarity = "Exclusive", colors = { rgb(74, 240, 255), rgb(255, 97, 159) }, glints = true, pass = "PrismTrail" },
}

-- Player auras circle the miner.
C.auras = {
	{ id = "Sparks", name = "Spark Ring", rarity = "Rare", color = rgb(255, 230, 140), look = "ring" },
	{ id = "Mist", name = "Frost Mist", rarity = "Rare", color = rgb(190, 235, 255), look = "nebula" },
	{ id = "Embers", name = "Ember Halo", rarity = "Epic", color = rgb(255, 130, 60), look = "embers" },
	{ id = "Halo", name = "Celestial Halo", rarity = "Legendary", color = rgb(255, 240, 180), look = "halo" },
	{ id = "Nebula", name = "Nebula", rarity = "Mythic", color = rgb(190, 120, 255), look = "nebula" },
}

-- Pet styles: something the pet wears.
C.styles = {
	{ id = "Sparkle", name = "Sparkle Trail", rarity = "Uncommon", color = rgb(255, 240, 160), look = "trail" },
	{ id = "Wings", name = "Fairy Wings", rarity = "Rare", color = rgb(190, 240, 255), look = "wings" },
	{ id = "Flames", name = "Pet Flames", rarity = "Epic", color = rgb(255, 140, 50), look = "flames" },
	{ id = "Crown", name = "Golden Crown", rarity = "Legendary", color = rgb(255, 210, 70), look = "crown" },
	{ id = "StarHalo", name = "Star Halo", rarity = "Legendary", color = rgb(255, 245, 190), look = "halo" },
	{ id = "Cloak", name = "Nebula Cloak", rarity = "Mythic", color = rgb(170, 110, 255), look = "cloak" },
}

-- Items stack. Tonics last their duration; using another adds to it (up to four hours).
-- Crates are opened from the inventory.
C.items = {
	{ id = "GoldTonic", name = "Gold Tonic", rarity = "Uncommon", kind = "boost", boost = "goldTonic", minutes = 10, detail = "+50% gold from sales for 10 min" },
	{ id = "HasteTonic", name = "Haste Tonic", rarity = "Uncommon", kind = "boost", boost = "speedTonic", minutes = 10, detail = "+20% mining speed for 10 min" },
	{ id = "LuckyBrew", name = "Lucky Brew", rarity = "Rare", kind = "boost", boost = "luck2", minutes = 10, detail = "2× rare-ore luck for 10 min" },
	{ id = "WelcomeGeode", name = "Welcome Crate", rarity = "Legendary", kind = "geode", geode = "Welcome", detail = "Guaranteed: Comet Trail (Legendary)" },
	{ id = "PebbleGeode", name = "Stone Crate", rarity = "Common", kind = "geode", geode = "Pebble", detail = "A free crate to open" },
	{ id = "CrystalGeode", name = "Crystal Crate", rarity = "Rare", kind = "geode", geode = "Crystal", detail = "A free crate to open" },
	{ id = "StarfallGeode", name = "Starfall Crate", rarity = "Legendary", kind = "geode", geode = "Starfall", detail = "A free crate to open" },
}

-- Timed boosts. Luck boosts don't multiply each other: the strongest active one counts.
C.boosts = {
	goldTonic = { name = "Gold Tonic", effect = "gold", amount = 0.5 },
	speedTonic = { name = "Haste Tonic", effect = "speed", amount = 0.2 },
	gold2 = { name = "2× Gold", effect = "goldTimes", amount = 2 },
	luck2 = { name = "2× Luck", effect = "luckTimes", amount = 2 },
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
C.petById, C.trailById, C.ribbonById = index(C.pets), index(C.trails), index(C.ribbons)
C.auraById, C.styleById, C.itemById = index(C.auras), index(C.styles), index(C.items)
C.lists = { pet = C.pets, trail = C.trails, ribbon = C.ribbons, aura = C.auras, style = C.styles, item = C.items }
local byKind = { pet = C.petById, trail = C.trailById, ribbon = C.ribbonById, aura = C.auraById, style = C.styleById, item = C.itemById }

-- The catalogue entry for a kind and id, or nil.
function C.find(kind: string, id: string): any
	local list = byKind[kind]
	return if list then list[id] else nil
end

-- Cosmetics are worn one per slot; the slot has the kind's name.
C.cosmeticKinds = { "trail", "ribbon", "aura", "style" }
function C.isCosmetic(kind: string): boolean
	return kind == "trail" or kind == "ribbon" or kind == "aura" or kind == "style"
end

-- The two colours a cosmetic is drawn with.
function C.colors(entry: any): { Color3 }
	if entry.colors then return entry.colors end
	local color = entry.color or rgb(255, 255, 255)
	return { color, color:Lerp(rgb(255, 255, 255), 0.5) }
end

return C
