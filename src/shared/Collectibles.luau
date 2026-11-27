--!strict
-- Everything a miner can collect: rarities, cosmetics and items. Cosmetics are purely for looks; only
-- tonics and passes change play. Crate reward pools and odds live in Shared.Geodes.
--
-- Cosmetic kinds, each worn in its own slot:
--   trail   mining trail: colours the pickaxe's swing and sparks
--   ribbon  player trail: a ribbon behind the miner as they walk
--   aura    player aura: particles around the miner
local rgb = Color3.fromRGB
local C = {}

C.rarities = {
	Common = { rank = 1, color = rgb(200, 206, 222), gold = 2 },
	Uncommon = { rank = 2, color = rgb(110, 230, 120), gold = 4 },
	Rare = { rank = 3, color = rgb(90, 190, 255), gold = 8 },
	Epic = { rank = 4, color = rgb(200, 130, 255), gold = 15 },
	Legendary = { rank = 5, color = rgb(255, 196, 60), gold = 30 },
	Mythic = { rank = 6, color = rgb(255, 96, 140), gold = 60 },
	Exclusive = { rank = 7, color = rgb(110, 240, 230), gold = 0 },
	Limited = { rank = 8, color = rgb(255, 150, 60), gold = 0 },
}
-- `gold` above: a duplicate pays that many minutes of the miner's own earnings.
C.rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive", "Limited" }

-- What each kind is called on screen.
C.kindNames = { trail = "Mining FX", ribbon = "Player FX", aura = "Player FX", item = "Item" }

-- Pets were removed. These stay empty so older saves still load (their pets are dropped).
C.pets = {}
C.petSlots = 0

-- Mining trails follow the pickaxe through each swing and set the colour of its sparks.
C.trails = {
	{ id = "Copper", name = "Copper Spark", rarity = "Common", colors = { rgb(255, 190, 140), rgb(200, 110, 60) } },
	{ id = "Ember", name = "Ember Trail", rarity = "Common", colors = { rgb(255, 196, 90), rgb(255, 92, 40) } },
	{ id = "Frost", name = "Frost Trail", rarity = "Uncommon", colors = { rgb(210, 248, 255), rgb(90, 180, 255) } },
	{ id = "Moss", name = "Moss Trail", rarity = "Uncommon", colors = { rgb(200, 255, 160), rgb(90, 170, 70) } },
	{ id = "Verdant", name = "Verdant Trail", rarity = "Rare", colors = { rgb(190, 255, 150), rgb(40, 190, 110) } },
	{ id = "Sakura", name = "Sakura Trail", rarity = "Rare", colors = { rgb(255, 220, 235), rgb(255, 120, 170) } },
	{ id = "Aurora", name = "Aurora Trail", rarity = "Epic", colors = { rgb(110, 255, 200), rgb(150, 110, 255) } },
	{ id = "Comet", name = "Comet Trail", rarity = "Epic", colors = { rgb(255, 255, 240), rgb(255, 205, 90) } },
	{ id = "Thunder", name = "Thunder Trail", rarity = "Epic", colors = { rgb(255, 255, 160), rgb(120, 160, 255) } },
	{ id = "Solar", name = "Solar Flare", rarity = "Legendary", colors = { rgb(255, 240, 140), rgb(255, 70, 40) } },
	{ id = "Inferno", name = "Inferno Trail", rarity = "Legendary", colors = { rgb(255, 120, 40), rgb(180, 20, 30) } },
	{ id = "Rift", name = "Starfall Rift", rarity = "Mythic", colors = { rgb(236, 222, 255), rgb(150, 90, 255) } },
	{ id = "Galaxy", name = "Galaxy Trail", rarity = "Mythic", colors = { rgb(120, 200, 255), rgb(230, 90, 255) } },
	{ id = "Celestial", name = "Celestial Trail", rarity = "Exclusive", colors = { rgb(255, 236, 160), rgb(110, 240, 230) }, pass = "Everything" },
}

-- Player trails: a ribbon behind the miner as they walk.
C.ribbons = {
	{ id = "Dust", name = "Dust Trail", rarity = "Common", colors = { rgb(230, 215, 190), rgb(170, 150, 120) } },
	{ id = "Mint", name = "Mint Trail", rarity = "Uncommon", colors = { rgb(200, 255, 220), rgb(60, 210, 160) } },
	{ id = "Sunset", name = "Sunset Trail", rarity = "Rare", colors = { rgb(255, 210, 120), rgb(255, 90, 140) } },
	{ id = "Candy", name = "Candy Trail", rarity = "Rare", colors = { rgb(255, 180, 230), rgb(140, 220, 255) } },
	{ id = "EmberRibbon", name = "Blaze Trail", rarity = "Epic", colors = { rgb(255, 200, 90), rgb(255, 60, 30) }, glints = true },
	{ id = "Starlight", name = "Starlight Trail", rarity = "Legendary", colors = { rgb(255, 250, 220), rgb(120, 170, 255) }, glints = true },
	{ id = "AuroraRibbon", name = "Borealis Trail", rarity = "Legendary", colors = { rgb(120, 255, 210), rgb(190, 120, 255) }, glints = true },
	{ id = "Void", name = "Void Trail", rarity = "Mythic", colors = { rgb(180, 120, 255), rgb(30, 20, 60) }, glints = true },
	{ id = "Prism", name = "Prism Trail", rarity = "Exclusive", colors = { rgb(74, 240, 255), rgb(255, 97, 159) }, glints = true, pass = "PrismTrail" },
}

-- Player auras circle the miner.
C.auras = {
	{ id = "Motes", name = "Dust Motes", rarity = "Common", color = rgb(240, 225, 190), look = "nebula" },
	{ id = "Leaves", name = "Leaf Swirl", rarity = "Uncommon", color = rgb(150, 230, 110), look = "ring" },
	{ id = "Sparks", name = "Spark Ring", rarity = "Rare", color = rgb(255, 230, 140), look = "ring" },
	{ id = "Mist", name = "Frost Mist", rarity = "Rare", color = rgb(190, 235, 255), look = "nebula" },
	{ id = "Embers", name = "Ember Halo", rarity = "Epic", color = rgb(255, 130, 60), look = "embers" },
	{ id = "Halo", name = "Celestial Halo", rarity = "Legendary", color = rgb(255, 240, 180), look = "halo" },
	{ id = "Sunburst", name = "Sunburst", rarity = "Legendary", color = rgb(255, 210, 90), look = "embers" },
	{ id = "Nebula", name = "Nebula", rarity = "Mythic", color = rgb(190, 120, 255), look = "nebula" },
	{ id = "FounderHalo", name = "Founder's Halo", rarity = "Limited", color = rgb(255, 170, 70), look = "halo", product = "FounderHalo" },
}

-- Items stack. Tonics last their duration; using another adds to it (up to four hours). Crates are
-- opened from the inventory. Gold items pay minutes of the miner's own earnings when they arrive.
C.items = {
	{ id = "GoldTonic", name = "Gold Tonic", rarity = "Uncommon", kind = "boost", boost = "goldTonic", minutes = 10, detail = "+50% gold from sales for 10 min" },
	{ id = "HasteTonic", name = "Haste Tonic", rarity = "Uncommon", kind = "boost", boost = "speedTonic", minutes = 10, detail = "+20% mining speed for 10 min" },
	{ id = "LuckyBrew", name = "Lucky Brew", rarity = "Rare", kind = "boost", boost = "luck2", minutes = 10, detail = "2× rare-ore luck for 10 min" },
	{ id = "GoldPouch", name = "Gold Pouch", rarity = "Common", kind = "gold", minutes = 10, detail = "10 minutes of your gold earnings" },
	{ id = "GoldSack", name = "Gold Sack", rarity = "Uncommon", kind = "gold", minutes = 30, detail = "30 minutes of your gold earnings" },
	{ id = "GoldChest", name = "Gold Chest", rarity = "Epic", kind = "gold", minutes = 60, detail = "An hour of your gold earnings" },
	{ id = "WelcomeGeode", name = "Welcome Crate", rarity = "Epic", kind = "geode", geode = "Welcome", detail = "A gift to welcome you to Citrine Cove" },
	{ id = "StarfallGeode", name = "Starfall Crate", rarity = "Legendary", kind = "geode", geode = "Starfall", detail = "Open it for a trail, an aura, a tonic or gold" },
}

-- Timed boosts. Luck boosts don't multiply each other.
C.boosts = {
	goldTonic = { name = "Gold Tonic", effect = "gold", amount = 0.5 },
	speedTonic = { name = "Haste Tonic", effect = "speed", amount = 0.2 },
	gold2 = { name = "2× Gold", effect = "goldTimes", amount = 2 },
	luck2 = { name = "2× Luck", effect = "luckTimes", amount = 2 },
	instamine = { name = "Instamine", effect = "instant", amount = 1 },
	autosell = { name = "Auto Sell", effect = "autoSell", amount = 1 },
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
C.petById = {}
C.trailById, C.ribbonById, C.auraById, C.itemById = index(C.trails), index(C.ribbons), index(C.auras), index(C.items)
C.lists = { trail = C.trails, ribbon = C.ribbons, aura = C.auras, item = C.items }
local byKind = { trail = C.trailById, ribbon = C.ribbonById, aura = C.auraById, item = C.itemById }

-- The catalogue entry for a kind and id, or nil.
function C.find(kind: string, id: string): any
	local list = byKind[kind]
	return if list then list[id] else nil
end

-- Cosmetics are worn one per slot; the slot has the kind's name.
C.cosmeticKinds = { "trail", "ribbon", "aura" }
function C.isCosmetic(kind: string): boolean
	return kind == "trail" or kind == "ribbon" or kind == "aura"
end

-- The two colours a cosmetic is drawn with.
function C.colors(entry: any): { Color3 }
	if entry.colors then return entry.colors end
	local color = entry.color or rgb(255, 255, 255)
	return { color, color:Lerp(rgb(255, 255, 255), 0.5) }
end

-- Effects make you better at something, more for rarer ones:
--   Player FX (trails and auras, worn one at a time) give movement speed;
--   Mining FX give mining speed (a cut takes less time), a smaller bonus.
C.speeds = { Common = 2, Uncommon = 4, Rare = 6, Epic = 9, Legendary = 12, Mythic = 16, Exclusive = 16, Limited = 16 }
C.mineSpeeds = { Common = 1, Uncommon = 2, Rare = 3, Epic = 5, Legendary = 7, Mythic = 10, Exclusive = 10, Limited = 10 }
-- Movement speed (percent) a Player FX gives.
function C.speed(kind: string, id: string?): number
	if kind ~= "ribbon" and kind ~= "aura" then return 0 end
	local entry = id and C.find(kind, id)
	return if entry then C.speeds[entry.rarity] or 0 else 0
end
-- Mining speed (percent) a Mining FX gives.
function C.mineSpeed(kind: string, id: string?): number
	if kind ~= "trail" then return 0 end
	local entry = id and C.find(kind, id)
	return if entry then C.mineSpeeds[entry.rarity] or 0 else 0
end
-- The movement speed bonus of the Player FX a collection wears, in percent.
function C.wornSpeed(col: any): number
	return math.max(C.speed("ribbon", col and col.ribbon), C.speed("aura", col and col.aura))
end
-- What an effect is good for, in words: "+9% movement speed" or "+5% mining speed" (nil otherwise).
-- `short` drops the word "movement"/"mining" for small badges.
function C.bonusText(kind: string, id: string?, short: boolean?): string?
	local mine = C.mineSpeed(kind, id)
	if mine > 0 then return "+" .. mine .. "%" .. (if short then "" else " mining speed") end
	local move = C.speed(kind, id)
	if move > 0 then return "+" .. move .. "%" .. (if short then "" else " movement speed") end
	return nil
end
-- Badge colours: green for movement speed, orange for mining speed.
C.bonusColors = { move = rgb(40, 150, 70), mine = rgb(225, 120, 30) }
-- Player FX is one slot: a player trail or an aura, never both.
C.playerFx = { ribbon = true, aura = true }
-- Kept for older callers: the bonus in words.
function C.speedText(kind: string, id: string?, short: boolean?): string?
	return C.bonusText(kind, id, short)
end

-- Words worth colouring wherever they appear: every rarity, and Starfall.
C.keywords = { Starfall = rgb(196, 140, 255) }
for name, rarity in C.rarities do
	C.keywords[name] = rarity.color
end

return C
