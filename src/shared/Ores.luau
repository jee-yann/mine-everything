local rgb = Color3.fromRGB
-- GameConfig.Layers supplies each region's per-block odds. `hardness` is the pickaxe Power an
-- ore needs (the stone around it can ask for more), `effort` scales its cutting time, `gem`
-- marks the stones the gem skills apply to, and `secret` ores stay "???" until first mined,
-- with a `hint` about where to look. Ores are listed in progression order; Starfall stays last.
-- Each ore is stored in the mine grid as its own Enum.Material, so `material` must be unique.
local list = {
	{
		name = "Dirt",
		rarity = "Common",
		value = 1,
		xp = 0,
		hardness = 1,
		effort = 0.72,
		material = Enum.Material.Mud,
		color = rgb(151, 98, 65),
		flash = "Dirt",
		host = true,
	},
	{
		name = "Stone",
		host = true,
		rarity = "Common",
		value = 2,
		xp = 0,
		hardness = 1,
		effort = 1,
		material = Enum.Material.Concrete,
		color = rgb(151, 153, 158),
		flash = "Stone",
	},
	{
		name = "Coal",
		rarity = "Common",
		value = 5,
		xp = 3,
		hardness = 1,
		effort = 1.15,
		material = Enum.Material.Asphalt,
		color = rgb(79, 82, 95),
		flash = "Coal seam",
	},
	{
		name = "Pyrite",
		rarity = "Common",
		value = 4,
		xp = 2,
		hardness = 1,
		effort = 1.2,
		material = Enum.Material.Brick,
		color = rgb(214, 182, 96),
		flash = "Fool's gold",
	},
	{
		name = "Copper",
		rarity = "Uncommon",
		value = 12,
		xp = 5,
		hardness = 2,
		effort = 1.4,
		material = Enum.Material.Ground,
		color = rgb(195, 122, 84),
		flash = "Native copper",
	},
	{
		name = "Quartz",
		rarity = "Common",
		value = 10,
		xp = 4,
		hardness = 2,
		effort = 1.3,
		material = Enum.Material.Pebble,
		color = rgb(232, 236, 240),
		flash = "Quartz point",
	},
	{
		name = "Iron",
		rarity = "Uncommon",
		value = 24,
		xp = 7,
		hardness = 3,
		effort = 1.7,
		material = Enum.Material.Limestone,
		color = rgb(172, 187, 199),
		flash = "Iron vein",
	},
	{
		name = "Garnet",
		rarity = "Uncommon",
		value = 45,
		xp = 8,
		hardness = 3,
		effort = 1.8,
		material = Enum.Material.Granite,
		color = rgb(170, 34, 52),
		flash = "Garnet cluster",
		gem = true,
	},
	{
		name = "Silver",
		rarity = "Uncommon",
		value = 60,
		xp = 8,
		hardness = 4,
		effort = 1.9,
		material = Enum.Material.Metal,
		color = rgb(206, 214, 224),
		flash = "Silver wire",
	},
	{
		name = "Gold",
		rarity = "Rare",
		value = 80,
		xp = 9,
		hardness = 4,
		effort = 2.05,
		material = Enum.Material.Sand,
		color = rgb(255, 206, 62),
		flash = "Gold strike!",
	},
	{
		name = "Sunstone",
		rarity = "Epic",
		value = 650,
		xp = 60,
		hardness = 1,
		effort = 1.6,
		material = Enum.Material.Sandstone,
		color = rgb(255, 136, 52),
		flash = "Sunstone!",
		gem = true,
		secret = true,
		hint = "A warm glint, somewhere in the shallow hollow",
	},
	{
		name = "Opal",
		rarity = "Rare",
		value = 190,
		xp = 14,
		hardness = 4,
		effort = 2.2,
		material = Enum.Material.Snow,
		color = rgb(146, 226, 222),
		flash = "Opal fire",
		gem = true,
	},
	{
		name = "Selenite",
		rarity = "Rare",
		value = 170,
		xp = 12,
		hardness = 5,
		effort = 2.2,
		material = Enum.Material.Salt,
		color = rgb(236, 232, 214),
		flash = "Selenite blade",
	},
	{
		name = "Diamond",
		rarity = "Epic",
		value = 260,
		xp = 11,
		hardness = 5,
		effort = 2.5,
		material = Enum.Material.Glacier,
		color = rgb(85, 223, 255),
		flash = "Diamond discovery!",
		gem = true,
	},
	{
		name = "Jade",
		rarity = "Rare",
		value = 340,
		xp = 16,
		hardness = 6,
		effort = 2.5,
		material = Enum.Material.Grass,
		color = rgb(62, 160, 104),
		flash = "Jade nodule",
		gem = true,
	},
	{
		name = "Emerald",
		rarity = "Legendary",
		value = 720,
		xp = 13,
		hardness = 6,
		effort = 3,
		material = Enum.Material.LeafyGrass,
		color = rgb(65, 204, 63),
		flash = "Legendary emerald!",
		gem = true,
	},
	{
		name = "Platinum",
		rarity = "Epic",
		value = 650,
		xp = 18,
		hardness = 7,
		effort = 2.7,
		material = Enum.Material.DiamondPlate,
		color = rgb(196, 204, 214),
		flash = "Platinum plate",
	},
	{
		name = "Lumenite",
		rarity = "Legendary",
		value = 3400,
		xp = 45,
		hardness = 7,
		effort = 3.2,
		material = Enum.Material.Neon,
		color = rgb(120, 255, 214),
		flash = "Lumenite glows!",
		gem = true,
		secret = true,
		hint = "Something shines back among the glowcaps",
	},
	{
		name = "Obsidian",
		rarity = "Rare",
		value = 950,
		xp = 20,
		hardness = 8,
		effort = 2.8,
		material = Enum.Material.Pavement,
		color = rgb(52, 44, 66),
		flash = "Obsidian glass",
		gem = true,
	},
	{
		name = "Amethyst",
		rarity = "Mythic",
		value = 2600,
		xp = 32,
		hardness = 8,
		effort = 3.4,
		material = Enum.Material.Glass,
		color = rgb(154, 74, 219),
		flash = "Amethyst geode",
		gem = true,
		secret = true,
		hint = "Geodes form where the fault runs dark",
	},
	{
		name = "Ruby",
		rarity = "Epic",
		value = 2700,
		xp = 30,
		hardness = 9,
		effort = 3.3,
		material = Enum.Material.ClayRoofTiles,
		color = rgb(224, 30, 72),
		flash = "Ruby!",
		gem = true,
	},
	{
		name = "Mithril",
		rarity = "Epic",
		value = 3300,
		xp = 34,
		hardness = 9,
		effort = 3.4,
		material = Enum.Material.CorrodedMetal,
		color = rgb(168, 210, 236),
		flash = "Mithril lattice",
	},
	{
		name = "Sapphire",
		rarity = "Mythic",
		value = 3600,
		xp = 38,
		hardness = 9,
		effort = 3.75,
		material = Enum.Material.Marble,
		color = rgb(54, 98, 243),
		flash = "Sapphire crystal",
		gem = true,
	},
	{
		name = "Brimstone",
		rarity = "Uncommon",
		value = 2600,
		xp = 26,
		hardness = 11,
		effort = 3,
		material = Enum.Material.Cardboard,
		color = rgb(240, 212, 58),
		flash = "Brimstone crust",
	},
	{
		name = "Aquamarine",
		rarity = "Legendary",
		value = 7200,
		xp = 40,
		hardness = 10,
		effort = 3.8,
		material = Enum.Material.CeramicTiles,
		color = rgb(120, 214, 236),
		flash = "Aquamarine column",
		gem = true,
	},
	{
		name = "Meteorite",
		rarity = "Epic",
		value = 9500,
		xp = 44,
		hardness = 13,
		effort = 4.1,
		material = Enum.Material.RoofShingles,
		color = rgb(122, 112, 104),
		flash = "Meteoric iron",
	},
	{
		name = "Moonstone",
		rarity = "Legendary",
		value = 11000,
		xp = 50,
		hardness = 12,
		effort = 4,
		material = Enum.Material.Plaster,
		color = rgb(206, 220, 255),
		flash = "Moonstone",
		gem = true,
	},
	{
		name = "Emberglass",
		rarity = "Mythic",
		value = 15000,
		xp = 56,
		hardness = 11,
		effort = 4,
		material = Enum.Material.CrackedLava,
		color = rgb(255, 86, 128),
		flash = "Emberglass",
		gem = true,
		secret = true,
		hint = "Hot glass waits in the forge's heart",
	},
	{
		name = "Adamantite",
		rarity = "Legendary",
		value = 26000,
		xp = 70,
		hardness = 13,
		effort = 4.6,
		material = Enum.Material.Leather,
		color = rgb(46, 150, 140),
		flash = "Adamantite",
	},
	{
		name = "Resonite",
		rarity = "Mythic",
		value = 42000,
		xp = 90,
		hardness = 12,
		effort = 4.3,
		material = Enum.Material.Fabric,
		color = rgb(140, 196, 255),
		flash = "Resonite hums",
		gem = true,
		secret = true,
		hint = "A hum carries through the drowned dark",
	},
	{
		name = "Voidshard",
		rarity = "Mythic",
		value = 120000,
		xp = 120,
		hardness = 13,
		effort = 4.9,
		material = Enum.Material.Rubber,
		color = rgb(108, 60, 196),
		flash = "Voidshard",
		gem = true,
		secret = true,
		hint = "Shards of nothing rest in the crater",
	},
	{
		name = "Starfall",
		rarity = "Celestial",
		value = 600000,
		xp = 400,
		hardness = 14,
		effort = 5.5,
		material = Enum.Material.Foil,
		color = rgb(181, 133, 255),
		flash = "Starfall",
		gem = true,
		secret = true,
		hint = "The rarest thing that ever fell, at the very bottom",
	},
}
-- The owner scanner filters ores with one bit each. Ores that existed before the expansion
-- keep their bits; new ores take the next free ones. A 32-bit mask holds at most 32 ores.
local legacyBits = {
	Coal = 2,
	Copper = 3,
	Iron = 4,
	Gold = 5,
	Diamond = 6,
	Emerald = 7,
	Amethyst = 8,
	Sapphire = 9,
	Emberglass = 10,
	Starfall = 11,
}
local byName, byMaterial, visionMask, nextBit = {}, {}, 0, 12
for _, ore in list do
	assert(not byMaterial[ore.material], ore.name .. " shares its grid material")
	if not ore.host then
		local bitIndex = legacyBits[ore.name]
		if not bitIndex then
			bitIndex, nextBit = nextBit, nextBit + 1
		end
		assert(bitIndex < 32, "Too many ores for the scanner mask")
		ore.visionBit = bit32.lshift(1, bitIndex)
		visionMask = bit32.bor(visionMask, ore.visionBit)
	end
	byName[ore.name] = ore
	byMaterial[ore.material] = ore
end
-- Plain stone in each region is stored as that region's stone material.
for _, m in { Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Ice } do
	assert(not byMaterial[m], tostring(m) .. " is an ore material")
	byMaterial[m] = byName.Stone
end

-- Deeper stone cuts slower: a steep climb through the first six grades, then a gentler one.
local function strengthFactor(strength)
	local s = strength or 1
	return 1 + 0.45 * math.min(s - 1, 5) + 0.3 * math.max(s - 6, 0)
end
-- A pick stronger than a block needs cuts it a little faster: 7% per spare Power, up to 28%.
local function surplusFactor(power, required)
	if not power then
		return 1
	end
	return 1 - 0.07 * math.clamp(power - required, 0, 4)
end
local function cutTime(base, ore, strength, charges, temperMultiplier, power)
	local required = math.max(strength or 1, ore.hardness)
	local tempered = (charges or 0) > 0 and required >= 2
	return base * ore.effort * strengthFactor(strength) * surplusFactor(power, required) * (if tempered
		then temperMultiplier or 0.8
		else 1),
		tempered
end
local rarityRank = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Celestial = 7 }
local function carried(player)
	local entries = {}
	for _, ore in list do
		local amount = player:GetAttribute("Held" .. ore.name) or 0
		if amount > 0 then
			table.insert(entries, { ore = ore, amount = amount })
		end
	end
	table.sort(entries, function(a, b)
		if a.ore.rarity ~= b.ore.rarity then
			return rarityRank[a.ore.rarity] > rarityRank[b.ore.rarity]
		end
		if a.amount ~= b.amount then
			return a.amount > b.amount
		end
		return a.ore.value > b.ore.value
	end)
	return entries
end
return {
	list = list,
	byName = byName,
	byMaterial = byMaterial,
	cutTime = cutTime,
	carried = carried,
	visionMask = visionMask,
	rarityRank = rarityRank,
}
