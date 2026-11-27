-- Analytics for the Creator Dashboard (AnalyticsService). Funnels have to be steps in a fixed order, so
-- only things that always happen in order are funnels; everything else is a one-off milestone:
--   Onboarding funnel  the guided first trip, in the order the guide asks for it (Profile.expeditionStep)
--   "Road to rebirth"  the first run's pick upgrades (Power 2 to 13), then the first Starfall (it needs
--                      the top pick), then the first rebirth
--   "Shop" funnel      one per visit: opened the Shop (or an offer card), asked to buy, bought
--   Milestones         one-off custom events that happen in any order (first ore, first skill, first
--                      crate opened, first job, first daily reward, the Starfall Crater)
--   Gold economy       sales, jobs and gold packs in; upgrades out
-- What a miner has already logged is kept in their profile (p.analytics), so a step is sent once,
-- ever. Saves from before analytics start fully logged, so testers never show up as new players.
-- Nothing is sent from Studio; `Analytics.sent` keeps what would have gone, for the tests.
local AnalyticsService = game:GetService("AnalyticsService")
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local Analytics = { sent = {} }

local onboarding = {
	{ "Joined", function() return true end },
	{ "Finished or skipped the opening", function(p) return p.introSeen == true end },
	{ "Mined a block", function(p) return p.mined > 0 end },
	{ "Sold a pack", function(p) return p.firstTrip.sold == true end },
	{ "Bought an upgrade", function(p, has) return has.upgrade end },
	{ "Back in the mine upgraded", function(p) return p.firstTrip.tried == true end },
}
Analytics.onboarding = onboarding
-- The road to the first rebirth: Power 2 to 13 are bought in order, then Starfall, then the rebirth.
local roadPower, roadSteps = 13, 14
local milestones = {
	{ "Found an ore", function(p) return p.xp > 0 end },
	{ "Learned a skill", function(p) return next(p.skills) ~= nil end },
	{ "Claimed a daily reward", function(p) return (p.stampCount or 0) > 0 end },
	{ "Claimed a job", function(p) return (p.claimedJobs or 0) > 0 end },
	{ "Reached the Starfall Crater", function(p, has) return has.crater end },
}

local function send(method, ...)
	table.insert(Analytics.sent, { method, ... })
	if #Analytics.sent > 200 then table.remove(Analytics.sent, 1) end
	if Run:IsStudio() then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(function() AnalyticsService[method](AnalyticsService, table.unpack(args, 1, args.n)) end)
		if not ok then warn("Analytics", method, err) end
	end)
end

-- A fresh record for a new miner, or a fully logged one for a save from before analytics.
function Analytics.record(fresh)
	if fresh then return { onboarding = 0, road = 0, done = {} } end
	local done = {}
	for _, m in milestones do done[m[1]] = true end
	done["Opened a crate"] = true
	return { onboarding = #onboarding, road = roadSteps, done = done }
end

function Analytics.valid(record)
	if type(record) ~= "table" or type(record.done) ~= "table" then return false end
	for _, key in { "onboarding", "road" } do
		local n = record[key]
		if type(n) ~= "number" or n ~= math.floor(n) or n < 0 or n > 50 then return false end
	end
	for name, flag in record.done do
		if type(name) ~= "string" or #name > 60 or flag ~= true then return false end
	end
	return true
end

-- The furthest onboarding step reached, counting only steps reached in order.
function Analytics.onboardingStep(p, has)
	local reached = 0
	for i, step in onboarding do
		if not step[2](p, has) then break end
		reached = i
	end
	return reached
end

-- Logs whatever the miner has newly reached. `has` carries what Profile works out (upgrade, crater).
function Analytics.progress(player, p, has)
	local a = p.analytics
	if not a then return end
	local reached = Analytics.onboardingStep(p, has)
	for step = a.onboarding + 1, reached do
		send("LogOnboardingFunnelStepEvent", player, step, onboarding[step][1])
	end
	a.onboarding = math.max(a.onboarding, reached)
	if (p.rebirths or 0) == 0 then
		for level = a.road + 2, math.min(p.levels.Power, roadPower) do
			send("LogFunnelStepEvent", player, "Road to rebirth", nil, level - 1, "Power " .. level)
			a.road = level - 1
		end
		if a.road == roadPower - 1 and (p.counts.Starfall or 0) > 0 then
			send("LogFunnelStepEvent", player, "Road to rebirth", nil, roadPower, "Found a Starfall")
			a.road = roadPower
		end
	elseif a.road < roadSteps then
		-- The first rebirth: close the road (a miner who skipped steps can't be filled in honestly).
		send("LogFunnelStepEvent", player, "Road to rebirth", nil, roadSteps, "First rebirth")
		a.road = roadSteps
	end
	for _, m in milestones do
		if not a.done[m[1]] and m[2](p, has) then Analytics.milestone(player, p, m[1]) end
	end
end

function Analytics.milestone(player, p, name)
	local a = p.analytics
	if not a or a.done[name] then return end
	a.done[name] = true
	send("LogCustomEvent", player, name)
end

-- Gold in (flow "Source") or out ("Sink"). `kind` is an AnalyticsEconomyTransactionType name.
function Analytics.gold(player, p, flow, amount, kind, sku)
	if amount <= 0 then return end
	send("LogEconomyEvent", player, Enum.AnalyticsEconomyFlowType[flow], "Gold", math.floor(amount), math.floor(p.gold), kind, sku)
end

-- The Shop funnel: each visit is its own funnel session.
local visits = {}
function Analytics.shopOpened(player)
	local now = os.clock()
	local visit = visits[player]
	if visit and now - visit.at < 5 then return end
	visits[player] = { id = Http:GenerateGUID(false), at = now, step = 1 }
	send("LogFunnelStepEvent", player, "Shop", visits[player].id, 1, "Opened the Shop")
end
function Analytics.shopStep(player, step, sku)
	local visit = visits[player]
	-- Only within a visit (ten minutes of opening the Shop or an offer), and each step once.
	if not visit or os.clock() - visit.at > 600 or visit.step >= step then return end
	visit.step = step
	-- Step names stay the same every visit; which item it was goes in a custom field.
	send("LogFunnelStepEvent", player, "Shop", visit.id, step, if step == 2 then "Asked to buy" else "Bought",
		{ [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = sku })
end
function Analytics.leave(player)
	visits[player] = nil
end

return Analytics
