local S = require(script.Parent.Scenery)
local BeaconSignal = require(script.Parent.BeaconSignal)
local V, CF = Vector3.new, CFrame.new
local F = require(script.Parent.ExposureSheet).frames
local metal = Enum.Material.Metal
local ExpeditionMarker = {}
ExpeditionMarker.__index = ExpeditionMarker

local function anchor(parent, name, position)
	local point = Instance.new("Attachment")
	point.Name, point.Position, point.Parent = name, position, parent
	return point
end

local function notice(wall, name)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = "Guild commission", Enum.NormalId.Back
	gui.CanvasSize, gui.SizingMode = Vector2.new(1000, 658), Enum.SurfaceGuiSizingMode.FixedSize
	gui.LightInfluence, gui.Parent = 0.18, wall
	local function line(words, y, height, ink, font, wide)
		local text = Instance.new("TextLabel")
		text.Name, text.AnchorPoint = words, Vector2.new(0.5, 0.5)
		text.Position, text.Size = UDim2.fromScale(0.5, y), UDim2.fromScale(wide, height)
		text.BackgroundTransparency, text.TextScaled = 1, true
		text.Font, text.TextColor3 = font, Color3.fromHex(ink)
		text.Text, text.Parent = words, gui
	end
	line("GUILD'S CHOICE", 0.29, 0.16, "7A382B", Enum.Font.GothamBold, 0.81)
	line(name, 0.51, 0.26, "182E32", Enum.Font.BuilderSansExtraBold, 0.84)
	line("MASTER PROSPECTOR", 0.75, 0.12, "704126", Enum.Font.GothamBold, 0.82)
	line("CITRINE COVE   /   EXPEDITION LEAD", 0.89, 0.073, "6C5844", Enum.Font.RobotoMono, 0.92)
end

local function badge(model, center)
	for _, side in { -1, 1 } do
		local function p(x, y, z)
			return center + V(x * side, y, z)
		end
		S.strut(
			model,
			"Crossed pick handle",
			p(-0.226, -0.121, 0.026),
			p(0.156, 0.13, 0.026),
			0.038,
			0.042,
			"D9A149",
			metal
		)
		S.strut(model, "Pick head", p(0.039, 0.178, 0.041), p(0.229, 0.068, 0.041), 0.056, 0.052, "FFE2A3", metal)
		S.strut(model, "Pick beak", p(0.229, 0.068, 0.041), p(0.262, -0.012, 0.041), 0.031, 0.032, "F8CE76", metal)
	end
end

local function column(model)
	-- The quarry surveyor dressed the slab at the base and left its crown broken.
	local levels = {
		{ -2.36, 0.63, 0.43, -0.04 },
		{ -1.91, 0.60, 0.42, -0.04 },
		{ -0.53, 0.48, 0.36, 0.01 },
		{ 0.37, 0.52, 0.31, 0 },
		{ 0.78, 0.39, 0.25, -0.06 },
	}
	local outline = {
		{ -1, -0.50 },
		{ -0.73, -1 },
		{ 0.73, -1 },
		{ 1, -0.54 },
		{ 1, 0.49 },
		{ 0.63, 1 },
		{ -0.69, 1 },
		{ -1, 0.49 },
	}
	local colors = { "535867", "343847", "363E4F", "4E5260", "62616A", "636470", "414758", "3B4355" }
	local previous
	for k, level in levels do
		local y, rx, rz, dx = table.unpack(level)
		local vertices = {}
		for j, v in outline do
			local notch = if k == #levels then 0.12 * math.sin(j * 2.17) else 0
			vertices[j] = V(dx + rx * v[1], y + notch, rz * v[2])
		end
		if previous then
			for j, a in vertices do
				local n = j % #vertices + 1
				S.facet(model, "Hewn basalt", previous[j], previous[n], a, colors[j])
				S.facet(model, "Hewn basalt", previous[n], vertices[n], a, colors[1 + (j + k) % #colors])
			end
		end
		previous = vertices
	end
	for j, a in previous do
		S.facet(model, "Hammered crown", a, previous[j % #previous + 1], V(-0.04, 0.88, 0.03), "777785")
	end
end

local function bezel(model, arms)
	local center = V(0, 0, 0.495)
	local belt, lip, tableCut = {}, {}, {}
	local colors = { "6745B9", "4D267F", "422174", "7850AB", "6756A1", "4C3D76", "8561A4", "41326E" }
	for i = 1, 8 do
		local phi = (i - 1) * math.pi / 4 + math.pi / 8
		local x, y = math.cos(phi), math.sin(phi)
		belt[i] = center + V(x * 0.34, y * 0.39, 0.015)
		lip[i] = center + V(x * 0.26, y * 0.30, 0.075)
		tableCut[i] = center + V(x * 0.105, y * 0.125, 0.126)
	end
	for j, outside in belt do
		local n = j % #belt + 1
		local back = V(0, 0, -0.185)
		S.facet(model, "Bronze strike collar", outside, outside + back, belt[n] + back, "755844", metal)
		S.facet(model, "Bronze strike collar", outside, belt[n] + back, belt[n], "AD8B5E", metal)
		S.strut(model, "Riveted brass bezel", outside, belt[n], 0.036, 0.055, "E7B96E", metal)
		S.facet(model, "Violet cabochon", outside, belt[n], lip[j], colors[j])
		S.facet(model, "Violet cabochon", belt[n], lip[n], lip[j], colors[n])
		S.facet(model, "Quartz window", lip[j], lip[n], tableCut[j], colors[1 + (j + 3) % 8])
		S.facet(model, "Quartz window", lip[n], tableCut[n], tableCut[j], colors[j])
		S.facet(model, "Octagonal table", tableCut[j], tableCut[n], center + V(0, 0, 0.155), "A28BE2")
	end
	for i, pair in
		{
			{ V(-0.52, 0.23, 0.302), V(-0.31, 0.17, 0.546) },
			{ V(0.46, 0.30, 0.299), V(0.24, 0.22, 0.551) },
		}
	do
		local jaw = S.group("Spring latch " .. i)
		jaw.Parent = model
		local hinge, nose = pair[1], pair[2]
		S.strut(jaw, "Filed bronze jaw", hinge, nose, 0.130, 0.095, "C68F48", metal)
		S.strut(
			jaw,
			"Steel jaw face",
			nose,
			nose + V(if i == 1 then 0.11 else -0.10, -0.13, 0.019),
			0.076,
			0.065,
			"D4BBB0",
			metal
		)
		jaw.WorldPivot = CF(hinge)
		arms[i] = { jaw = jaw, hinge = hinge, swing = if i == 1 then 1 else -1 }
	end
end

local function lanternLine(model, name, points, width)
	local parts = {}
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		parts[i - 1] = S.strut(model, name, a, b, width, width * 0.59, "664F8D")
	end
	return parts
end

-- All six offline-fused enamel/brass castings are ready before the first
-- exposed picture. Placement later only surveys the actual floor under each.
local function makeRoute()
	local route = S.group("Expedition line")
	local lamps = {}
	for i = 1, 6 do
		local model = script.Parent.ExpeditionVane:Clone()
		model.Name, model.Parent = "Descent vane " .. i, route
		local point = model.PrimaryPart["Route waypoint"]
		lamps[i] = {
			model = model,
			at = point,
			light = point["Route light"],
			strokes = { model.Violet },
			eyes = { model.Silver },
			surfaces = { model.Violet, model.Silver, model.Enamel, model.Bronze },
		}
	end
	return route, lamps
end

function ExpeditionMarker.new(name)
	local model = S.group("Starfall expedition station")
	local base = S.part(model, "Survey datum", CF(), V(0.04, 0.04, 0.04), "FFFFFF")
	base.Transparency, base.CastShadow = 1, false
	local function block(label, at, size, tint, material)
		return S.part(model, label, CF(at), size, tint, material)
	end
	column(model)
	block("Battered lower shoe", V(-0.03, -1.87, 0), V(1.19, 0.15, 0.87), "907149", metal)
	block("Upper cross tie", V(0.78, 0.74, -0.07), V(2.03, 0.125, 0.14), "8B6C47", metal)
	block("Bracket peg", V(1.91, 0.33, -0.15), V(0.13, 2.52, 0.22), "8F7253", Enum.Material.Wood)
	S.strut(model, "Diagonal bracket", V(0.11, -0.77, -0.02), V(1.63, 0.36, -0.13), 0.115, 0.15, "846847", metal)
	local center = V(1.54, 0.76, 0.075)
	block("Mahogany dispatch back", center - V(0, 0, 0.10), V(2.61, 1.79, 0.15), "61443A", Enum.Material.Wood)
	block("Blue-green brass mount", center - V(0, 0, 0.006), V(2.56, 1.74, 0.055), "315256", metal)
	local paper = block("Signed field dispatch", center + V(0, 0, 0.033), V(2.41, 1.61, 0.031), "F4DCA6")
	notice(paper, name)
	for _, side in { -1, 1 } do
		for _, y in { -0.70, 0.70 } do
			block("Commission tack", center + V(side * 1.13, y, 0.061), V(0.055, 0.055, 0.020), "AE8949", metal)
		end
	end
	local seal = center + V(0, 0.655, 0.066)
	-- A die-struck medallion and miniature crossed picks identify the guild
	-- even in the wide, before the signatures become legible.
	for i = 1, 8 do
		local a, b = (i - 1) * math.pi / 4, i * math.pi / 4
		S.facet(
			model,
			"Wax seal",
			seal + V(math.cos(a) * 0.292, math.sin(a) * 0.163, 0),
			seal + V(math.cos(b) * 0.292, math.sin(b) * 0.163, 0),
			seal + V(0, 0, 0.032),
			"7B3F39"
		)
	end
	badge(model, seal + V(0, 0, 0.041))
	local arms = {}
	bezel(model, arms)
	local faces = {}
	for _, p in model:GetDescendants() do
		if p.Name == "Quartz window" or p.Name == "Octagonal table" or p.Name == "Violet cabochon" then
			local color = if p.Name == "Octagonal table" then "EAFEFF"
				elseif p.Name == "Quartz window" then "B1ACFF" else "8954D0"
			table.insert(faces, { part = p, base = p.Color, lit = Color3.fromHex(color), material = p.Material })
		end
	end
	local veins = {
		lanternLine(model, "Sapphire thread", {
			V(-0.27, -0.17, 0.362),
			V(-0.34, -0.56, 0.367),
			V(-0.22, -0.79, 0.373),
			V(-0.35, -1.20, 0.393),
			V(-0.24, -1.70, 0.409),
		}, 0.042),
		lanternLine(model, "Iolite thread", {
			V(0.22, -0.23, 0.362),
			V(0.29, -0.51, 0.363),
			V(0.08, -0.77, 0.375),
			V(0.13, -1.16, 0.393),
			V(-0.24, -1.70, 0.409),
		}, 0.035),
	}
	local core = anchor(base, "Strike window", V(0, 0, 0.650))
	local light = S.light(core, "A691FF", 5, 0)
	light.Shadows, light.Enabled = false, false
	local route, lamps = makeRoute()
	return setmetatable({
		model = model,
		base = base,
		invitation = anchor(base, "Guild dispatch", center + V(0, 0, 0.052)),
		core = core,
		crown = anchor(base, "Cairn crown", V(0, 0.83, 0.04)),
		arms = arms,
		veins = veins,
		light = light,
		seal = anchor(base, "Twin-pick crest", seal),
		route = route,
		runnels = lamps,
		faces = faces,
		signal = BeaconSignal.new(),
	}, ExpeditionMarker)
end

local function surface(a, p)
	local live = workspace:FindFirstChild("CitrineCove")
	local delta = a.replayLanding and a.replayLanding - a.handoff.landing or Vector3.zero
	if live then
		local filter = RaycastParams.new()
		filter.FilterType, filter.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { live }
		local hit = workspace:Raycast(p - delta + Vector3.yAxis * 1.2 * a.unit, -Vector3.yAxis * 12 * a.unit, filter)
		if hit then
			return Vector3.new(p.X, hit.Position.Y + delta.Y + 0.080 * a.unit, p.Z)
		end
	end
	local floor = (a.replayLanding or a.handoff.landing).Y - 3.74
	return V(p.X, floor + 0.080 * a.unit, p.Z)
end

function ExpeditionMarker:place(a)
	local u, bearing = a.unit, a.mineBearing
	self.unit = u
	-- Leave one working pick-length between the extended palm and the crystal.
	-- The open side of the fixed seal faces the sideline, clear of the dispatch.
	self.site = bearing * CF(1.82 * u, -0.08 * u, -3.05 * u) * CFrame.Angles(0, math.rad(50), 0) * CF(0, 0, -0.650 * u)
	self.model:ScaleTo(u)
	self.model:PivotTo(self.site)
	if self.foundation then
		self.foundation:Destroy()
	end
	self.foundation = S.group("Station footing")
	self.foundation.Parent = a.stage
	local ground = surface(a, self.site.Position)
	local foundation = S.part(
		self.foundation,
		"Compass foot",
		CF(ground) * bearing.Rotation,
		V(1.46, 0.23, 1.09) * u,
		"75717C",
		Enum.Material.Slate
	)
	foundation.CFrame *= CF(0, -0.055 * u, 0)
	local bottom = self.site * V(-0.03 * u, -2.24 * u, 0)
	if bottom.Y > ground.Y then
		local height = bottom.Y - ground.Y + 0.22 * u
		S.part(
			self.foundation,
			"Basalt footing",
			CF(ground + Vector3.yAxis * (height * 0.5)) * bearing.Rotation,
			V(1.11 * u, height, 0.83 * u),
			"504E5B",
			Enum.Material.Slate
		)
	end
	for i, distance in { 3.0, 6.0, 10, 15, 21, 28 } do
		local at = bearing * V(1.3 * u * math.max(0, 1 - distance / 15), 0, -(1.88 + distance) * u)
		local pos = surface(a, at)
		local lamp = self.runnels[i]
		lamp.model:ScaleTo(u)
		lamp.model:PivotTo(CF(pos) * bearing.Rotation)
		lamp.light.Range = 3 * u
		lamp.fade = nil
	end
	self.exit = self.runnels[#self.runnels].at
	self.signal:place(self, a)
	self.model.Parent, self.route.Parent = a.stage, a.stage
end

local rest, bright = Color3.fromHex("65527D"), Color3.fromHex("B58EFF")
local function energized(parts, strength)
	for _, part in parts do
		part.Color = rest:Lerp(bright, strength)
		part.Material = if strength > 0.04 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end
function ExpeditionMarker:draw(a, frame, contact)
	if frame < F.commission or frame >= F.lode + 22 then
		self:hide()
		return
	end
	local age = frame - contact
	self.signalPosition = self.signal:draw(a.stage, frame, contact, a.motion)
	local heat = if age < 0 then 0 elseif a.motion then 0.26 + 0.74 * (1 - S.ease(age, 2, 15))
		else 0.64 * S.ease(age, 0, 5)
	if self.heat ~= heat then
		for _, face in self.faces do
			face.part.Color = face.base:Lerp(face.lit, heat)
			face.part.Material = if heat > 0.035 then Enum.Material.Neon else face.material
		end
		self.heat = heat
	end
	local unlock = S.ease(age, 0, 4)
	for _, arm in self.arms do
		arm.jaw:PivotTo(self.site * CF(arm.hinge * self.unit) * CFrame.Angles(0, 0, arm.swing * unlock * 0.64))
	end
	self.light.Enabled = age >= 0 and frame < F.lode
	self.light.Brightness = if age < 0 then 0 else 0.4 + 1.5 * (1 - S.ease(age, 0, 9))
	for i, strand in self.veins do
		energized(strand, S.ease(age, i - 2, i + 2) * (1 - S.ease(frame, F.lode - 7, F.lode)))
	end
	for i, lamp in self.runnels do
		local first = 3 + (i - 1) * 3
		local rise = S.ease(age, first, first + 2)
		local burst = rise * (1 - S.ease(age, first + 2, first + 7))
		local fade = S.ease(frame, F.lode - 12 + (#self.runnels - i) * 1.8, F.lode - 6 + (#self.runnels - i) * 1.8)
		if lamp.rise ~= rise or lamp.burst ~= burst or lamp.fade ~= fade then
			local violet =
				Color3.fromHex("5E35AB"):Lerp(Color3.fromHex("B49AF5"), rise):Lerp(Color3.fromHex("C2F3FF"), burst)
			local ice =
				Color3.fromHex("414C61"):Lerp(Color3.fromHex("8E83DC"), rise):Lerp(Color3.fromHex("E8FFFF"), burst)
			for _, v in lamp.strokes do
				v.Color = violet
				v.Material = if rise > 0.02 then Enum.Material.Neon else Enum.Material.SmoothPlastic
			end
			for _, v in lamp.eyes do
				v.Color = ice
				v.Material = if rise > 0.02 then Enum.Material.Neon else Enum.Material.SmoothPlastic
			end
			lamp.light.Enabled, lamp.light.Brightness = burst > 0.05 and fade < 1, 1.5 * burst * (1 - fade)
			if lamp.fade ~= fade then
				for _, v in lamp.surfaces do
					v.Transparency = fade
				end
			end
			lamp.rise, lamp.burst, lamp.fade = rise, burst, fade
		end
	end
	local onStage = if frame >= F.commission and age < 26 and frame < F.lode then a.stage else nil
	self.model.Parent, self.foundation.Parent = onStage, onStage
	self.route.Parent = if frame >= F.beacon - 24 and frame < F.lode + 4 then a.stage else nil
end
function ExpeditionMarker:hide()
	self.signalPosition = nil
	self.signal:hide()
	if self.foundation then
		self.foundation.Parent = nil
	end
	self.model.Parent, self.route.Parent = nil, nil
end
function ExpeditionMarker:Destroy()
	self.signal:Destroy()
	if self.foundation then
		self.foundation:Destroy()
	end
	self.model:Destroy()
	self.route:Destroy()
end
return ExpeditionMarker
