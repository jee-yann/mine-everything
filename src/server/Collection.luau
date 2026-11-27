-- A miner's collection, stored in the profile as `p.col`: pets (one follows at a time), cosmetics
-- (one worn per slot: mining trail, player trail, player aura, pet style), stacked items, Crate Dust,
-- crate guarantee counters and timed boosts. Everything here is server-side and checks its inputs; the
-- client only ever asks. Pets and cosmetics are only for looks.
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes, Recipes = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.Recipes)
local Ores = require(Shared.Ores)
local Http = game:GetService("HttpService")
local Col = {}

local function integer(n, max)
	return type(n) == "number" and n >= 0 and n <= max and n % 1 == 0
end

function Col.new()
	return {
		-- Every miner owns a Pocket Rock; it follows once they equip it.
		pets = { Rock = { l = 1, x = 0, s = 0 } },
		eq = {},
		cos = {},
		items = {},
		dust = 0,
		pity = {},
		boosts = {},
	}
end

-- Refuses anything that isn't a well-formed collection. Ids the game no longer has (from an older
-- version) are allowed here and dropped by Col.migrate.
function Col.valid(col)
	if col == nil then return true end
	if type(col) ~= "table" or type(col.pets) ~= "table" or type(col.eq) ~= "table" or type(col.cos) ~= "table"
		or type(col.items) ~= "table" or not integer(col.dust, 9e15) or type(col.pity) ~= "table" or type(col.boosts) ~= "table" then
		return false
	end
	for id, pet in col.pets do
		if type(id) ~= "string" or type(pet) ~= "table" then return false end
	end
	if #col.eq > 3 then return false end
	for i, id in col.eq do
		if not integer(i, 3) or type(id) ~= "string" or not col.pets[id] then return false end
	end
	for id, owned in col.cos do
		if type(id) ~= "string" or owned ~= true then return false end
	end
	for id, n in col.items do
		if type(id) ~= "string" or not integer(n, 1e6) then return false end
	end
	for id, n in col.pity do
		if type(id) ~= "string" or not integer(n, 1000) then return false end
	end
	for key, at in col.boosts do
		if type(key) ~= "string" or type(at) ~= "number" then return false end
	end
	for _, key in { "trail", "ribbon", "aura", "style", "petAura" } do
		local id = col[key]
		if id ~= nil and type(id) ~= "string" then return false end
	end
	if col.intro ~= nil and type(col.intro) ~= "boolean" then return false end
	return true
end

-- Brings a collection up to date: drops what the game no longer has (pet food, old boosts, retired
-- cosmetics) and keeps one pet out. Safe to run on every load.
function Col.migrate(col)
	for id in col.pets do
		if not C.petById[id] then col.pets[id] = nil end
	end
	for id in col.cos do
		local known = false
		for _, kind in C.cosmeticKinds do
			if C.find(kind, id) then known = true end
		end
		if not known then col.cos[id] = nil end
	end
	for id in col.items do
		if not C.itemById[id] then col.items[id] = nil end
	end
	for id in col.pity do
		if not Geodes.byId[id] then col.pity[id] = nil end
	end
	for key in col.boosts do
		if not C.boosts[key] then col.boosts[key] = nil end
	end
	local lead
	for _, id in col.eq do
		if col.pets[id] then
			lead = id
			break
		end
	end
	col.eq = if lead then { lead } else {}
	col.petAura = nil
	for _, kind in C.cosmeticKinds do
		local id = col[kind]
		if id ~= nil and not (col.cos[id] and C.find(kind, id)) then col[kind] = nil end
	end
end

-- Gives an older save its collection: the pet it already had, and the old First Light pick aura becomes
-- the Comet Trail it was replaced by.
function Col.upgrade(p)
	if p.col then
		Col.migrate(p.col)
		return
	end
	local col = Col.new()
	if p.drake then col.pets.Drake = { l = 1, x = 0, s = 0 } end
	col.eq = if p.pet == "Drake" and p.drake then { "Drake" } elseif p.pet == "Rock" then { "Rock" } else {}
	local hadAura = p.levels and (p.levels.Speed > 1 or p.levels.Power > 1 or p.levels.Capacity > 1)
	if hadAura then
		col.cos.Comet = true
		col.intro = true
		if not p.auraOff then col.trail = "Comet" end
	end
	p.col = col
end

function Col.copy(col)
	local out = table.clone(col)
	out.pets = {}
	for id, pet in col.pets do
		out.pets[id] = table.clone(pet)
	end
	out.eq, out.cos, out.items, out.pity, out.boosts = table.clone(col.eq), table.clone(col.cos), table.clone(col.items),
		table.clone(col.pity), table.clone(col.boosts)
	return out
end

-- The replicated form (the Collection attribute). Expired boosts are dropped.
function Col.encode(col, now)
	for key, at in col.boosts do
		if at <= now then col.boosts[key] = nil end
	end
	return Http:JSONEncode(col)
end

function Col.owns(col, kind, id)
	if kind == "pet" then return col.pets[id] ~= nil end
	if C.isCosmetic(kind) then return col.cos[id] == true end
	return (col.items[id] or 0) > 0
end

-- Adds a reward. A pet or cosmetic already owned becomes Crate Dust. Returns what happened, for the reveal.
function Col.grant(col, reward)
	local entry = C.find(reward.kind, reward.id)
	local count = reward.count or 1
	local dust = C.rarities[entry.rarity].dust
	if reward.kind == "pet" then
		if col.pets[reward.id] then
			col.dust += dust
			return { dust = dust }
		end
		col.pets[reward.id] = { l = 1, x = 0, s = 0 }
		return { new = true }
	elseif C.isCosmetic(reward.kind) then
		if col.cos[reward.id] then
			col.dust += dust
			return { dust = dust }
		end
		col.cos[reward.id] = true
		return { new = true }
	end
	col.items[reward.id] = (col.items[reward.id] or 0) + count
	return { count = count }
end

-- Opens a crate. `paid` spends gems from the profile; otherwise one of the free crates in the
-- inventory is used. Returns the reward and its result, or nil and why not.
function Col.open(p, geodeId, paid, rng)
	local geode, col = Geodes.byId[geodeId], p.col
	if not geode then return nil, "Unknown crate" end
	if paid then
		if not geode.price then return nil, geode.name .. " can't be bought" end
		if p.gems < geode.price then return nil, "Not enough gems" end
		p.gems -= geode.price
	else
		local item = geodeId .. "Geode"
		if (col.items[item] or 0) < 1 then return nil, "You have no " .. geode.name end
		col.items[item] -= 1
		if col.items[item] == 0 then col.items[item] = nil end
	end
	local reward = Geodes.roll(geode, rng, col.pity[geodeId])
	if geode.pity then
		col.pity[geodeId] = if Geodes.rank(reward) >= geode.pity.rank then 0 else (col.pity[geodeId] or 0) + 1
	end
	return reward, Col.grant(col, reward)
end

function Col.craft(p, recipeId)
	local recipe, col = Recipes.byId[recipeId], p.col
	if not recipe then return nil, "Unknown recipe" end
	for name, need in recipe.ores or {} do
		if (p.bag[name] or 0) < need then return nil, "Need " .. (need - (p.bag[name] or 0)) .. " more " .. name end
	end
	if (recipe.gems or 0) > p.gems then return nil, "Need " .. (recipe.gems - p.gems) .. " more gems" end
	if (recipe.dust or 0) > col.dust then return nil, "Need " .. (recipe.dust - col.dust) .. " more Crate Dust" end
	local give = recipe.give
	if give.kind ~= "item" and Col.owns(col, give.kind, give.id) then return nil, "You already own this" end
	return recipe, nil
end

-- Equips a pet (it replaces the one out) or puts it away (false). One pet follows at a time.
function Col.equipPet(col, id, on)
	if type(id) ~= "string" or not col.pets[id] then return false end
	if on then
		col.eq = { id }
	elseif col.eq[1] == id then
		col.eq = {}
	end
	return true
end

-- Wears a cosmetic in its slot ("trail", "ribbon", "aura" or "style"), or takes it off with nil.
function Col.wear(col, slot, id)
	if slot ~= "trail" and slot ~= "ribbon" and slot ~= "aura" and slot ~= "style" then return false end
	if id == nil then
		col[slot] = nil
		return true
	end
	if type(id) ~= "string" or not col.cos[id] or not C.find(slot, id) then return false end
	col[slot] = id
	return true
end

-- Starts or extends a timed boost, up to four hours from now.
function Col.boost(col, key, minutes, now)
	local from = math.max(col.boosts[key] or 0, now)
	col.boosts[key] = math.min(from + minutes * 60, now + C.maxBoostMinutes * 60)
end

-- The onboarding gift: one Welcome Crate, given once per miner (after their first workshop upgrade).
function Col.welcome(col)
	if col.intro then return false end
	col.intro = true
	col.items.WelcomeGeode = (col.items.WelcomeGeode or 0) + 1
	return true
end

-- Pass rewards: the Starfall Drake pet and pass cosmetics, added to the collection while a pass is
-- owned. A pass cosmetic is worn the first time it arrives. Returns true when something was added.
function Col.passRewards(col, benefits, wearNew)
	local added = false
	for _, pet in C.pets do
		if pet.pass and benefits[pet.pass] and not col.pets[pet.id] then
			col.pets[pet.id] = { l = 1, x = 0, s = 0 }
			col.eq = { pet.id }
			added = true
		end
	end
	for _, kind in C.cosmeticKinds do
		for _, entry in C.lists[kind] do
			if entry.pass and benefits[entry.pass] and not col.cos[entry.id] then
				col.cos[entry.id] = true
				if wearNew ~= false then col[kind] = entry.id end
				added = true
			end
		end
	end
	return added
end

-- Uses one item: a tonic starts its boost. Crates open with Col.open.
function Col.use(col, id, now)
	local item = C.itemById[id]
	if not item or (col.items[id] or 0) < 1 then return nil, "You have none" end
	if item.kind ~= "boost" then return nil, "Open it from your inventory" end
	Col.boost(col, item.boost, item.minutes, now)
	col.items[id] -= 1
	if col.items[id] == 0 then col.items[id] = nil end
	return item
end

-- Ores a recipe uses, for spending from the bag (the profile's sell code handles purity stacks).
function Col.recipeOres(recipe)
	local out = {}
	for name, n in recipe.ores or {} do
		if Ores.byName[name] then out[name] = n end
	end
	return out
end

return Col
