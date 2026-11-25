local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local Http = game:GetService("HttpService")
local Data = require(script.Parent.DataService)
local Standings = {}

function Standings.top(scores, levels)
	local rows = {}
	for id, entry in scores do
		table.insert(rows, { id = id, name = entry.name, score = entry.score })
	end
	table.sort(rows, function(a, b)
		return a.score > b.score or (a.score == b.score and a.id < b.id)
	end)
	local lines = {}
	for i = 1, math.min(5, #rows) do
		local row = rows[i]
		lines[i] = if levels
			then string.format("%d.   %s     ·     Lv %d", i, row.name, row.score)
			else string.format("%d.   %s     ·     %d blocks", i, row.name, row.score)
	end
	return lines, rows
end

local function draw(board, scores, levels, empty)
	local lines, rows = Standings.top(scores, levels)
	local face = board.Standings.Lettering
	for i = 1, 5 do
		face["Row" .. i].Text = lines[i] or (if i == 1 then empty else "")
	end
	-- The whole list, for the boards each player scrolls.
	local full = {}
	for i = 1, math.min(100, #rows) do
		full[i] = { id = rows[i].id, name = rows[i].name, score = rows[i].score }
	end
	local ok, text = pcall(Http.JSONEncode, Http, full)
	if ok then
		board:SetAttribute(if levels then "RanksLevel" else "RanksDepth", text)
	end
	board:SetAttribute("Notice", empty)
	for i = 1, 3 do
		local podium = board["Podium " .. i]
		local row = rows[i]
		podium:SetAttribute("StandingName", row and row.name)
		podium:SetAttribute("StandingLevel", if levels and row then row.score else nil)
		podium:SetAttribute("StandingDepth", if not levels and row then row.score else nil)
		podium:SetAttribute("StandingId", row and row.id)
	end
end

-- The court has room for two boards, so the global one alternates between the deepest miners
-- and the highest levels across servers.
local function refreshGlobal(board, names, levels)
	local ok, page = pcall(if levels then Data.globalLevels else Data.globalDepths)
	if not ok then
		board.Standings.Lettering.Title.Text = "GLOBAL RECORDS OFFLINE"
		board:SetAttribute("Notice", "Global records are offline. Checking again shortly")
		if not board["Podium 1"]:GetAttribute("StandingId") then
			board.Standings.Lettering.Row1.Text = "Checking again shortly"
		end
		return
	end
	local scores, missing, currentNames = {}, {}, {}
	for _, record in page do
		local id = tonumber(record.key)
		if id and id > 0 then
			local player = Players:GetPlayerByUserId(id)
			currentNames[id] = if player then player.DisplayName else names[id]
			if not currentNames[id] then
				table.insert(missing, id)
			end
			scores[id] = { score = record.value }
		end
	end
	if #missing > 0 then
		for first = 1, #missing, 50 do
			local batch = table.move(missing, first, math.min(first + 49, #missing), 1, {})
			local resolved, users = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, batch)
			if resolved then
				for _, user in users do
					currentNames[user.Id] = user.DisplayName
				end
			end
		end
	end
	for id, row in scores do
		names[id] = currentNames[id]
		row.name = names[id] or ("Miner #" .. id)
	end
	board.Standings.Lettering.Title.Text = if levels then "GLOBAL LEVELS" else "DEEPEST DESCENT"
	draw(board, scores, levels, if levels then "No level records yet" else "No depth records yet")
end

function Standings.start(court)
	local practice = RunService:IsStudio() and game.GameId == 0
	court.Server.Standings.Lettering.Title.Text = "HIGHEST LEVEL"
	if practice then
		court.Global.Standings.Lettering.Title.Text = "PRACTICE DEPTHS"
	else
		task.spawn(function()
			local names, levels = {}, false
			while true do
				-- 20 s per view keeps ordered-store reads well under the request budget.
				refreshGlobal(court.Global, names, levels)
				levels = not levels
				task.wait(20)
			end
		end)
	end
	task.spawn(function()
		while true do
			local levels, depths = {}, {}
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("ProfileReady") then
					levels[player.UserId] = { name = player.DisplayName, score = player:GetAttribute("Level") or 1 }
					if practice and player.leaderstats.Depth.Value > 0 then
						depths[player.UserId] = { name = player.DisplayName, score = player.leaderstats.Depth.Value }
					end
				end
			end
			draw(court.Server, levels, true, "Waiting for miners")
			if practice then
				local showLevels = math.floor(os.clock() / 12) % 2 == 1
				court.Global.Standings.Lettering.Title.Text = if showLevels then "PRACTICE LEVELS" else "PRACTICE DEPTHS"
				if showLevels then
					draw(court.Global, levels, true, "Waiting for miners")
				else
					draw(court.Global, depths, false, "Mine deeper to set a record")
				end
			end
			task.wait(2)
		end
	end)
end
return Standings
