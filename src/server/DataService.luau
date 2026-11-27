local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Collection = require(script.Parent.Collection)
local Profile = require(script.Parent.Profile)
local Field = require(game.ReplicatedStorage.Shared.FieldRewards)
local Expeditions = require(game.ReplicatedStorage.Shared.Expeditions)
local Data = {}
local store
local function getStore()
	if not store then
		store = DSS:GetDataStore(Config.StoreName, if RunService:IsStudio() then "studio" else "live")
	end
	return store
end

local function depthStore()
	return DSS:GetOrderedDataStore(
		Config.StoreName .. "_DepthBlocks",
		if RunService:IsStudio() then "studio" else "live"
	)
end

function Data.snapshot(p)
	local grades = {}
	for name, stock in p.grades do grades[name] = table.clone(stock) end
	return {
		version = p.version,
		introSeen = p.introSeen,
		firstTrip = table.clone(p.firstTrip),
		gold = p.gold,
		gems = p.gems, stampCount = p.stampCount, stampDay = p.stampDay, stampAt = p.stampAt, giftStart = p.giftStart,
		shiftDay = p.shiftDay, shiftSeconds = p.shiftSeconds, shiftClaims = p.shiftClaims,
		giftDay = p.giftDay, giftSeconds = p.giftSeconds, giftClaims = p.giftClaims,
		hasteCuts = p.hasteCuts, stoneChips = p.stoneChips, pulses = p.pulses,
		oreCompass = p.oreCompass, auraOff = p.auraOff,
		mined = p.mined,
		xp = p.xp,
		title = p.title,
		skills = table.clone(p.skills),
		counts = table.clone(p.counts),
		recentCuts = table.clone(p.recentCuts),
		earned = table.clone(p.earned),
		claimedJobs = p.claimedJobs,
		pet = p.pet,
		drake = p.drake,
		petName = p.petName,
		bestDepth = p.bestDepth,
		rebirths = p.rebirths,
		runStarfalls = p.runStarfalls,
		runTrail = p.runTrail,
		levels = table.clone(p.levels),
		progression = p.progression,
		preferences = table.clone(p.preferences),
		bag = table.clone(p.bag),
		grades = grades,
		bestPurity = table.clone(p.bestPurity),
		flares = p.flares,
		temper = p.temper,
		dailyClaim = p.dailyClaim,
		jobs = p.jobs,
		discoveries = table.clone(p.discoveries),
		viewed = table.clone(p.viewed),
		col = Collection.copy(p.col),
		store = {
			receipts = table.clone(p.store.receipts), order = table.clone(p.store.order), starter = p.store.starter,
			vipAt = p.store.vipAt, testGems = p.store.testGems, limited = if p.store.limited then table.clone(p.store.limited) else nil,
		},
	}
end

local function rebirthStore()
	return DSS:GetOrderedDataStore(Config.StoreName .. "_Rebirths", if RunService:IsStudio() then "studio" else "live")
end
function Data.globalRebirths()
	return rebirthStore():GetSortedAsync(false, 100, 1):GetCurrentPage()
end
local function indexRebirths(session, userId, count)
	-- Miners who never reborn aren't listed; a reset (count 0 after a listing) removes the entry.
	if count == session.indexedRebirths or (count <= 0 and not session.indexedRebirths) then
		return
	end
	local ok, result = pcall(function()
		return rebirthStore():UpdateAsync(tostring(userId), function(previous)
			return if (previous or 0) == count then nil else count
		end)
	end)
	if ok then
		session.indexedRebirths = count
	else
		warn("Could not update global rebirths for", userId, result)
	end
end

function Data.globalDepths()
	return depthStore():GetSortedAsync(false, 100, 1):GetCurrentPage()
end

-- Miner levels share the court's global board with depths, so they get their own ranking.
local function levelStore()
	return DSS:GetOrderedDataStore(Config.StoreName .. "_Levels", if RunService:IsStudio() then "studio" else "live")
end

function Data.globalLevels()
	return levelStore():GetSortedAsync(false, 100, 1):GetCurrentPage()
end

local function indexLevel(session, userId, level)
	if level == session.indexedLevel then
		return
	end
	local ok, result = pcall(function()
		return levelStore():UpdateAsync(tostring(userId), function(previous)
			return if (previous or 0) == level then nil else level
		end)
	end)
	if ok then
		session.indexedLevel = level
	else
		warn("Could not update global level for", userId, result)
	end
end

local function indexDepth(session, userId, blocks)
	if blocks == session.indexedDepth then
		return
	end
	local ok, result = pcall(function()
		return depthStore():UpdateAsync(tostring(userId), function(previous)
			-- The saved profile is authoritative, including a miner who started over.
			return if (previous or 0) == blocks then nil else blocks
		end)
	end)
	if ok then
		session.indexedDepth = blocks
	else
		warn("Could not update global depth for", userId, result)
	end
end

function Data.claim(old, token, now)
	if old ~= nil then
		if type(old) ~= "table" or not Profile.valid(old.profile) then
			return nil, "Unsupported save format"
		end
		if old.owner and old.owner ~= token then
			if type(old.expires) ~= "number" or old.expires > now then
				return nil, "Save open on another server"
			end
		end
	end
	return {
		profile = if old then Profile.upgradeSave(old.profile) else Profile.new(),
		owner = token,
		expires = now + Config.LeaseSeconds,
	}
end

function Data.commit(record, token, snapshot, now, release)
	if type(record) ~= "table" or record.owner ~= token then
		return nil
	end
	if release then
		return { profile = snapshot }
	end
	return { profile = snapshot, owner = token, expires = now + Config.LeaseSeconds }
end

function Data.open(player)
	local session = {
		key = "miner_" .. player.UserId,
		token = Http:GenerateGUID(false),
		profile = Profile.new(),
		writable = false,
		busy = false,
	}
	local detail = "Saving unavailable"
	-- Unpublished local places cannot use DataStores. Skip the network wait.
	if RunService:IsStudio() and (game.GameId == 0 or player.UserId <= 0) then
		session.practice = true
		player:SetAttribute("SaveStatus", "Practice session")
		return session
	end
	-- A miner who rejoins soon after a server crash finds their save still held by that server. Rather
	-- than play the whole visit unsaved, keep asking until its lease runs out (Config.LeaseSeconds).
	local held = "Save open on another server"
	local waitUntil = os.clock() + Config.LeaseSeconds + 20
	local failures = 0
	while player.Parent do
		local reason
		local ok, record = pcall(function()
			return getStore():UpdateAsync(session.key, function(old)
				local claimed, why = Data.claim(old, session.token, os.time())
				reason = why
				return claimed
			end)
		end)
		if ok and record and record.owner == session.token then
			session.profile, session.writable = record.profile, true
			player:SetAttribute("SaveStatus", "Saving enabled")
			return session
		end
		if ok and reason == held and os.clock() < waitUntil then
			detail = held
			player:SetAttribute("SaveStatus", "Waiting for your last server to let go of your save")
			task.wait(10)
		elseif ok then
			detail = reason or detail
			break
		else
			detail = tostring(record)
			failures += 1
			if failures >= 3 then break end
			task.wait(failures)
		end
	end
	warn("Endless Mining opened a temporary session for", player.UserId, detail)
	player:SetAttribute("SaveStatus", "Temporary session • progress unsaved")
	return session
end

local function writeSnapshot(player, session, snapshot, release)
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return getStore():UpdateAsync(session.key, function(record)
				return Data.commit(record, session.token, snapshot, os.time(), release)
			end)
		end)
		if ok then
			if not result then
				session.writable = false
				player:SetAttribute("SaveStatus", "Temporary session • progress unsaved")
				warn("Endless Mining lost save ownership for", player.UserId)
			else
				session.writable = not release
				player:SetAttribute("SaveStatus", "Saving enabled")
			end
			return result ~= nil
		end
		warn("Endless Mining save failed", player.UserId, result)
		player:SetAttribute("SaveStatus", "Save delayed")
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	return false
end

-- Saves now and says whether it worked. A purchase is only reported as granted after this.
function Data.saveNow(player, session)
	if session.practice then return true end
	if not session.writable or session.closing then return false end
	while session.busy do
		task.wait()
	end
	session.busy = true
	local ok = writeSnapshot(player, session, Data.snapshot(session.profile), false)
	session.busy = false
	return ok
end

function Data.save(player, session, release)
	if release then
		session.closing = true
		while session.busy or session.resetting do
			task.wait()
		end
	elseif session.closing or session.busy or session.resetting then
		return
	end
	if not session.writable then
		return
	end
	session.busy = true
	Field.trackGifts(session, os.time())
	local snapshot = Data.snapshot(session.profile)
	local depth = Profile.depthRecord(snapshot)
	if not release or depth ~= session.indexedDepth then
		if writeSnapshot(player, session, snapshot, false) then
			-- Finish the ranking updates while we still own the profile.
			indexDepth(session, player.UserId, depth)
			indexLevel(session, player.UserId, Expeditions.level(snapshot.xp or 0))
			indexRebirths(session, player.UserId, snapshot.rebirths or 0)
		end
	end
	if release and session.writable then
		writeSnapshot(player, session, snapshot, true)
	end
	session.busy = false
end

function Data.resetProgress(player, session)
	if not Config.AllowProgressReset or session.resetting or session.closing then
		return false, "Reset unavailable right now."
	end
	session.resetting = true
	while session.busy do
		task.wait()
	end
	local fresh = Profile.new()
	fresh.introSeen = session.profile.introSeen
	fresh.preferences = table.clone(session.profile.preferences)
	-- Purchase records stay: they stop a retried receipt from paying out twice.
	fresh.store = session.profile.store
	local ok = session.practice or (session.writable and writeSnapshot(player, session, Data.snapshot(fresh), false))
	if ok then
		session.profile = fresh
		session.giftAt = os.time()
		if session.writable then
			indexDepth(session, player.UserId, 0)
			indexLevel(session, player.UserId, 1)
			indexRebirths(session, player.UserId, 0)
		end
	end
	session.resetting = nil
	if not ok then
		return false, "Couldn’t save the reset. Try again when saving is available."
	end
	return true, if session.practice then "Practice progress reset." else "Progress reset."
end
return Data
