-- A miner's collection, stored in the profile as `p.col`: pets (one of each species, with level, XP
-- and stars), cosmetics, stacked items, Geode Dust, geode pity counters and timed boosts. Everything
-- here is server-side and checks its inputs; the client only ever asks.
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
		-- Every miner owns a Pocket Rock; it follows once they equip it, as before.
		pets = { Rock = { l = 1, x = 0, s = 0 } },
		eq = {},
		cos = {},
		items = {},
		dust = 0,
		pity = {},
		boosts = {},
	}
end

-- Refuses anything that isn't a well-formed collection.
function Col.valid(col)
	if col == nil then return true end
	if type(col) ~= "table" or type(col.pets) ~= "table" or type(col.eq) ~= "table" or type(col.cos) ~= "table"
		or type(col.items) ~= "table" or not integer(col.dust, 9e15) or type(col.pity) ~= "table" or type(col.boosts) ~= "table" then
		return false
	end
	for id, pet in col.pets do
		if not C.petById[id] or type(pet) ~= "table" or not integer(pet.l, C.maxPetLevel) or pet.l < 1
			or not integer(pet.x, 9e15) or not integer(pet.s, C.maxStars) then
			return false
		end
	end
	if #col.eq > C.petSlots then return false end
	for i, id in col.eq do
		if not integer(i, C.petSlots) or not col.pets[id] then return false end
	end
	for id, owned in col.cos do
		if owned ~= true or not (C.trailById[id] or C.auraById[id]) then return false end
	end
	for id, n in col.items do
		if not C.itemById[id] or not integer(n, 1e6) then return false end
	end
	for id, n in col.pity do
		if not Geodes.byId[id] or not integer(n, 1000) then return false end
	end
	for key, at in col.boosts do
		if not C.boosts[key] or type(at) ~= "number" then return false end
	end
	for _, key in { "trail", "aura", "petAura" } do
		local id = col[key]
		if id ~= nil and (type(id) ~= "string" or (not C.trailById[id] and not C.auraById[id])) then return false end
	end
	if col.intro ~= nil and type(col.intro) ~= "boolean" then return false end
	return true
end

-- Gives an older save its collection: the pet it already had, and the old First Light pick aura becomes
-- the Comet Trail it was replaced by.
function Col.upgrade(p)
	if p.col then return end
	local col = Col.new()
	if p.drake then col.pets.Drake = { l = 1, x = 0, s = 0 } end
	col.eq = if p.pet == "Drake" and p.drake then { "Drake" } elseif p.pet == "" then {} else { "Rock" }
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
	if kind == "trail" or kind == "aura" then return col.cos[id] == true end
	return (col.items[id] or 0) > 0
end

-- Adds a reward. A pet already owned gains a star (up to three); after that, and for a cosmetic already
-- owned, the duplicate becomes Geode Dust. Returns what actually happened, for the reveal.
function Col.grant(col, reward)
	local entry = C.find(reward.kind, reward.id)
	local count = reward.count or 1
	local dust = C.rarities[entry.rarity].dust
	if reward.kind == "pet" then
		local pet = col.pets[reward.id]
		if not pet then
			col.pets[reward.id] = { l = 1, x = 0, s = 0 }
			if #col.eq < C.petSlots then table.insert(col.eq, reward.id) end
			return { new = true }
		elseif pet.s < C.maxStars then
			pet.s += 1
			return { star = pet.s }
		end
		col.dust += dust
		return { dust = dust }
	elseif reward.kind == "trail" or reward.kind == "aura" then
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

-- Opens a geode. `paid` spends gems from the profile; otherwise one of the free geodes in the
-- inventory is used. Returns the reward and its result, or nil and why not.
function Col.open(p, geodeId, paid, rng)
	local geode, col = Geodes.byId[geodeId], p.col
	if not geode then return nil, "Unknown geode" end
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
	if (recipe.dust or 0) > col.dust then return nil, "Need " .. (recipe.dust - col.dust) .. " more Geode Dust" end
	local give = recipe.give
	if (give.kind == "trail" or give.kind == "aura") and col.cos[give.id] then return nil, "You already own this" end
	if give.kind == "pet" and col.pets[give.id] and col.pets[give.id].s >= C.maxStars then return nil, "This pet has every star" end
	return recipe, nil
end

-- Equips a pet (true) or takes it off (false). At most three are out at once.
function Col.equipPet(col, id, on)
	if type(id) ~= "string" or not col.pets[id] then return false end
	local at = table.find(col.eq, id)
	if on and not at then
		if #col.eq >= C.petSlots then return false end
		table.insert(col.eq, id)
	elseif not on and at then
		table.remove(col.eq, at)
	end
	return true
end

-- Wears a trail or aura (slot "trail", "aura" or "petAura"), or takes it off with nil.
function Col.wear(col, slot, id)
	if slot ~= "trail" and slot ~= "aura" and slot ~= "petAura" then return false end
	if id == nil then
		col[slot] = nil
		return true
	end
	if type(id) ~= "string" or not col.cos[id] then return false end
	if slot == "trail" and not C.trailById[id] then return false end
	if slot ~= "trail" and not C.auraById[id] then return false end
	col[slot] = id
	return true
end

-- Gives every equipped pet `xp`, levelling them up. Returns the pets that levelled.
function Col.petXp(col, xp)
	local levelled = {}
	for _, id in col.eq do
		local pet = col.pets[id]
		pet.x += xp
		while pet.l < C.maxPetLevel and pet.x >= C.petXpFor(pet.l) do
			pet.x -= C.petXpFor(pet.l)
			pet.l += 1
			table.insert(levelled, id)
		end
		if pet.l >= C.maxPetLevel then pet.x = 0 end
	end
	return levelled
end

-- The onboarding gift: one Welcome Geode, given once per miner (after their first workshop upgrade).
function Col.welcome(col)
	if col.intro then return false end
	col.intro = true
	col.items.WelcomeGeode = (col.items.WelcomeGeode or 0) + 1
	return true
end

-- Pass rewards: the Starfall Drake pet and pass trails, added to the collection while a pass is owned.
-- Returns true when something new was added.
function Col.passRewards(col, benefits, trailOn)
	local added = false
	for _, pet in C.pets do
		if pet.pass and benefits[pet.pass] and not col.pets[pet.id] then
			col.pets[pet.id] = { l = 1, x = 0, s = 0 }
			if #col.eq < C.petSlots then table.insert(col.eq, pet.id) end
			added = true
		end
	end
	for _, trail in C.trails do
		if trail.pass and benefits[trail.pass] and not col.cos[trail.id] then
			col.cos[trail.id] = true
			if trailOn ~= false then col.trail = trail.id end
			added = true
		end
	end
	return added
end

-- Starts or extends a timed boost, up to four hours from now.
function Col.boost(col, key, minutes, now)
	local from = math.max(col.boosts[key] or 0, now)
	col.boosts[key] = math.min(from + minutes * 60, now + C.maxBoostMinutes * 60)
end

-- Uses one item: food feeds the equipped pets, a tonic starts its boost.
function Col.use(col, id, now)
	local item = C.itemById[id]
	if not item or (col.items[id] or 0) < 1 then return nil, "You have none" end
	if item.kind == "food" then
		if #col.eq == 0 then return nil, "Equip a pet first" end
		Col.petXp(col, item.petXp)
	elseif item.kind == "boost" then
		Col.boost(col, item.boost, item.minutes, now)
	else
		return nil, "Open it from the Geodes tab"
	end
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
