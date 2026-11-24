local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Profile = require(script.Parent.Profile)
local Field = require(game.ReplicatedStorage.Shared.FieldRewards)
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
		gems = p.gems, stampCount = p.stampCount, stampDay = p.stampDay,
		shiftDay = p.shiftDay, shiftSeconds = p.shiftSeconds, shiftClaims = p.shiftClaims,
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
	}
end

function Data.globalDepths()
	return depthStore():GetSortedAsync(false, 5, 1):GetCurrentPage()
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
	for attempt = 1, 3 do
		local ok, record = pcall(function()
			return getStore():UpdateAsync(session.key, function(old)
				local claimed, reason = Data.claim(old, session.token, os.time())
				detail = reason or detail
				return claimed
			end)
		end)
		if ok and record and record.owner == session.token then
			session.profile, session.writable = record.profile, true
			player:SetAttribute("SaveStatus", "Saving enabled")
			return session
		end
		if ok then
			break
		end
		detail = tostring(record)
		if attempt < 3 then
			task.wait(attempt)
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
	Field.trackShift(session, os.time())
	local snapshot = Data.snapshot(session.profile)
	local depth = Profile.depthRecord(snapshot)
	if not release or depth ~= session.indexedDepth then
		if writeSnapshot(player, session, snapshot, false) then
			-- Finish the ranking update while we still own the profile.
			indexDepth(session, player.UserId, depth)
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
	local ok = session.practice or (session.writable and writeSnapshot(player, session, Data.snapshot(fresh), false))
	if ok then
		session.profile = fresh
		session.shiftAt = os.time()
		if session.writable then
			indexDepth(session, player.UserId, 0)
		end
	end
	session.resetting = nil
	if not ok then
		return false, "Couldn’t save the reset. Try again when saving is available."
	end
	return true, if session.practice then "Practice progress reset." else "Progress reset."
end
return Data
