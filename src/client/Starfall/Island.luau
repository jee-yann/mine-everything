local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local TideFront = require(script.Parent.TideFront)
local FaultField = require(script.Parent.FaultField)
local Outcrop = require(script.Parent.PortalOutcrop)
local clock = require(script.Parent.Timeline)
local Island = { witnessPoint = Outcrop.fork }
Island.__index = Island
local V, CF = Vector3.new, CFrame.new

function Island.new(stage, base, live)
	local set = script.Parent.CoveChronicle:Clone()
	set.Name = "Ancient Citrine Cove"
	set:PivotTo(base)
	local vault = Instance.new("Folder")
	local parcels, changes, trees = {}, {}, {}
	local function schedule(model, opens, closes)
		table.insert(parcels, model)
		table.insert(changes, { at = opens, model = model, show = true })
		table.insert(changes, { at = closes, model = model, show = false })
		model.Parent = vault
	end
	local grove = set["Wind trees"]
	for _, tree in grove:GetChildren() do
		local closes = assert(tonumber(tree.Name:match("^0%.00_([%d%.]+)$")))
		local rest = tree:GetPivot()
		local point = base:PointToObjectSpace(rest.Position)
		local radial = V(point.X, 0, point.Z + 32)
		table.insert(trees, {
			model = tree,
			rest = rest,
			arrival = TideFront.arrival(radial.Magnitude),
			axis = base:VectorToWorldSpace(Vector3.yAxis:Cross(radial.Unit)),
			breaks = closes < 12,
			moving = false,
		})
		schedule(tree, 0, closes)
	end
	grove:Destroy()
	for _, parcel in set:GetChildren() do
		if parcel:IsA("Model") and not parcel.Name:match("_Open sea$") then
			local a, b = parcel.Name:match("^(%d+)_(%d+)_")
			schedule(parcel, assert(tonumber(a)) / 100, assert(tonumber(b)) / 100)
		end
	end
	table.sort(changes, function(a, b)
		return a.at < b.at
	end)
	local coast = Shared:FindFirstChild("TideCoast")
	if coast then
		local ledges = coast:Clone()
		ledges:PivotTo(base * coast:GetPivot())
		ledges.Parent = set
	end
	local hot, weathered = Outcrop.new(false), Outcrop.new(true)
	hot:PivotTo(base)
	local self = setmetatable({
		set = set, stage = stage, base = base, live = live or base, vault = vault,
		changes = changes, parcels = parcels, trees = trees, index = 1, last = -1,
		tide = TideFront.new(stage, base), faults = FaultField.new(stage, base),
		hot = hot, weathered = weathered,
	}, Island)
	local felled = 0
	for i, tree in trees do
		if tree.breaks then
			felled += 1
			if felled % 3 == 1 then
				self.faults:addCanopy(tree, i)
			end
		end
	end
	self:draw(0, false, false)
	return self
end

-- Prepare the completed site offstage while a distant player is watching the
-- blast. Surface players with a streamed cove can use the real architecture.
function Island:prepareReplica()
	if self.replaySite then
		return
	end
	local replica = script.Parent.CoveReplay:Clone()
	replica:PivotTo(self.base)
	self.replaySite, self.replayFloor = replica["Present-day cove"], replica.Present_EditFace
	self.replaySite.Parent, self.replayFloor.Parent = self.vault, self.vault
	replica:Destroy()
end

-- These labels guide the player between shops. The entrance shot photographs
-- the actual site, including instances that finish streaming during the shot.
function Island:maskStationLabels(active)
	if active == (self.labelStream ~= nil) then
		return
	end
	if not active then
		self.labelStream:Disconnect()
		self.labelStream = nil
		for gui, enabled in self.labelStates do
			gui.Enabled = enabled
		end
		self.labelStates = nil
		return
	end
	local states = {}
	self.labelStates = states
	local function mask(gui)
		if gui.Name == "Station name" and gui:IsA("BillboardGui") and states[gui] == nil then
			local site = workspace:FindFirstChild("CitrineCove")
			if site and gui:IsDescendantOf(site) then
				states[gui] = gui.Enabled
				gui.Enabled = false
			end
		end
	end
	self.labelStream = workspace.DescendantAdded:Connect(mask)
	local site = workspace:FindFirstChild("CitrineCove")
	if site then
		for _, gui in site:GetDescendants() do
			mask(gui)
		end
	end
end

function Island:draw(t, modern, showReplica, showWitness)
	self:maskStationLabels(modern == true and not showReplica and showWitness ~= false)
	self.set.Parent = if not modern or showReplica then self.stage else nil
	self.hot.Parent = if not modern and t >= clock.waveLaunch then self.set else nil
	local weatheredFrame = if showReplica then self.base else self.live
	if modern and showWitness ~= false then
		if self.witnessFrame ~= weatheredFrame then
			self.weathered:PivotTo(weatheredFrame)
			self.witnessFrame = weatheredFrame
		end
		self.weathered.Parent = self.stage
	else
		self.weathered.Parent = nil
	end
	if self.modern ~= modern or t < self.last then
		for _, parcel in self.parcels do
			parcel.Parent = self.vault
		end
		self.index = 1
	end
	self.modern, self.last = modern, t
	if modern and showReplica and not self.replaySite then
		-- A direct seek or last-moment streaming change can bypass prewarming.
		self:prepareReplica()
	end
	local replayParent = if modern and showReplica then self.set else self.vault
	if self.replaySite and self.replaySite.Parent ~= replayParent then
		self.replaySite.Parent, self.replayFloor.Parent = replayParent, replayParent
	end
	self.faults:draw(t, not modern)
	self.tide:draw(if modern then -1 else t - clock.waveLaunch)
	if modern then
		return
	end
	while self.index <= #self.changes and self.changes[self.index].at <= t do
		local v = self.changes[self.index]
		v.model.Parent = if v.show then self.set else self.vault
		self.index += 1
	end
	for _, tree in self.trees do
		local age = t - clock.waveLaunch - tree.arrival
		if age >= 0 and age < 1.18 and tree.model.Parent == self.set then
			local tilt = if age < 0.21
				then 0.39 * math.sin(age / 0.21 * math.pi * 0.5)
				else 0.39 * math.exp(-4.8 * (age - 0.21)) * math.cos((age - 0.21) * 8.1)
			if tree.breaks then
				tilt = 1.24 * math.clamp(age / 0.50, 0, 1) ^ 1.4
			end
			tree.model:PivotTo(CF(tree.rest.Position) * CFrame.fromAxisAngle(tree.axis, tilt) * tree.rest.Rotation)
			tree.moving = true
		elseif tree.moving then
			tree.model:PivotTo(tree.rest)
			tree.moving = false
		end
	end
end

function Island:Destroy()
	self:maskStationLabels(false)
	self.tide:Destroy()
	self.faults:Destroy()
	self.hot:Destroy()
	self.weathered:Destroy()
	self.set:Destroy()
	self.vault:Destroy()
end
return Island
