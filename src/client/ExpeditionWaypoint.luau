local W = require(script.Parent.Widgets)
local V = Vector3.new

local Waypoint = {}
Waypoint.__index = Waypoint

-- A straight guide from the miner to the target. Everything is placed from the miner's own position
-- each frame, with no route and no raycasts, so it never lags behind or changes its mind.
local count = 5
local outside = { near = 3.6, gap = 4.6, speed = 6, scale = 1.25, start = V(0, -2.35, 0), line = 0.5 }
local inside = { near = 1.6, gap = 1.35, speed = 2.6, scale = 0.6, start = V(0, 1, 0), line = 0.3 }
local arms = {
	CFrame.new(-0.62, 0, 0) * CFrame.Angles(0, -0.64, 0),
	CFrame.new(0.62, 0, 0) * CFrame.Angles(0, 0.64, 0),
}
local dark = Color3.fromRGB(39, 30, 35)

local function bar(parent, name, material)
	local part = Instance.new("Part")
	part.Name, part.Material = name, material
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
	part.Transparency, part.Parent = 1, parent
	return part
end

local function build(self)
	self.marks, self.moving, self.frames = {}, {}, {}
	for i = 1, count do
		local mark = { face = {}, border = {} }
		for arm = 1, 2 do
			mark.border[arm] = bar(self.anchor, "Chevron edge", Enum.Material.SmoothPlastic)
			mark.border[arm].Color = dark
			mark.face[arm] = bar(self.anchor, "Trail chevron", Enum.Material.Neon)
			table.insert(self.moving, mark.border[arm])
			table.insert(self.moving, mark.face[arm])
		end
		self.marks[i] = mark
	end
	local from, to = Instance.new("Attachment"), Instance.new("Attachment")
	from.Name, to.Name = "Guide line start", "Guide line end"
	from.Parent, to.Parent = workspace.Terrain, workspace.Terrain
	local line = Instance.new("Beam")
	line.Name, line.Attachment0, line.Attachment1 = "Guide line", from, to
	line.FaceCamera, line.Segments, line.CurveSize0, line.CurveSize1 = true, 1, 0, 0
	line.LightEmission, line.LightInfluence = 0.5, 0
	line.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.12, 0.62),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	line.Enabled, line.Parent = false, self.anchor
	self.from, self.to, self.line = from, to, line
	self.anchor.Destroying:Once(function()
		from:Destroy()
		to:Destroy()
	end)
end

local function resize(self, style)
	if self.style == style then return end
	self.style = style
	self.tip.TextSize = if style == inside then 42 else 27
	for _, mark in self.marks do
		for arm = 1, 2 do
			mark.border[arm].Size = V(0.66, 0.09, 2.39) * style.scale
			mark.face[arm].Size = V(0.41, 0.12, 2.12) * style.scale
		end
	end
end

function Waypoint.new(root)
	local anchor = Instance.new("Attachment")
	anchor.Name, anchor.Parent = "First expedition waypoint", workspace.Terrain
	local pin = Instance.new("BillboardGui")
	pin.Name, pin.Size = "Destination", UDim2.fromOffset(154, 72)
	pin.LightInfluence, pin.Enabled, pin.Parent = 0, false, anchor
	local label = W.title(pin, "", 0, 0, 154, 26, 19, W.gold)
	label.Name = "TextLabel"
	W.outlineText(label, 2.3)
	local distance = W.title(pin, "", 0, 23, 154, 18, 14, W.white)
	distance.Name = "Distance"
	W.outlineText(distance, 2)
	local tip = W.title(pin, "▼", 0, 38, 154, 30, 27, W.gold)
	W.outlineText(tip, 2.3)
	local glow = Instance.new("Highlight")
	glow.Name, glow.DepthMode = "Expedition target", Enum.HighlightDepthMode.Occluded
	glow.FillTransparency, glow.OutlineTransparency = 0.78, 0.12
	glow.Enabled, glow.Parent = false, anchor
	local edge
	if root then
		edge = W.title(root, "▶", 0, 0, 40, 40, 34, W.gold)
		edge.Name, edge.AnchorPoint, edge.Visible = "Expedition direction", Vector2.one * 0.5, false
		W.outlineText(edge, 2.4)
	end
	return setmetatable({ anchor = anchor, pin = pin, label = label, distance = distance, tip = tip, glow = glow, edge = edge }, Waypoint)
end

local function hide(mark)
	if not mark.visible then return end
	mark.visible = false
	for i = 1, 2 do
		mark.face[i].Transparency, mark.border[i].Transparency = 1, 1
	end
end

function Waypoint:hideTrail()
	if not self.marks then return end
	for _, mark in self.marks do hide(mark) end
	self.line.Enabled, self.aim, self.base = false, nil, nil
end

function Waypoint:clear()
	self.pin.Enabled, self.glow.Enabled, self.glow.Adornee = false, false, nil
	if self.edge then self.edge.Visible = false end
	self:hideTrail()
end

-- `goal` is the thing itself. `position` is where its name floats.
function Waypoint:show(position, text, tint, goal, part)
	self.goal = goal or position
	self.anchor.WorldPosition = position
	self.label.Text, self.label.TextColor3, self.tip.TextColor3 = text, tint, tint
	-- The arrow stays on top, even over a rock that is being mined.
	self.pin.AlwaysOnTop, self.pin.Enabled = true, true
	self.glow.Adornee, self.glow.Enabled = part, part ~= nil
	self.glow.FillColor, self.glow.OutlineColor = tint, tint
	if self.edge then self.edge.TextColor3 = tint end
end

function Waypoint:trail(position, camera, dt, now, motion, underground)
	if not self.marks then build(self) end
	local style = if underground then inside else outside
	resize(self, style)
	-- Only the height is eased, so a jump or a stair does not shake the line.
	local base = position + style.start
	if not self.base or math.abs(self.base - base.Y) > 8 then self.base = base.Y end
	self.base += (base.Y - self.base) * (1 - math.exp(-dt * (if underground then 24 else 10)))
	base = V(base.X, self.base, base.Z)
	local goal = if underground then self.goal else V(self.goal.X, math.max(self.goal.Y + 0.65, math.min(base.Y, self.goal.Y + 2)), self.goal.Z)
	-- A new target swings the line across instead of snapping it.
	self.aim = if self.aim and (self.aim - goal).Magnitude > 0.01 then self.aim:Lerp(goal, 1 - math.exp(-dt * 12)) else goal
	local delta = self.aim - base
	local length = delta.Magnitude
	if length < style.near then
		for _, mark in self.marks do hide(mark) end
		self.line.Enabled = false
		return
	end
	local forward = delta / length
	self.from.WorldPosition, self.to.WorldPosition = base + forward * style.near * 0.6, self.aim
	self.line.Enabled = length > style.near + 1
	self.line.Width0, self.line.Width1 = style.line * 0.6, style.line * 1.5
	self.line.Color = ColorSequence.new(self.label.TextColor3)

	local span = count * style.gap
	local flow = if motion then now * style.speed % style.gap else 0
	local frames, n = self.frames, 0
	-- Neon washes pale colours out, so it gets a deeper shade of the same one.
	local hue, saturation, value = self.label.TextColor3:ToHSV()
	local ink = Color3.fromHSV(hue, math.min(1, saturation * 1.25), value * 0.82)
	for i, mark in self.marks do
		local along = style.near + (i - 1) * style.gap + flow
		local fade = math.min(along - style.near + (if motion then 0 else 1), style.near + span - along, length - along - style.near * 0.3)
		local strength = math.clamp(fade / (style.gap * 0.3), 0, 1)
		local center = base + forward * along
		-- Turned to the camera in the mine, where a target can be overhead or underfoot.
		local up = Vector3.yAxis
		if camera then
			-- Outside, only leaned that way, so a low camera still sees the whole arrow.
			local eye = (camera.CFrame.Position - center).Unit
			up = if underground then eye else up + eye * 0.7
		end
		up -= forward * up:Dot(forward)
		if up.Magnitude < 0.05 then
			up = Vector3.xAxis - forward * forward.X
			if up.Magnitude < 0.05 then up = Vector3.zAxis end
		end
		up = up.Unit
		local at = CFrame.lookAt(center, center + forward, up)
		for arm, offset in arms do
			local placed = at * CFrame.new(offset.Position * style.scale) * offset.Rotation
			frames[n + 1], frames[n + 2] = placed, placed + up * (0.061 * style.scale)
			n += 2
			mark.border[arm].Transparency = 1 - 0.92 * strength
			mark.face[arm].Color, mark.face[arm].Transparency = ink, 1 - strength
		end
		mark.visible = true
	end
	workspace:BulkMoveTo(self.moving, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

-- Where the arrow at the edge of the screen points. Continuous all the way round, so it slides.
local function screenDirection(camera, position)
	local at = camera.CFrame:PointToObjectSpace(position)
	local ahead = math.clamp(-at.Z / math.max(at.Magnitude, 0.001), 0, 1)
	local direction = Vector2.new(at.X, -at.Y * ahead)
	if direction.Magnitude < 0.05 then return Vector2.new(if at.X < 0 then -1 else 1, 0) end
	return direction.Unit
end

function Waypoint:draw(camera, motion, aimed, head, underground, dt)
	if not self.pin.Enabled then return end
	local now = os.clock()
	dt = dt or 1 / 60
	local root = head and head.Parent and (head.AssemblyRootPart or head)
	if root then
		self:trail(root.Position, camera, dt, now, motion, underground)
		local away = (self.goal - root.Position).Magnitude
		self.distance.Visible = not underground and away > 14
		if self.distance.Visible then self.distance.Text = string.format("%d studs", math.round(away)) end
	else
		self:hideTrail()
	end
	if self.glow.Adornee then
		-- When the pick is already aimed here its normal mining rim takes over.
		self.glow.OutlineTransparency = if self.glow.Adornee == aimed then 1 else 0.12
	end
	local beat = if motion then (1 - math.cos(now * 4.8)) * 0.5 else 0
	self.pin.StudsOffsetWorldSpace = V(0, beat * 0.62, 0)
	if not self.edge or not camera then return end
	local position = self.anchor.WorldPosition
	local _, seen = camera:WorldToViewportPoint(position)
	self.edge.Visible = not seen
	if seen then
		self.heading = nil
		return
	end
	local direction = screenDirection(camera, position)
	local angle = math.atan2(direction.Y, direction.X)
	if self.heading then
		local turn = (angle - self.heading + math.pi) % (2 * math.pi) - math.pi
		angle = self.heading + turn * (1 - math.exp(-dt * 16))
	end
	self.heading = angle
	direction = Vector2.new(math.cos(angle), math.sin(angle))
	local bounds = self.edge.Parent.AbsoluteSize
	local x, y = math.max(1, bounds.X * 0.31), math.max(1, bounds.Y * 0.26)
	local rim = direction / math.max(math.abs(direction.X) / x, math.abs(direction.Y) / y)
	if motion then rim += direction * (5 * beat) end
	self.edge.Position = UDim2.new(0.5, rim.X, 0.5, rim.Y)
	self.edge.Rotation = math.deg(angle)
end

return Waypoint
