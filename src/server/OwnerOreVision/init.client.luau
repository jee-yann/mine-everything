local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Rep = game:GetService("ReplicatedStorage")
local shared = Rep:WaitForChild("Shared")
local Ores = require(shared:WaitForChild("Ores"))
local Config = require(shared:WaitForChild("GameConfig"))
local net = Rep:WaitForChild("EndlessMiningNet")
local player, gui = Players.LocalPlayer, script.Parent
local scan = gui:WaitForChild("Scan")
local Display = require(script:WaitForChild("Display"))
local location = gui.Parent:WaitForChild("MiningHUD"):WaitForChild("SafeArea"):WaitForChild("Location")

local display, revision
local enabled, session, epoch = false, 0, 0
local mask = Ores.visionMask
local markers = {}
-- A client-only reference for adornments, even when the rock has never streamed in.
local anchor = Instance.new("Part")
anchor.Name, anchor.Size, anchor.Transparency = "Ore vision origin", Vector3.one, 1
anchor.Anchored, anchor.CanCollide, anchor.CanTouch = true, false, false
anchor.CanQuery, anchor.CastShadow = false, false

local function clear()
	for _, box in markers do
		box:Destroy()
	end
	table.clear(markers)
	anchor.Parent = nil
	revision = nil
	epoch += 1
	display.badge.Text = if mask == 0 then "Select an ore" else "Scanning nearby…"
end

local function showNearby(center, hits)
	anchor.Position, anchor.Parent = center, workspace
	local nextMarkers = {}
	local count = 0
	for i = 0, buffer.len(hits) - 1, 4 do
		local ore = Ores.list[buffer.readu8(hits, i + 3)]
		if not bit32.btest(mask, ore.visionBit) then
			continue
		end
		local offset = Vector3.new(buffer.readi8(hits, i), buffer.readi8(hits, i + 1), buffer.readi8(hits, i + 2))
			* Config.Cell
		local at = center + offset
		local box = markers[at]
		if not box then
			box = Instance.new("BoxHandleAdornment")
			box.Adornee, box.Size = anchor, Vector3.one * Config.Cell * 0.55
			box.AlwaysOnTop, box.ZIndex, box.Transparency = true, 1, 0.48
			box.Parent = gui
		end
		box.Name, box.Color3 = ore.name, ore.color:Lerp(Color3.new(1, 1, 1), 0.18)
		box.CFrame = CFrame.new(offset)
		nextMarkers[at] = box
		count += 1
	end
	for at, box in markers do
		if not nextMarkers[at] then
			box:Destroy()
		end
	end
	markers = nextMarkers
	display.badge.Text = string.format("%d nearby · %d-block range", count, Config.OreVisionRadius)
end

local function poll(token)
	while token == session and enabled and mask ~= 0 do
		local character = player.Character
		if character and net:GetAttribute("Ready") then
			local atRequest = epoch
			local ok, nextRevision, center, hits = pcall(scan.InvokeServer, scan, revision)
			if token ~= session then
				return
			end
			if ok and atRequest == epoch and character == player.Character and net:GetAttribute("Ready") then
				if nextRevision then
					showNearby(center, hits)
					revision = nextRevision
				elseif nextRevision == false then
					clear()
				end
			end
		end
		task.wait(0.4)
	end
end

local function restart()
	session += 1
	clear()
	if enabled and mask ~= 0 then
		task.spawn(poll, session)
	end
end
local function toggle()
	enabled = not enabled
	display:enable(enabled)
	restart()
end
local function selectOres(nextMask)
	if mask == nextMask then
		return
	end
	mask = nextMask
	display:selection(mask)
	restart()
end
local function clearStone()
	if not location.Visible then return end
	net.Action:FireServer("OwnerClear")
end
display = Display.new(location, toggle, selectOres, clearStone)
display:selection(mask)
display:enable(false)
player.CharacterRemoving:Connect(clear)
net:GetAttributeChangedSignal("Ready"):Connect(function()
	if not net:GetAttribute("Ready") then
		clear()
	end
end)
Input.InputBegan:Connect(function(key, processed)
	if not processed and not Input:GetFocusedTextBox() and key.KeyCode == Enum.KeyCode.C
		and (Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift)) then
		clearStone()
	end
	if not processed and key.KeyCode == Enum.KeyCode.X and not Input:GetFocusedTextBox() then
		if Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift) then
			display.panel.Visible = not display.panel.Visible
		else
			toggle()
		end
	end
end)
