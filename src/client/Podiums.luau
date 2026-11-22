local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Podiums = {}
local function bottom(part)
	local frame, size = part.CFrame, part.Size
	local extent = math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y
		+ math.abs(frame.LookVector.Y) * size.Z
	return frame.Y - extent / 2
end

function Podiums.soleY(model)
	local feet, body, costume = math.huge, math.huge, math.huge
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= 0.99 or part.Name == "HumanoidRootPart" then continue end
		local y = bottom(part)
		if part.Parent == model then
			body = math.min(body, y)
			if part.Name == "LeftFoot" or part.Name == "RightFoot" or part.Name == "Left Leg" or part.Name == "Right Leg" then
				feet = math.min(feet, y)
			end
		else
			costume = math.min(costume, y)
		end
	end
	if feet < math.huge then return feet end
	if body < math.huge then return body end
	if costume < math.huge then return costume end
	local frame, size = model:GetBoundingBox()
	return frame.Y - size.Y / 2
end

local function seatFigure(model, base)
	local offset = base.Position.Y + base.Size.Y / 2 + 0.04 - Podiums.soleY(model)
	if math.abs(offset) > 0.012 then model:PivotTo(model:GetPivot() + Vector3.yAxis * offset) end
end
local function makeFigure(id)
	local player = Players:GetPlayerByUserId(id)
	local char = player and player.Character
	local model
	if char and char:FindFirstChild("Head") then
		local old = char.Archivable
		char.Archivable = true
		model = char:Clone()
		char.Archivable = old
	elseif id > 0 then
		model = Players:CreateHumanoidModelFromUserIdAsync(id)
	end
	if not model then
		return
	end
	for _, v in model:GetDescendants() do
		if
			v:IsA("LuaSourceContainer")
			or v:IsA("BillboardGui")
			or v:IsA("Light")
			or v:IsA("Trail")
			or v:IsA("Sound")
			or v:IsA("ParticleEmitter")
			or v.Name == "Harbor pick"
			or v.Name == "Prospector kit"
			or v.Name == "Head clearance"
			or v:IsA("Tool")
		then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.CanCollide, v.CanTouch, v.CanQuery = false, false, false
			v.LocalTransparencyModifier = 0
			v.Anchored = v.Name == "HumanoidRootPart"
		elseif v:IsA("Motor6D") or v:IsA("AnimationConstraint") then
			v.Transform = CFrame.identity
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	local human = model:FindFirstChildOfClass("Humanoid")
	if not root or not human then
		model:Destroy()
		return
	end
	human.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	human.EvaluateStateMachine = false
	model:ScaleTo(1.45)
	model.Name = "Podium miner"
	return model
end
function Podiums.start(viewer, hud)
	local slots = {}
	local function clear(slot)
		if slot.model then
			slot.model:Destroy()
		end
		slot.model, slot.arm, slot.id, slot.busy = nil, nil, nil, false
		slot.token += 1
	end
	local function fit(slot, id)
		clear(slot)
		slot.id, slot.busy = id, true
		local token = slot.token
		task.spawn(function()
			local ok, model = pcall(makeFigure, id)
			if token ~= slot.token or not slot.base:IsDescendantOf(workspace) then
				if ok and model then
					model:Destroy()
				end
				return
			end
			slot.busy = false
			if not ok or not model then
				slot.retry = os.clock() + 12
				return
			end
			local base = slot.base
			model:PivotTo(
				CFrame.new(base.Position)
					* CFrame.Angles(0, math.rad(if slot.rank == 1 then 0 elseif slot.rank == 2 then -12 else 12), 0)
			)
			model.Parent = base
			seatFigure(model, base)
			slot.settle = 4
			local arm = model:FindFirstChild("RightShoulder", true) or model:FindFirstChild("Right Shoulder", true)
			slot.arm = if arm and (arm:IsA("Motor6D") or arm:IsA("AnimationConstraint")) then arm else nil
			slot.model = model
			local tag = Instance.new("BillboardGui")
			tag.Name, tag.Adornee, tag.Size, tag.StudsOffsetWorldSpace, tag.MaxDistance =
				"Record", model.Head, UDim2.fromOffset(150, 32), Vector3.yAxis * (model.Head.Size.Y / 2 + 0.7), 48
			local label = Instance.new("TextLabel")
			label.Size, label.BackgroundTransparency, label.TextScaled, label.Font =
				UDim2.fromScale(1, 1), 1, true, Enum.Font.FredokaOne
			label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(254, 228, 174), 0.18
			label.Parent, tag.Parent = tag, model
			slot.label = label
		end)
	end
	local clock = 0
	Run.PostSimulation:Connect(function()
		for _, slot in slots do
			if slot.model and slot.settle > 0 then
				seatFigure(slot.model, slot.base)
				slot.settle -= 1
			end
		end
	end)
	Run.PreSimulation:Connect(function(dt)
		if hud.inOpening then
			for _, slot in slots do
				if slot.id then clear(slot) end
			end
			return
		end
		clock += dt
		if clock >= 0.5 then
			clock = 0
			local island = workspace:FindFirstChild("CitrineCove")
			local court = island and island:FindFirstChild("Miners Court", true)
			local root = viewer.Character and viewer.Character:FindFirstChild("HumanoidRootPart")
			for _, key in { "Server", "Global" } do
				local board = court and court:FindFirstChild(key)
				for rank = 1, 3 do
					local k = key .. rank
					local slot = slots[k]
					local base = board and board:FindFirstChild("Podium " .. rank)
					if slot and slot.base ~= base then
						clear(slot)
						slots[k] = nil
						slot = nil
					end
					if base then
						if not slot then
							slot = { base = base, rank = rank, token = 0 }
							slots[k] = slot
						end
						local id = base:GetAttribute("StandingId")
						if not root or (root.Position - base.Position).Magnitude > 125 then
							id = nil
						end
						if
							id
							and (
								slot.id ~= id or (not slot.model and not slot.busy and os.clock() >= (slot.retry or 0))
							)
						then
							fit(slot, id)
						elseif not id and slot.id then
							clear(slot)
						end
						if slot.model and slot.label then
							local name = base:GetAttribute("StandingName") or ""
							local score = base:GetAttribute(
								if key == "Global" then "StandingDepth" else "StandingLevel"
							) or 0
							slot.label.Text = string.format(
								if key == "Global" then "%s  ·  %d blocks" else "%s  ·  Lv %d",
								name,
								score
							)
						end
					end
				end
			end
		end
		for _, slot in slots do
			if slot.arm then
				local angle = os.clock() * 2.1 + slot.rank
				local axes = slot.arm.C0.Rotation
				slot.arm.Transform = axes:Inverse()
					* CFrame.Angles(math.rad(40 + 12 * math.sin(angle)), 0, math.rad(100 + 12 * math.cos(angle * 1.6)))
					* axes
			end
		end
	end)
end
return Podiums
