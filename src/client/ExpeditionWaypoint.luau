local W = require(script.Parent.Widgets)
local V = Vector3.new

local Waypoint = {}
Waypoint.__index = Waypoint

local arrows = 3
local spacing = 3.7
local arms = {
	CFrame.new(-0.43, 0, 0) * CFrame.Angles(0, -0.68, 0),
	CFrame.new(0.43, 0, 0) * CFrame.Angles(0, 0.68, 0),
}

local function makeChevrons(parent)
	local marks = {}
	for i = 1, arrows * 2 do
		local arm = Instance.new("Part")
		arm.Name = "Trail chevron"
		arm.Size = V(0.28, 0.09, 1.45)
		arm.Anchored, arm.CanCollide, arm.CanTouch, arm.CanQuery, arm.CastShadow = true, false, false, false, false
		arm.Material, arm.Transparency, arm.Parent = Enum.Material.Neon, 1, parent
		marks[i] = arm
	end
	return marks
end

function Waypoint.new(root)
	local anchor = Instance.new("Attachment")
	anchor.Name, anchor.Parent = "First expedition waypoint", workspace.Terrain
	local pin = Instance.new("BillboardGui")
	pin.Name, pin.Size = "Destination", UDim2.fromOffset(154, 56)
	pin.LightInfluence, pin.Enabled, pin.Parent = 0, false, anchor
	local label = W.title(pin, "", 0, 0, 154, 26, 19, W.gold)
	label.Name = "TextLabel"
	W.outlineText(label, 2.3)
	local tip = W.title(pin, "▼", 0, 22, 154, 30, 27, W.gold)
	W.outlineText(tip, 2.3)
	local glow = Instance.new("Highlight")
	glow.Name, glow.DepthMode = "Expedition target", Enum.HighlightDepthMode.Occluded
	glow.FillTransparency, glow.OutlineTransparency = 0.78, 0.12
	glow.Enabled, glow.Parent = false, anchor
	local edge
	if root then
		edge = W.title(root, "➤", 0, 0, 34, 34, 26, W.gold)
		edge.Name, edge.AnchorPoint, edge.Visible = "Expedition direction", Vector2.one * 0.5, false
		W.outlineText(edge, 2.4)
	end
	return setmetatable({ anchor = anchor, pin = pin, label = label, tip = tip, glow = glow, edge = edge }, Waypoint)
end

function Waypoint:clear()
	self.pin.Enabled, self.glow.Enabled, self.glow.Adornee = false, false, nil
	if self.edge then self.edge.Visible = false end
	if self.marks then
		table.clear(self.trailPoints)
		for _, arm in self.marks do arm.Transparency = 1 end
	end
end

function Waypoint:show(position, text, tint, surface, part)
	self.anchor.WorldPosition = position
	self.label.Text, self.label.TextColor3, self.tip.TextColor3 = text, tint, tint
	self.pin.AlwaysOnTop, self.pin.Enabled = surface, true
	self.glow.Adornee, self.glow.Enabled = part, part ~= nil
	self.glow.FillColor, self.glow.OutlineColor = tint, tint
	if self.edge then self.edge.TextColor3 = tint end
end

-- Lead across the actual bridge deck when the player and destination are on opposite banks.
function Waypoint:trail(head)
	local island = workspace:FindFirstChild("CitrineCove")
	local paths = island and island:FindFirstChild("Sand path and bridge")
	local bridge = paths and paths:FindFirstChild("Bridge decking")
	if not bridge then return end
	local target, start = self.anchor.WorldPosition, head.Position
	if math.abs(start.Y - bridge.Position.Y) > 13 then return end
	local b, half = bridge.Position, bridge.Size.Z / 2
	if (start.Z > b.Z - half and target.Z < b.Z - half) or (start.Z < b.Z + half and target.Z > b.Z + half) then
		local sign = if target.Z < b.Z then 1 else -1
		local side = (start.Z - b.Z) * sign
		target = if side > half + 4 then b + Vector3.zAxis * (sign * half) else b - Vector3.zAxis * (sign * (half + 3))
	end
	local flat = V(target.X - start.X, 0, target.Z - start.Z)
	if flat.Magnitude < 6 then return end
	if not self.marks then
		self.marks = makeChevrons(self.anchor)
		self.trailPoints = {}
		self.ground = RaycastParams.new()
		self.ground.FilterType, self.ground.RespectCanCollide = Enum.RaycastFilterType.Include, true
	end
	self.ground.FilterDescendantsInstances = { island }
	local forward = flat.Unit
	-- Sample the walkable surface at guide-update speed. The chevrons can then
	-- travel between samples at render speed without raycasting each frame.
	for i = 1, arrows + 1 do
		local distance = 4 + (i - 1) * spacing
		if distance > flat.Magnitude - 1 then break end
		local hit = workspace:Raycast(start + forward * distance + Vector3.yAxis, -Vector3.yAxis * 14, self.ground)
		if hit and hit.Normal.Y > 0.85 and hit.Position.Y < start.Y - 1.5 then
			local point = hit.Position + hit.Normal * 0.15
			local tangent = forward - hit.Normal * forward:Dot(hit.Normal)
			self.trailPoints[i] = CFrame.lookAt(point, point + tangent, hit.Normal)
		end
	end
end

function Waypoint:draw(camera, motion, aimed)
	if not self.pin.Enabled then return end
	local now = os.clock()
	if self.marks then
		local phase = if motion then (now / 1.15) % 1 else 0
		for i = 1, arrows do
			local from, to = self.trailPoints[i], self.trailPoints[i + 1]
			if from then
				local at = from
				if to and math.abs(to.Y - from.Y) < 1.8 then at = from:Lerp(to, phase) end
				local strength = 0.83
				if motion and (i == 1 or not self.trailPoints[i - 1]) then
					strength *= math.clamp(phase / 0.22, 0, 1)
				end
				if motion and (i == arrows or not to) then
					strength *= math.clamp((1 - phase) / 0.22, 0, 1)
				end
				for j, offset in arms do
					local arm = self.marks[(i - 1) * 2 + j]
					arm.CFrame = at * offset
					arm.Color, arm.Transparency = self.label.TextColor3, 1 - strength
				end
			end
		end
	end
	if self.glow.Adornee then
		-- When the pick is already aimed here its normal mining rim takes over.
		self.glow.OutlineTransparency = if self.glow.Adornee == aimed then 1 else 0.12
	end
	local beat = if motion then (1 - math.cos(now * 4.8)) * 0.5 else 0
	local lift = beat * 0.62
	self.pin.StudsOffsetWorldSpace = V(0, lift, 0)
	if not self.edge or not camera then return end
	local position = self.anchor.WorldPosition
	local screen, inside = camera:WorldToViewportPoint(position)
	self.edge.Visible = not inside
	if inside then return end
	local size = camera.ViewportSize
	local direction = Vector2.new(screen.X - size.X / 2, screen.Y - size.Y / 2)
	if screen.Z <= 0 then
		local localPoint = camera.CFrame:PointToObjectSpace(position)
		-- Directly behind always points sideways; never ask a walking player to look at their feet.
		direction = Vector2.new(if localPoint.X < 0 then -1 else 1, 0)
	end
	if direction.Magnitude < 0.001 then direction = Vector2.yAxis end
	local bounds = self.edge.Parent.AbsoluteSize
	local x = math.max(1, bounds.X * 0.31)
	local y = math.max(1, bounds.Y * 0.26)
	local rim = direction / math.max(math.abs(direction.X) / x, math.abs(direction.Y) / y)
	if motion then rim += direction.Unit * (5 * beat) end
	self.edge.Position = UDim2.new(0.5, rim.X, 0.5, rim.Y)
	self.edge.Rotation = math.deg(math.atan2(direction.Y, direction.X))
end

return Waypoint
