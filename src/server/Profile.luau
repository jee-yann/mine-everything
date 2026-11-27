local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local Purity = require(Shared.OrePurity)
local miningRandom = Random.new()
local Upgrades = require(Shared.Upgrades)
local Materials = require(Shared.Materials)
local Field = require(Shared.FieldRewards)
local Expeditions = require(Shared.Expeditions)
local Preferences = require(Shared.Preferences)
local Guide = require(Shared.FieldGuide)
local Skills = require(Shared.Skills)
local Rebirth = require(Shared.Rebirth)
local Collection = require(script.Parent.Collection)
local Profile = {}

function Profile.new()
	return {
		version = 1,
		progression = 4,
		introSeen = false,
		firstTrip = {},
		gold = 0,
		gems = 0,
		stampDay = 0,
		stampAt = 0,
		giftStart = 0,
		stampCount = 0,
		shiftDay = 0,
		shiftSeconds = 0,
		shiftClaims = 0,
		giftDay = 0,
		giftSeconds = 0,
		giftClaims = 0,
		hasteCuts = 0,
		stoneChips = 0,
		pulses = 0,
		levels = { Speed = 1, Power = 1, Capacity = 1 },
		bag = {},
		grades = {},
		bestPurity = {},
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
		rebirths = 0,
		runStarfalls = 0,
		jobs = 0,
		claimedJobs = 0,
		discoveries = {},
		viewed = {},
		preferences = table.clone(Preferences.defaults),
		col = Collection.new(),
		store = { receipts = {}, order = {} },
	}
end

-- What the store remembers: granted receipt IDs (so a retried receipt is never paid twice), whether
-- the one-time Starter Pack was claimed, and when VIP's chest was last opened.
local function validStore(store)
	if store == nil then return true end
	if type(store) ~= "table" or type(store.receipts) ~= "table" or type(store.order) ~= "table" then return false end
	for id, done in store.receipts do
		if type(id) ~= "string" or done ~= true then return false end
	end
	for _, id in store.order do
		if type(id) ~= "string" then return false end
	end
	if store.starter ~= nil and type(store.starter) ~= "boolean" then return false end
	if store.vipAt ~= nil and (type(store.vipAt) ~= "number" or store.vipAt < 0) then return false end
	if store.testGems ~= nil and type(store.testGems) ~= "boolean" then return false end
	if store.limited ~= nil then
		if type(store.limited) ~= "table" then return false end
		for key, done in store.limited do
			if type(key) ~= "string" or done ~= true then return false end
		end
	end
	return true
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
	-- `bigPack` is set while the miner owns the Bigger Pack pass. It is never saved.
	return if key == "Capacity" then math.floor(Skills.capacity(base, p.skills) * (if p.bigPack then 1.5 else 1)) else base
end

function Profile.hasUpgrade(p)
	-- Rebirths reset the levels. A reborn miner keeps the aura and does not repeat the first expedition.
	return p.levels.Speed > 1 or p.levels.Power > 1 or p.levels.Capacity > 1 or (p.rebirths or 0) > 0
end

function Profile.expeditionStep(p)
	local trip = p.firstTrip
	if trip.skipped then return "Skipped" end
	if p.mined == 0 then return "Dig" end
	if not trip.sold then
		if p.xp == 0 and Profile.used(p) < Profile.stat(p, "Capacity") then return "Ore" end
		return "Sell"
	end
	if not Profile.hasUpgrade(p) then return "Upgrade" end
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

local function takeStack(p, name, amount)
	local count = p.bag[name] or 0
	local grades = p.grades[name]
	local value = Purity.remove(Ores.byName[name], count, grades, amount, p.skills.Broker)
	if grades and not next(grades) then p.grades[name] = nil end
	p.bag[name] = if count > amount then count - amount else nil
	return value
end

function Profile.consume(p, recipe)
	for name, count in recipe do takeStack(p, name, count) end
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
			takeStack(p, ore.name, removed)
			left -= removed
		end
	end
	return loss
end

-- Legacy profiles can return with a full pre-rebalance bag. This ceiling is for
-- reading saves only; every new cut uses the current workshop and skill capacity.
local oldBackpackSlots = { 36, 80, 170, 360, 760, 1600, 3400, 7200 }

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
	for _, n in { "rebirths", "runStarfalls" } do
		if p[n] ~= nil and not integer(p[n], 9e15) then
			return false
		end
	end
	-- Legacy profiles may omit all of the field rewards.
	-- The shift fields belonged to the old timed rewards. They are kept so older servers can read the save.
	for key, max in { gems = 9e15, stampDay = 9e15, stampCount = #Field.daily, hasteCuts = Field.hasteCuts,
		stoneChips = Field.stoneChips, pulses = 9e15, shiftDay = 9e15, shiftSeconds = 3600, shiftClaims = 3,
		giftDay = 9e15, giftSeconds = 86400, giftClaims = 1000, stampAt = 9e15, giftStart = 9e15 } do
		if p[key] ~= nil and not integer(p[key], max) then return false end
	end
	for _, key in { "oreCompass", "auraOff" } do
		if p[key] ~= nil and type(p[key]) ~= "boolean" then return false end
	end
	if p.levels.Radius ~= nil and (not integer(p.levels.Radius, 8) or p.levels.Radius < 1) then
		return false
	end
	for _, k in Upgrades.order do
		-- Saves from before the 30-level Speed curve (progression 3) may hold up to the old 100.
		local most = if k == "Speed" and (p.progression or 1) < 3 then 100 else #Upgrades.items[k].values
		if not integer(p.levels[k], most) or p.levels[k] < 1 then
			return false
		end
	end
	for name, n in p.bag do
		if not Ores.byName[name] or not integer(n, 9e15) then
			return false
		end
	end
	if p.bestPurity ~= nil then
		if type(p.bestPurity) ~= "table" then return false end
		for name, percent in p.bestPurity do
			local ore = Ores.byName[name]
			if not ore or ore.host or type(percent) ~= "number" or not Purity.valid(percent) then return false end
		end
	end
	if p.grades ~= nil then
		if type(p.grades) ~= "table" then return false end
		for name, stack in p.grades do
			local ore = Ores.byName[name]
			if not ore or ore.host or type(stack) ~= "table" then return false end
			local count = 0
			for grade, n in stack do
				if not Purity.validGrade(grade) or not integer(n, 9e15) or n == 0 then return false end
				if not p.bestPurity or tonumber(grade) > (p.bestPurity[name] or 0) then return false end
				count += n
			end
			if count > (p.bag[name] or 0) then return false end
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
	if not Collection.valid(p.col) or not validStore(p.store) then
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
		-- Ids from an older tree are fine here: Profile.upgradeSave refunds them (Skills.prune).
		for id, owned in p.skills do
			if type(id) ~= "string" or #id > 40 or owned ~= true then
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
	local level = p.levels.Capacity
	local storedCapacity = Skills.capacity(math.max(oldBackpackSlots[level] or 0, Upgrades.items.Capacity.values[level]), p.skills)
	return (p.temper == nil or integer(p.temper, Materials.temperCharges + Skills.bonus(p.skills, "charges")))
		-- Bigger Pack adds half again, and the save may hold a full one.
		and Profile.used(p) <= math.floor(storedCapacity * 1.5)
end

function Profile.upgradeSave(p)
	for _, key in { "gems", "stampDay", "stampCount", "shiftDay", "shiftSeconds", "shiftClaims", "giftDay", "giftSeconds", "giftClaims", "hasteCuts", "stoneChips", "pulses" } do
		p[key] = p[key] or 0
	end
	-- Saves from when rewards followed the UTC day start their wait at that day's midnight.
	p.stampAt = p.stampAt or p.stampDay * 86400
	p.giftStart = p.giftStart or p.giftDay * 86400
	-- Profiles predating the opening belong to returning players.
	if p.introSeen == nil then p.introSeen = true end
	if p.firstTrip == nil then p.firstTrip = { skipped = true } end
	p.grades, p.bestPurity = p.grades or {}, p.bestPurity or {}
	local beforeSupplies = p.flares == nil
	p.flares, p.temper, p.dailyClaim = p.flares or 0, p.temper or 0, p.dailyClaim or 0
	-- Repay retired area upgrades once, using their original workshop prices.
	for level = 1, (p.levels.Radius or 1) - 1 do
		p.gold += math.floor(24 * 2.5 ^ (level - 1) + 0.5)
	end
	p.levels.Radius = nil
	-- Move workshop levels from the short pre-expansion tables onto the long curves.
	if (p.progression or 1) < 2 then
		for _, key in { "Speed", "Capacity" } do
			p.levels[key] = Upgrades.migrateLevel(key, p.levels[key])
		end
		p.progression = 2
	end
	-- The 30-level Speed curve: keep at least the speed they had.
	if p.progression < 3 then
		p.levels.Speed = Upgrades.migrateSpeed(p.levels.Speed)
		p.progression = 3
	end
	-- The smaller Capacity curve: the first level at least as roomy (the biggest old packs shrink to
	-- the new top, 852 slots).
	if p.progression < 4 then
		p.levels.Capacity = Upgrades.migrateCapacity(p.levels.Capacity)
		p.progression = 4
	end
	if p.xp == nil then
		p.xp = 0
		for name, count in p.bag do
			p.xp += Ores.byName[name].xp * count
		end
	end
	p.viewed = p.viewed or {}
	p.skills = p.skills or {}
	p.refunded = Skills.prune(p.skills)
	if #p.refunded == 0 then p.refunded = nil end
	if p.counts == nil then
		-- Earlier fields measured records in four-stud blocks.
		p.bestDepth = math.floor(p.bestDepth / 4) * savedUnitsPerBlock
		p.counts = table.clone(p.bag)
	end
	p.pet, p.petName = p.pet or "", p.petName or "Pebble"
	Collection.upgrade(p)
	p.store = p.store or { receipts = {}, order = {} }
	-- Saves from before rebirths: every Starfall so far belongs to the current run.
	p.rebirths = p.rebirths or 0
	if p.runStarfalls == nil then p.runStarfalls = p.counts.Starfall or 0 end
	p.runTrail = nil -- the retired Starfall trail
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
	elseif page == "Guide" then
		-- One-time guides the miner has followed (the Rebirth button), so they never show again.
		if id ~= "Rebirth" then return false end
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
-- `boost` multiplies the XP of this cut, for mining with a friend.
function Profile.recordCut(p, name, depth, random, boost)
	local ore = Ores.byName[name]
	local units, grade, record = 1, nil, false
	if not ore.host then
		random = random or miningRandom
		grade = Purity.roll(random)
		-- Assayer: some finds roll twice and keep the better. Polish: never under 55%.
		local assay = Skills.bonus(p.skills, "assay")
		if assay > 0 and random:NextInteger(1, 100) <= assay then
			grade = math.max(grade, Purity.roll(random))
		end
		if p.skills.Polish then grade = math.max(grade, 55) end
		local odds = if p.skills.FortuneII then 7 else 10
		if p.skills.Fortune and Profile.used(p) + 1 < Profile.stat(p, "Capacity") and random:NextInteger(1, odds) == 1 then
			units = 2
		end
		local stock = p.grades[name] or {}
		local key = Purity.key(grade)
		stock[key] = (stock[key] or 0) + units
		p.grades[name] = stock
		record = grade > (p.bestPurity[name] or 0)
		if record then p.bestPurity[name] = grade end
	end
	local xp = math.floor(Skills.oreXP(ore, p.skills, (p.bag[name] or 0) == 0, depth or 0, grade) * Rebirth.xpMultiplier(p.rebirths) * (boost or 1) + 0.5)
	if name == Rebirth.requirement.ore then p.runStarfalls += 1 end
	p.discoveries[name] = true
	p.bag[name] = (p.bag[name] or 0) + units
	p.counts[name] = (p.counts[name] or 0) + 1
	p.mined += 1
	if Profile.hasUpgrade(p) then p.firstTrip.tried = true end
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
	return unlocked, grade, units, record
end

-- Starts a new run when the current one has met Rebirth.requirement. Resets the pack, workshop
-- levels and field supplies, keeps some of the gold (Rebirth.keptGold) and everything earned for the
-- miner, and gives Starfall Crates (Rebirth.crates). Returns the new count, the gold kept and the crates.
function Profile.rebirth(p)
	if not Rebirth.ready(p.runStarfalls, p.rebirths) then
		return nil
	end
	local kept = Rebirth.keptGold(p.gold, p.rebirths)
	p.rebirths += 1
	p.runStarfalls = 0
	p.gold = kept
	local crates = Rebirth.crates(p.rebirths)
	p.col.items.StarfallGeode = (p.col.items.StarfallGeode or 0) + crates
	p.bag, p.grades = {}, {}
	p.levels = { Speed = 1, Power = 1, Capacity = 1 }
	p.flares, p.temper = 0, 0
	return p.rebirths, kept, crates
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

-- Collects every finished job. Returns how many, their gold and an award, if any.
function Profile.claimJobs(p)
	local count, gold, award = 0, 0, nil
	for i in Expeditions.jobs do
		local job, earned = Profile.claimJob(p, i)
		if job then
			count += 1
			gold += job.reward
			award = earned or award
		end
	end
	return count, gold, award
end

function Profile.value(bag, grades, broker)
	local amount = 0
	for name, n in bag do
		amount += Purity.quote(Ores.byName[name], n, grades and grades[name], n, broker)
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
			value += takeStack(p, name, sold)
			quantity += sold
			if sold > 0 and ore.host then
				oreOnly = false
			end
		end
	end
	-- Bulk Seller: a big sale at once pays 5% more.
	if p.skills.BulkSeller and quantity >= 50 then multiplier = (multiplier or 1) * 1.05 end
	-- Gold is always whole: passes and boosts can make fractions.
	local amount = math.floor(value * (multiplier or 1) + 0.5)
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
	if (key == "Haste" and p.hasteCuts > 0) or (key == "Chips" and p.stoneChips > 0) then
		return false, "Finish the charges on your pick first"
	elseif key == "Compass" and p.oreCompass then
		return false, "You already have an ore compass"
	end
	local name, count = Materials.missing(item.recipe, p.bag)
	if name then
		return false, string.format("Bring %d more %s to Field Supplies", count, name)
	end
	Profile.consume(p, item.recipe)
	if key == "Haste" then
		p.hasteCuts = Field.hasteCuts
		return true, "Quick-cut wax ready for 12 cuts"
	elseif key == "Chips" then
		p.stoneChips = Field.stoneChips
		return true, "Diamond teeth ready for 6 stone cuts"
	elseif key == "Pulse" then
		p.pulses += 1
		return true, "Cave pulse packed. Use it underground from Supplies."
	elseif key == "Compass" then
		p.oreCompass = true
		return true, "Ore compass crafted. Its marker over your head points to nearby ore."
	end
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
	Profile.consume(p, order.recipe)
	p.dailyClaim = day
	p.gold += order.gold
	-- And Gold Tonics: two with the Supply Runner skill.
	p.col.items.GoldTonic = (p.col.items.GoldTonic or 0) + (if p.skills.SupplyRunner then 2 else 1)
	return true
end
return Profile
