-- A miner's collection, stored in the profile as `p.col`: cosmetics (one worn per slot: mining trail,
-- player trail, player aura), stacked items (crates and tonics), the crate guarantee counter and
-- timed boosts. Everything here is server-side and checks its inputs; the client only ever asks.
-- Cosmetics are only for looks. A duplicate cosmetic pays gold instead.
local Shared = game:GetService("ReplicatedStorage").Shared
local C, Geodes, Earnings = require(Shared.Collectibles), require(Shared.Geodes), require(Shared.Earnings)
local Http = game:GetService("HttpService")
local Col = {}

local function integer(n, max)
	return type(n) == "number" and n >= 0 and n <= max and n % 1 == 0
end

function Col.new()
	return { pets = {}, eq = {}, cos = {}, items = {}, dust = 0, pity = {}, boosts = {} }
end

-- Refuses anything that isn't a well-formed collection. Ids the game no longer has (from an older
-- version: pets, pet styles, other crates) are allowed here and dropped or converted by Col.migrate.
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

-- Brings a collection up to date: drops pets, pet styles, pet food and retired boosts and cosmetics,
-- and turns the old Stone and Crystal crates into Starfall Crates. Safe to run on every load.
function Col.migrate(col)
	col.pets, col.eq = {}, {}
	col.petAura, col.style = nil, nil
	for id in col.cos do
		local known = false
		for _, kind in C.cosmeticKinds do
			if C.find(kind, id) then known = true end
		end
		if not known then col.cos[id] = nil end
	end
	for _, old in { "PebbleGeode", "CrystalGeode" } do
		if col.items[old] then
			col.items.StarfallGeode = (col.items.StarfallGeode or 0) + col.items[old]
			col.items[old] = nil
		end
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
	for _, kind in C.cosmeticKinds do
		local id = col[kind]
		local testing = require(game:GetService("ReplicatedStorage").Shared.GameConfig).AllFxForTesting
		if id ~= nil and not ((col.cos[id] or testing) and C.find(kind, id)) then col[kind] = nil end
	end
	-- Player FX is one slot now: an older save wearing a trail and an aura keeps the trail.
	if col.ribbon and col.aura then col.aura = nil end
end

-- Gives an older save its collection. The old First Light pick aura becomes the Comet Trail it was
-- replaced by.
function Col.upgrade(p)
	if p.col then
		Col.migrate(p.col)
		return
	end
	local col = Col.new()
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
	out.eq, out.cos, out.items, out.pity, out.boosts = {}, table.clone(col.cos), table.clone(col.items),
		table.clone(col.pity), table.clone(col.boosts)
	return out
end

-- The replicated form (the Collection attribute). Expired boosts are dropped.
function Col.encode(col, now)
	for key, at in col.boosts do
		if at <= now then col.boosts[key] = nil end
	end
	-- While every effect is open for playtesting, the client is told so it can offer them all.
	if require(game:GetService("ReplicatedStorage").Shared.GameConfig).AllFxForTesting then
		local shown = table.clone(col)
		shown.allFx = true
		return Http:JSONEncode(shown)
	end
	return Http:JSONEncode(col)
end

function Col.owns(col, kind, id)
	if C.isCosmetic(kind) then return col.cos[id] == true end
	return (col.items[id] or 0) > 0
end

-- Adds a reward to profile `p`. A cosmetic already owned pays minutes of the miner's earnings (more for
-- rarer ones); a gold item pays its minutes. Returns what happened, for the reveal.
function Col.grant(p, reward)
	local col = p.col
	local entry = C.find(reward.kind, reward.id)
	local count = reward.count or 1
	if C.isCosmetic(reward.kind) then
		if col.cos[reward.id] then
			local gold = Earnings.minutes(p, C.rarities[entry.rarity].gold)
			p.gold += gold
			return { gold = gold, duplicate = true }
		end
		col.cos[reward.id] = true
		return { new = true }
	end
	if entry.kind == "gold" then
		local gold = Earnings.minutes(p, entry.minutes) * count
		p.gold += gold
		return { gold = gold }
	end
	col.items[reward.id] = (col.items[reward.id] or 0) + count
	return { count = count }
end

-- Opens one crate from the inventory. Returns the reward and its result, or nil and why not.
function Col.open(p, geodeId, rng)
	local geode, col = Geodes.byId[geodeId], p.col
	if not geode then return nil, "Unknown crate" end
	local item = geodeId .. "Geode"
	if (col.items[item] or 0) < 1 then return nil, "You have no " .. geode.name end
	col.items[item] -= 1
	if col.items[item] == 0 then col.items[item] = nil end
	local reward = Geodes.roll(geode, rng, col.pity[geodeId])
	if geode.pity then
		col.pity[geodeId] = if Geodes.rank(reward) >= geode.pity.rank then 0 else (col.pity[geodeId] or 0) + 1
	end
	return reward, Col.grant(p, reward)
end

-- Wears a cosmetic in its slot ("trail", "ribbon" or "aura"), or takes it off with nil.
function Col.wear(col, slot, id)
	if not C.isCosmetic(slot) then return false end
	if id == nil then
		col[slot] = nil
		return true
	end
	local testing = require(game:GetService("ReplicatedStorage").Shared.GameConfig).AllFxForTesting
	if type(id) ~= "string" or not (col.cos[id] or testing) or not C.find(slot, id) then return false end
	col[slot] = id
	-- Player FX is one slot: a trail takes the aura off, and an aura the trail.
	if slot == "ribbon" then col.aura = nil elseif slot == "aura" then col.ribbon = nil end
	return true
end

-- Starts or extends a timed boost, up to four hours from now.
function Col.boost(col, key, minutes, now)
	local from = math.max(col.boosts[key] or 0, now)
	col.boosts[key] = math.min(from + minutes * 60, now + C.maxBoostMinutes * 60)
end

-- Pass rewards: pass cosmetics, added to the collection while a pass is owned. A pass cosmetic is worn
-- the first time it arrives. Returns true when something was added.
function Col.passRewards(col, benefits, wearNew)
	local added = false
	for _, kind in C.cosmeticKinds do
		for _, entry in C.lists[kind] do
			if entry.pass and benefits[entry.pass] and not col.cos[entry.id] then
				col.cos[entry.id] = true
				if wearNew ~= false then
					col[kind] = entry.id
					if kind == "ribbon" then col.aura = nil elseif kind == "aura" then col.ribbon = nil end
				end
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

return Col
