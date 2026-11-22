local rep = game:GetService("ReplicatedStorage")
local config = require(rep.Shared.GameConfig)
local test = game:GetService("StudioTestService")
local mode = rep:GetAttribute("MiningTestMode")
local completed = false
local function finish(result)
	if not completed then
		completed = true
		local marker = if mode == "Swing" then "MINING_SWING_RESULT " else "MINING_PLAYTEST_RESULT "
		print(marker .. result .. " [" .. rep:GetAttribute("MiningTestRun") .. "]")
		test:EndTest(result)
	end
end
task.delay(180, function()
	finish("FAIL: playtest timeout")
end)
local report = Instance.new("RemoteEvent")
local inputTest = mode == "Swing"
report:SetAttribute("CheckSwing", inputTest)
report.Name = "MiningTestReport"
report.Parent = rep
local done = {}
report.OnServerEvent:Connect(function(player, stage, detail)
	local n = rep.EndlessMiningNet
	if inputTest and stage == "respawnOpening" then
		player:LoadCharacterAsync()
	elseif stage == "gateApproach" then
		local char = player.Character
		char.HumanoidRootPart.Anchored = false
		char:PivotTo(CFrame.new(n:GetAttribute("Origin") + Vector3.new(0, 3, 2)))
	elseif stage == "position" then
		local char = player.Character
		local x = if inputTest then 0 elseif player.UserId % 2 == 0 then -4 else 5
		char:PivotTo(CFrame.new(n:GetAttribute("Origin") + Vector3.new(x, 2.5, -2.5 * config.Cell)))
		char.HumanoidRootPart.Anchored = true
	elseif inputTest and stage == "moveOreVision" then
		local root = player.Character.HumanoidRootPart
		root.CFrame += Vector3.xAxis * (24 * config.Cell)
	elseif stage == "depthSample" then
		local root = player.Character.HumanoidRootPart
		root.Anchored = true
		root.CFrame = CFrame.new(n:GetAttribute("Origin") + Vector3.new(-1, 2.5, -18))
	elseif stage == "minedShaft" then
		local origin = n:GetAttribute("Origin")
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.CitrineCove.MineBlocks }
		local lowest
		for x = -config.HallHalfWidth / config.Cell, config.HallHalfWidth / config.Cell - 1 do
			for z = config.HallBack / config.Cell, config.HallFront / config.Cell - 1 do
				local start = origin + Vector3.new((x + 0.5) * config.Cell, 2, (z + 0.5) * config.Cell)
				local hit = workspace:Raycast(start, -Vector3.yAxis * 65, params)
				if hit and (not lowest or hit.Position.Y < lowest.Y) then
					lowest = hit.Position
				end
			end
		end
		if lowest then
			local at = lowest + Vector3.yAxis * 2.5
			player.Character:PivotTo(CFrame.new(at))
			player:SetAttribute("TestShaftDepth", config.depthInBlocks(origin.Y - at.Y))
		end
	elseif stage == "walk" then
		player.Character.HumanoidRootPart.Anchored = false
	elseif stage == "openPage" then
		n.Feedback:FireClient(player, "page", detail)
	elseif stage == "renewalNotice" then
		n.Feedback:FireClient(player, "resetSoon", 30)
	elseif stage == "station" then
		local island = workspace.CitrineCove
		local positions = {
			Sell = island["Shore market"].Sell["Service mat"],
			Gear = island["Shore market"].Upgrades["Service mat"],
			Store = island["Harbor Plaza"].Store.Counter,
			Book = island["Harbor Plaza"].Book.Counter,
			Supplies = island["Harbor Plaza"].Supplies.Counter,
		}
		if positions[detail] then
			player.Character:PivotTo(CFrame.new(positions[detail].Position + Vector3.yAxis * 3))
			player.Character.HumanoidRootPart.Anchored = true
		end
	elseif stage == "closePage" then
		n.Feedback:FireClient(player, "close")
	elseif stage == "readyForPracticeReset" then
		player:SetAttribute("ReadyForPracticeReset", true)
	elseif stage == "passed" then
		done[player] = detail
		local results = {}
		for who, msg in done do
			table.insert(results, who.Name .. " " .. msg)
		end
		if #results == (if inputTest then 1 else 2) then
			finish("PASS " .. table.concat(results, " / "))
		end
	elseif stage == "failed" then
		finish("FAIL " .. player.Name .. " " .. detail)
	end
end)
