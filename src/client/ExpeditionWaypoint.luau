local W = require(script.Parent.Widgets)
local V = Vector3.new

local Waypoint = {}
Waypoint.__index = Waypoint

local arrowCount, spacing, near = 4, 4.8, 2.8
local arms = {
	CFrame.new(-0.62, 0, 0) * CFrame.Angles(0, -0.64, 0),
	CFrame.new(0.62, 0, 0) * CFrame.Angles(0, 0.64, 0),
}

local function strip(parent, name, size)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Material = name, size, Enum.Material.Neon
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
	part.Transparency, part.Parent = 1, parent
	return part
end

local function makeChevrons(parent)
	local marks = {}
	for i = 1, arrowCount do
		local mark = { face = {}, border = {} }
		for arm = 1, 2 do
			mark.border[arm] = strip(parent, "Chevron edge", V(0.66, 0.09, 2.39))
			mark.border[arm].Material, mark.border[arm].Color = Enum.Material.SmoothPlastic, Color3.fromRGB(39, 30, 35)
			mark.face[arm] = strip(parent, "Trail chevron", V(0.41, 0.12, 2.12))
		end
		marks[i] = mark
	end
	return marks
end

local function hideMark(mark)
	if not mark.visible then return end
	mark.visible = false
	for i = 1, 2 do
		mark.face[i].Transparency, mark.border[i].Transparency = 1, 1
	end
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
	local self = setmetatable({ anchor = anchor, pin = pin, label = label, tip = tip, glow = glow, edge = edge }, Waypoint)
	anchor.Destroying:Once(function()
		if self.addedCrossing then
			self.addedCrossing:Disconnect()
			self.removedCrossing:Disconnect()
		end
	end)
	return self
end

function Waypoint:clear()
	self.pin.Enabled, self.glow.Enabled, self.glow.Adornee = false, false, nil
	if self.edge then self.edge.Visible = false end
	if self.marks then
		for _, mark in self.marks do hideMark(mark) end
	end
end

function Waypoint:show(position, text, tint, surface, part)
	self.destination, self.destinationLabel = position, text
	self.anchor.WorldPosition = position
	self.label.Text, self.label.TextColor3, self.tip.TextColor3 = text, tint, tint
	self.pin.AlwaysOnTop, self.pin.Enabled = surface, true
	self.glow.Adornee, self.glow.Enabled = part, part ~= nil
	self.glow.FillColor, self.glow.OutlineColor = tint, tint
	if self.edge then self.edge.TextColor3 = tint end
end

function Waypoint:placeMark(mark, flat, forward, eyeY, strength, now)
	-- Reuse the sampled ground plane while crossing a small patch. XY
	-- and heading still follow the actual route every rendered frame.
	if not mark.sample or (mark.sample - flat).Magnitude > 0.7 or math.abs(eyeY - mark.eyeY) > 1.5
		or (not mark.hit and now >= mark.retry) then
		mark.sample, mark.eyeY, mark.retry = flat, eyeY, now + 0.25
		local hit = workspace:Raycast(flat + V(0, eyeY + 1, 0), -Vector3.yAxis * 15, self.ground)
		if hit and hit.Normal.Y > 0.77 and hit.Position.Y < eyeY - 1
			and (hit.Position.Y >= self.waterFloor or hit.Instance.Name == "Canal step" or hit.Instance.Name == "Canal landing") then
			mark.hit, mark.normal = hit.Position, hit.Normal
		else
			mark.hit = nil
		end
	end
	if not mark.hit then hideMark(mark) return end
	local normal, hit = mark.normal, mark.hit
	local height = hit.Y - (normal.X * (flat.X - hit.X) + normal.Z * (flat.Z - hit.Z)) / normal.Y
	local center = flat + V(0, height, 0) + normal * 0.16
	local tangent = forward - normal * normal:Dot(forward)
	local at = CFrame.lookAt(center, center + tangent, normal)
	for j, offset in arms do
		local base = at * offset
		mark.border[j].CFrame, mark.border[j].Transparency = base, 1 - 0.92 * strength
		mark.face[j].CFrame = base + normal * 0.061
		mark.face[j].Color, mark.face[j].Transparency = self.label.TextColor3, 1 - strength
	end
	mark.visible = true
end

-- Lay a short section of the route on fixed ground intervals. Walking toward
-- a chevron passes it naturally, even between updates of the tutorial objective.
local function flat(position)
	return V(position.X, 0, position.Z)
end

local function shortestCrossing(decks, start, target)
	local best, nearest, farthest = math.huge, nil, nil
	for _, deck in decks do
		local center = flat(deck.Position)
		local half = deck.Size.Z / 2
		local sign = if target.Z < center.Z then 1 else -1
		if (target.Z - center.Z) * sign >= -half or (start.Z - center.Z) * sign <= -half then continue end
		local nearEnd = center + Vector3.zAxis * (half * sign)
		local farEnd = center - Vector3.zAxis * (half * sign)
		local onDeck = math.abs(start.X - center.X) <= deck.Size.X / 2 and math.abs(start.Z - center.Z) <= half
		local distance = if onDeck then (start - farEnd).Magnitude else (start - nearEnd).Magnitude + half * 2
		distance += (farEnd - target).Magnitude
		if distance < best then
			best, nearest, farthest = distance, if onDeck then nil else nearEnd, farEnd
		end
	end
	return nearest, farthest
end

-- A side bridge or stair can stream in after the main deck (and leave again).
-- Track only the route pieces that are present on this client.
function Waypoint:watchCrossings(island, paths, bridge)
	if self.addedCrossing then
		self.addedCrossing:Disconnect()
		self.removedCrossing:Disconnect()
	end
	self.bridge, self.decks, self.exits = bridge, { bridge }, {}
	self.waterFloor = bridge.Position.Y - 1.7
	local function listFor(part)
		if part.Name == "Timber deck" and part.Parent and part.Parent.Name == "Creek crossing" then
			return self.decks
		elseif part.Name == "Canal landing" and part.Parent == paths then
			return self.exits
		end
	end
	local function attach(part)
		local list = listFor(part)
		if list and not table.find(list, part) then table.insert(list, part) end
	end
	self.addedCrossing = island.DescendantAdded:Connect(attach)
	self.removedCrossing = island.DescendantRemoving:Connect(function(part)
		local list = if part.Name == "Timber deck" then self.decks elseif part.Name == "Canal landing" then self.exits else nil
		local i = list and table.find(list, part)
		if i then table.remove(list, i) end
	end)
	local highlands = island:FindFirstChild("Citrine Highlands")
	local meadows = highlands and highlands:FindFirstChild("Outer meadows")
	if meadows then
		for _, part in meadows:GetDescendants() do attach(part) end
	end
	for _, part in paths:GetChildren() do attach(part) end
end

function Waypoint:trail(head, now, motion)
	local island = workspace:FindFirstChild("CitrineCove")
	local paths = island and island:FindFirstChild("Sand path and bridge")
	local bridge = paths and paths:FindFirstChild("Bridge decking")
	if not head or not bridge or math.abs(head.Position.Y - bridge.Position.Y) > 13 then
		if self.marks then for _, mark in self.marks do hideMark(mark) end end
		return
	end
	if not self.marks then
		self.marks = makeChevrons(self.anchor)
		self.path = {}
		self.ground = RaycastParams.new()
		self.ground.FilterType, self.ground.RespectCanCollide = Enum.RaycastFilterType.Include, true
	end
	if self.groundIsland ~= island then
		self.ground.FilterDescendantsInstances = { island }
		self.groundIsland = island
		for _, mark in self.marks do mark.sample = nil end
	end
	local root = head.AssemblyRootPart or head
	local start, target = flat(root.Position), flat(self.destination)
	if self.bridge ~= bridge then
		self:watchCrossings(island, paths, bridge)
	end
	table.clear(self.path)
	local exit
	if root.Position.Y < bridge.Position.Y + 1.35
		and math.abs(start.Z - bridge.Position.Z) < 11 and math.abs(start.X - bridge.Position.X) < 63 then
		local best = math.huge
		for _, landing in self.exits do
			local distance = (start - flat(landing.Position)).Magnitude
			if distance < best then best, exit = distance, landing end
		end
	end
	if exit then
		local foot = flat(exit.Position)
		local up = if math.abs(foot.X - bridge.Position.X) > 22 then 1 else -1
		local top = foot + Vector3.zAxis * (9.4 * up)
		local onStairs = math.abs(start.X - foot.X) < exit.Size.X / 2 and (start.Z - foot.Z) * up > -1.1
		if not onStairs then table.insert(self.path, foot) end
		table.insert(self.path, top)
		self.anchor.WorldPosition = top + Vector3.yAxis * (bridge.Position.Y + 2)
		self.label.Text = "Climb the steps"
	else
		self.anchor.WorldPosition, self.label.Text = self.destination, self.destinationLabel
		local entry, far = shortestCrossing(self.decks, start, target)
		if entry then table.insert(self.path, entry) end
		if far then table.insert(self.path, far) end
		table.insert(self.path, target)
	end

	local length, previous = 0, start
	for _, point in self.path do
		length += (point - previous).Magnitude
		previous = point
	end
	local travel = if motion then now * 4.2 else 0
	local first = math.floor((length - near + travel) / spacing)
	for i = 0, arrowCount - 1 do
		local index = first - i
		local mark = self.marks[index % arrowCount + 1]
		local along = length + travel - index * spacing
		if along > length - 1.5 then hideMark(mark) continue end
		local remaining, segmentStart = along, start
		for _, stop in self.path do
			local segment = stop - segmentStart
			local distance = segment.Magnitude
			if remaining > distance or distance < 0.001 then
				remaining -= distance
				segmentStart = stop
				continue
			end
			local forward = segment / distance
			local flat = segmentStart + forward * remaining
			local fade = math.min(along - near, near + arrowCount * spacing - along, length - 1.5 - along)
			self:placeMark(mark, flat, forward, head.Position.Y, math.clamp(fade / 0.8, 0, 1), now)
			break
		end
	end
end

function Waypoint:draw(camera, motion, aimed, outdoorHead)
	if not self.pin.Enabled then return end
	local now = os.clock()
	self:trail(outdoorHead, now, motion)
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
