local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local Upgrades = require(Shared.Upgrades)
local Materials = require(Shared.Materials)
local Expeditions = require(Shared.Expeditions)
local Preferences = require(Shared.Preferences)
local Guide = require(Shared.FieldGuide)
local Skills = require(Shared.Skills)
local Profile = {}

function Profile.new()
	return {
		version = 1,
		introSeen = false,
		firstTrip = {},
		gold = 0,
		levels = { Speed = 1, Power = 1, Capacity = 1 },
		bag = {},
		flares = 0,
		temper = 0,
		dailyClaim = 0,
		mined = 0,
		xp = 0,
		counts = {},
		recentCuts = {},
		earned = {},
		skills = {},
		pet = "",
		petName = "Pebble",
		bestDepth = 0,
		jobs = 0,
		claimedJobs = 0,
		discoveries = {},
		viewed = {},
		preferences = table.clone(Preferences.defaults),
	}
end

local function integer(n, max)
	return type(n) == "number" and n >= 0 and n <= max and n % 1 == 0
end

function Profile.used(p)
	local n = 0
	for _, count in p.bag do
		n += count
	end
	return n
end

function Profile.stat(p, key)
	local base = Upgrades.items[key].values[p.levels[key]]
	return if key == "Capacity" then Skills.capacity(base, p.skills) else base
end

local function ownsUpgrade(p)
	return p.levels.Speed > 1 or p.levels.Power > 1 or p.levels.Capacity > 1
end

function Profile.expeditionStep(p)
	local trip = p.firstTrip
	if trip.skipped then return "Skipped" end
	if p.mined == 0 then return "Dig" end
	if p.xp == 0 then return "Ore" end
	if not trip.sold then return "Sell" end
	if not ownsUpgrade(p) then return "Upgrade" end
	return if trip.tried then "Done" else "Return"
end

-- Existing profiles store five units per depth record block, including saves
-- written by older servers. Keep that storage unit independent of the physical grid.
local savedUnitsPerBlock = 5
function Profile.depthRecord(p)
	return math.floor(p.bestDepth / savedUnitsPerBlock)
end

function Profile.recordDepth(p, blocks)
	if blocks > Profile.depthRecord(p) then
		p.bestDepth = blocks * savedUnitsPerBlock
		return true
	end
	return false
end

function Profile.spill(p)
	local used = Profile.used(p)
	local loss = math.floor(used / 10)
	local left = loss
	for _, ore in Ores.list do
		if left == 0 then
			break
		end
		local stock = p.bag[ore.name] or 0
		local removed = math.min(stock, left)
		if removed > 0 then
			p.bag[ore.name] = if stock > removed then stock - removed else nil
			left -= removed
		end
	end
	return loss
end

-- Refuse incompatible records instead of silently replacing them with defaults.
function Profile.valid(p)
	if type(p) ~= "table" or p.version ~= 1 or type(p.levels) ~= "table" or type(p.bag) ~= "table" then
		return false
	end
	if p.firstTrip ~= nil then
		if type(p.firstTrip) ~= "table" then return false end
		for _, key in { "sold", "tried", "skipped" } do
			if p.firstTrip[key] ~= nil and type(p.firstTrip[key]) ~= "boolean" then return false end
		end
	end
	for _, n in { "gold", "mined", "bestDepth" } do
		if not integer(p[n], 9e15) then
			return false
		end
	end
	if p.levels.Radius ~= nil and (not integer(p.levels.Radius, 8) or p.levels.Radius < 1) then
		return false
	end
	for _, k in Upgrades.order do
		if not integer(p.levels[k], #Upgrades.items[k].values) or p.levels[k] < 1 then
			return false
		end
	end
	for name, n in p.bag do
		if not Ores.byName[name] or not integer(n, 9e15) then
			return false
		end
	end
	if p.xp ~= nil and not integer(p.xp, 9e15) then
		return false
	end
	for _, key in { "flares", "dailyClaim" } do
		if p[key] ~= nil and not integer(p[key], 9e15) then
			return false
		end
	end
	if p.title ~= nil and not (integer(p.title, #Expeditions.ranks) and p.title >= 1) then
		return false
	end
	if p.drake ~= nil and type(p.drake) ~= "boolean" then
		return false
	end
	if p.pet ~= nil and p.pet ~= "" and p.pet ~= "Rock" and not (p.pet == "Drake" and p.drake) then
		return false
	end
	if p.petName ~= nil and (type(p.petName) ~= "string" or #p.petName > 100 or not utf8.len(p.petName)) then
		return false
	end
	if p.counts ~= nil then
		if type(p.counts) ~= "table" then
			return false
		end
		for ore, v in p.counts do
			if not Ores.byName[ore] or not integer(v, 9e15) then
				return false
			end
		end
	end
	if p.recentCuts ~= nil then
		if type(p.recentCuts) ~= "table" or #p.recentCuts > Guide.cutWindow then
			return false
		end
		for i, ore in p.recentCuts do
			if not integer(i, #p.recentCuts) or i < 1 or not Ores.byName[ore] then
				return false
			end
		end
		for i = 1, #p.recentCuts do
			if not p.recentCuts[i] then
				return false
			end
		end
	end
	if p.earned ~= nil then
		if type(p.earned) ~= "table" then
			return false
		end
		for id, value in p.earned do
			if not Guide.storedAwards[id] or value ~= true then
				return false
			end
		end
	end
	if p.claimedJobs ~= nil and not integer(p.claimedJobs, 2 ^ #Expeditions.jobs - 1) then
		return false
	end
	if p.skills ~= nil then
		if type(p.skills) ~= "table" then
			return false
		end
		for id, owned in p.skills do
			if not Guide.byId[id] or owned ~= true then
				return false
			end
		end
	end
	if p.jobs ~= nil and not integer(p.jobs, #Expeditions.jobs) then
		return false
	end
	if p.discoveries ~= nil then
		if type(p.discoveries) ~= "table" then
			return false
		end
		for name, seen in p.discoveries do
			if not Ores.byName[name] or seen ~= true then
				return false
			end
		end
	end
	if p.viewed ~= nil then
		if type(p.viewed) ~= "table" then
			return false
		end
		for key, value in p.viewed do
			if type(key) ~= "string" or value ~= true then
				return false
			end
		end
	end
	if p.preferences ~= nil then
		if type(p.preferences) ~= "table" then
			return false
		end
		for key, value in p.preferences do
			if not Preferences.valid(key, value) then
				return false
			end
		end
	end
	return (p.temper == nil or integer(p.temper, Materials.temperCharges + Skills.bonus(p.skills, "charges")))
		and Profile.used(p) <= Profile.stat(p, "Capacity")
end

function Profile.upgradeSave(p)
	-- Profiles predating the opening belong to returning players.
	if p.introSeen == nil then p.introSeen = true end
	if p.firstTrip == nil then p.firstTrip = { skipped = true } end
	local beforeSupplies = p.flares == nil
	p.flares, p.temper, p.dailyClaim = p.flares or 0, p.temper or 0, p.dailyClaim or 0
	-- Repay retired area upgrades once, using their original workshop prices.
	for level = 1, (p.levels.Radius or 1) - 1 do
		p.gold += math.floor(24 * 2.5 ^ (level - 1) + 0.5)
	end
	p.levels.Radius = nil
	if p.xp == nil then
		p.xp = 0
		for name, count in p.bag do
			p.xp += Ores.byName[name].xp * count
		end
	end
	p.viewed = p.viewed or {}
	p.skills = p.skills or {}
	if p.counts == nil then
		-- Earlier fields measured records in four-stud blocks.
		p.bestDepth = math.floor(p.bestDepth / 4) * savedUnitsPerBlock
		p.counts = table.clone(p.bag)
	end
	p.pet, p.petName = p.pet or "", p.petName or "Pebble"
	p.preferences = p.preferences or {}
	for key, value in Preferences.defaults do
		if p.preferences[key] == nil then
			p.preferences[key] = value
		end
	end
	p.jobs = p.jobs or 0
	p.claimedJobs = p.claimedJobs or (2 ^ p.jobs - 1)
	p.recentCuts = p.recentCuts or {}
	p.earned = p.earned or {}
	p.discoveries = p.discoveries or {}
	for _, id in { "PickUpgrade", "Branch", "Shifts" } do
		local award = Guide.awardsById[id]
		if Guide.progress(p, award) == award.goal then
			p.earned[id] = true
		end
	end
	if p.petName ~= "Pebble" then
		p.earned.PetName = true
	end
	for name, amount in p.counts do
		if amount > 0 then
			p.discoveries[name] = true
		end
	end
	if beforeSupplies then
		for name, amount in p.bag do
			if amount > 0 then
				p.discoveries[name] = true
			end
		end
	end
	return p
end

function Profile.markViewed(p, page, id)
	if type(id) ~= "string" then
		return false
	end
	if page == "Book" then
		if not p.discoveries[id] then
			return false
		end
	elseif page == "Achievements" then
		local award = Guide.awardsById[id]
		if not award or Guide.progress(p, award) < award.goal then
			return false
		end
	else
		return false
	end
	local key = page .. id
	if p.viewed[key] then
		return false
	end
	p.viewed[key] = true
	return true
end

function Profile.unlock(p, id)
	if p.earned[id] then
		return nil
	end
	p.earned[id] = true
	return Guide.awardsById[id].name
end
function Profile.learn(p, id)
	local node = Guide.byId[id]
	if not node or p.skills[id] or not Skills.ready(node, p.skills) or Guide.points(p.xp, p.skills) < 1 then
		return false
	end
	p.skills[id] = true
	local award = Guide.awardsById.Branch
	return true, if Guide.progress(p, award) == award.goal then Profile.unlock(p, award.id) else nil
end
function Profile.equipTitle(p, id)
	if not integer(id, #Expeditions.ranks) or id < 1 or Expeditions.ranks[id].level > Expeditions.level(p.xp) then
		return false
	end
	p.title = id
	return true
end
function Profile.recordCut(p, name, depth)
	local ore = Ores.byName[name]
	local xp = Skills.oreXP(ore, p.skills, not p.discoveries[name], depth or 0)
	p.discoveries[name] = true
	p.bag[name] = (p.bag[name] or 0) + 1
	p.counts[name] = (p.counts[name] or 0) + 1
	p.mined += 1
	if ownsUpgrade(p) then p.firstTrip.tried = true end
	p.xp += xp
	if #p.recentCuts == Guide.cutWindow then
		table.remove(p.recentCuts, 1)
	end
	table.insert(p.recentCuts, name)
	local unlocked = {}
	for _, award in Guide.achievements do
		if award.ore then
			if award.ore == name and p.counts[name] == award.goal then
				table.insert(unlocked, award.name)
			end
		elseif award.sequence and not p.earned[award.id] and Guide.progress(p, award) == award.goal then
			p.earned[award.id] = true
			table.insert(unlocked, award.name)
		end
	end
	return unlocked
end

function Profile.claimJob(p, i)
	if not integer(i, #Expeditions.jobs) or i < 1 then
		return nil
	end
	local job = Expeditions.jobs[i]
	if Expeditions.jobClaimed(p.claimedJobs, i) or p.mined < job.goal then
		return nil
	end
	p.claimedJobs = bit32.bor(p.claimedJobs, bit32.lshift(1, i - 1))
	p.jobs += 1
	p.gold += job.reward
	return job, if p.jobs == #Expeditions.jobs then Profile.unlock(p, "Shifts") else nil
end

function Profile.value(bag)
	local amount = 0
	for name, n in bag do
		amount += Ores.byName[name].value * n
	end
	return amount
end

function Profile.sell(p, multiplier, selectedOre, portion)
	if selectedOre ~= nil or portion ~= nil then
		if type(selectedOre) ~= "string" or not Ores.byName[selectedOre] then
			return nil
		end
		if portion ~= "Stack" then
			if type(portion) ~= "number" or portion < 1 or portion % 1 ~= 0 then
				return nil
			end
			if portion > (p.bag[selectedOre] or 0) then
				return 0, nil, 0
			end
		end
	end
	local value, quantity, oreOnly = 0, 0, true
	for name, count in p.bag do
		if selectedOre == nil or selectedOre == name then
			local sold = if type(portion) == "number" then portion else count
			local ore = Ores.byName[name]
			value += sold * ore.value
			quantity += sold
			if sold > 0 and ore.host then
				oreOnly = false
			end
			p.bag[name] = if count > sold then count - sold else nil
		end
	end
	local amount = value * (multiplier or 1)
	if quantity > 0 then p.firstTrip.sold = true end
	p.gold += amount
	local award = if quantity > 0 and oreOnly and Profile.used(p) == 0 then Profile.unlock(p, "CleanSale") else nil
	return amount, award, quantity
end

function Profile.buy(p, key)
	local item = Upgrades.items[key]
	if not item then
		return false, "Unknown upgrade"
	end
	local price = Upgrades.price(key, p.levels[key])
	if not price then
		return false, "Already at maximum level"
	end
	if p.gold < price then
		return false, "Need " .. (price - p.gold) .. " more gold"
	end
	p.gold -= price
	p.levels[key] += 1
	return true, (item.label or key) .. " upgraded!", if key == "Power" then Profile.unlock(p, "PickUpgrade") else nil
end
function Profile.buySupply(p, key)
	local item = Materials.supplies[key]
	if not item then
		return false, "Unknown supply"
	end
	if key == "Temper" and p.temper > 0 then
		return false, "Your pick is already tempered"
	end
	local name, count = Materials.missing(item.recipe, p.bag)
	if name then
		return false, string.format("Bring %d more %s to Field Supplies", count, name)
	end
	Materials.consume(item.recipe, p.bag)
	if key == "Flare" then
		p.flares += 1
		return true, "Flare packed • use it from Inventory → Supplies"
	end
	p.temper = Materials.temperCharges + Skills.bonus(p.skills, "charges")
	return true, string.format("Pick tempered for %d hard blocks", p.temper)
end
function Profile.deliver(p, day, requestedDay)
	if day ~= requestedDay or p.dailyClaim >= day then
		return false
	end
	local order = Materials.daily(day)
	if Materials.missing(order.recipe, p.bag) then
		return false
	end
	Materials.consume(order.recipe, p.bag)
	p.dailyClaim = day
	p.gold += order.gold
	p.flares += if p.skills.SupplyRunner then 2 else 1
	return true
end
return Profile
