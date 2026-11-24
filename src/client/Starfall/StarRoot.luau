-- A root of the fallen star, pushing up through the harbor compass. Crystals
-- rise through the real floor, so the ground hides them until they break it.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local Debris = require(script.Parent.Debris)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local M = Enum.Material
local Root = {}
Root.__index = Root

local skin = { "6C43C9", "8A5CE6", "A57BF4", "7A4FD8", "9468EC", "B690FA" }
local tipTone = { "E9DBFF", "CDB2FF", "FFFFFF", "D9C4FF", "F2E9FF", "BFA0FF" }

local function crystal(parent, at, height, radius, sides, buried)
	local shoulder = height * 0.66
	local top = at * V(radius * 0.18, height, -radius * 0.1)
	local low, high = {}, {}
	for i = 1, sides do
		local a = (i + 0.3) / sides * math.pi * 2
		local r = radius * (0.88 + 0.16 * math.sin(i * 2.7))
		low[i] = at * V(math.cos(a) * r * 0.82, -buried, math.sin(a) * r * 0.82)
		high[i] = at * V(math.cos(a) * r, shoulder + radius * 0.35 * math.sin(i * 1.9), math.sin(a) * r)
	end
	for i = 1, sides do
		local j = i % sides + 1
		local tone = skin[(i - 1) % #skin + 1]
		S.facet(parent, "Crystal face", low[i], low[j], high[i], tone)
		S.facet(parent, "Crystal face", low[j], high[j], high[i], tone)
		S.facet(parent, "Crystal tip", high[i], high[j], top, tipTone[(i - 1) % #tipTone + 1], if i % 2 == 0 then M.Neon else nil)
		S.strut(parent, "Crystal edge", low[i], high[i], radius * 0.07, radius * 0.07, "D6BCFF", M.Neon).CastShadow = false
		S.strut(parent, "Crystal edge", high[i], top, radius * 0.06, radius * 0.06, "F6EEFF", M.Neon).CastShadow = false
	end
end
Root.crystal = crystal

-- One spire per group so they can break the surface one after another.
-- x, z, height, radius, roll, pitch, delay
local spires = {
	{ 0, 0, 1.00, 0.24, 4, -3, 0 }, { -0.46, 0.10, 0.60, 0.17, 24, 10, 2 }, { 0.44, 0.16, 0.66, 0.18, -22, 12, 3 },
	{ 0.14, -0.42, 0.48, 0.15, -10, -26, 5 }, { -0.26, 0.48, 0.42, 0.14, 14, 26, 6 }, { 0.60, -0.26, 0.36, 0.11, -34, -16, 7 },
}

function Root.new(stage)
	return setmetatable({
		stage = stage,
		chips = Debris.new(20, { "4AB5AF", "257E8C", "FFE9AD" }, 77, "C79BFF"),
		burst = Debris.new(30, { "E9DBFF", "B690FA", "8A5CE6" }, 78, "FFFFFF"),
	}, Root)
end

function Root:clear()
	if self.groups then
		for _, g in self.groups do
			g.model:Destroy()
		end
		self.plates:Destroy()
		self.anchor:Destroy()
		self.groups = nil
	end
end

-- `tip` is where the pick steel stops. The tallest spire grows to meet it.
function Root:place(tip, floor, bearing, unit)
	self:clear()
	self.unit = unit
	local height = math.max(1.2 * unit, tip.Y - floor)
	self.tip, self.floor = tip, floor
	self.at = CF(tip.X, floor, tip.Z) * bearing.Rotation
	self.groups = {}
	for _, s in spires do
		local model = S.group("Star root")
		local h = height * s[3]
		local lean = A(math.rad(s[6]), 0, math.rad(s[5]))
		local base = self.at * CF(s[1] * height * 0.5, 0, s[2] * height * 0.5) * lean
		if s[3] == 1 then
			-- The struck spire is seated so its summit is exactly on the mark.
			local summit = base * V(s[4] * height * 0.18, h, -s[4] * height * 0.1)
			base += tip - summit
		end
		crystal(model, base, h, s[4] * height, 6, 0.25 * unit)
		table.insert(self.groups, { model = model, rise = h + 0.4 * unit, delay = s[7], up = base.UpVector, y = 0 })
	end
	-- Broken plates of the compass floor tilt away from the growth.
	self.plates = S.group("Lifted paving")
	self.slabs = {}
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2 + 0.2
		local r = height * (0.40 + 0.09 * math.sin(i * 2.1))
		local slab = S.part(self.plates, "Paving", CF(), V(height * 0.30, 0.10 * unit, height * 0.26),
			({ "4AB5AF", "3E9F9C", "FFF0C2" })[i % 3 + 1])
		table.insert(self.slabs, { part = slab, at = self.at * A(0, a, 0) * CF(0, 0, -r), tilt = 0.5 + 0.22 * math.sin(i * 3.3) })
	end
	self.anchor = S.part(nil, "Star root light", CF(tip - Vector3.yAxis * height * 0.35), Vector3.one * 0.05, "FFFFFF")
	self.anchor.Transparency = 1
	self.light = S.light(self.anchor, "A86BFF", 18 * unit, 0)
end

function Root:draw(frame, contact)
	if not self.groups then
		return
	end
	local age, gone = frame - F.sprout, frame - contact
	local visible = age >= 0 and gone < 1
	for _, g in self.groups do
		g.model.Parent = if visible then self.stage else nil
		if visible then
			local t = age - 6 - g.delay
			-- A break, a slight overshoot and a hold.
			local out = if t <= 0 then 0 else 1 - math.exp(-t / 2.6) * math.cos(t * 0.52)
			local y = (out - 1) * g.rise
			if y ~= g.y then
				g.model:PivotTo(g.model:GetPivot() + g.up * (y - g.y))
				g.y = y
			end
		end
	end
	self.plates.Parent = if visible then self.stage else nil
	if visible then
		local lift = S.ease(age, 4, 12)
		for i, s in self.slabs do
			local shake = if age < 6 then 0.02 * math.sin(age * 2.4 + i) else 0
			s.part.CFrame = s.at * CF(0, (0.02 + 0.10 * lift + shake) * self.unit, 0) * A(s.tilt * lift, 0, 0)
		end
	end
	self.anchor.Parent = if visible then self.stage else nil
	local breath = 0.75 + 0.25 * math.sin(frame / 5)
	self.light.Brightness = if visible then 1.1 * S.ease(age, 2, 12) * breath else 0
	local up = CF(self.at.Position + Vector3.yAxis * 0.1) * A(-math.pi / 2, 0, 0)
	self.chips:draw(self.stage, up, age - 6, 0.62 * self.unit, self.floor)
	self.burst:draw(self.stage, CF(self.tip) * A(-math.pi / 2, 0, 0), gone, 0.9 * self.unit, self.floor)
end

function Root:hide()
	if self.groups then
		for _, g in self.groups do
			g.model.Parent = nil
		end
		self.plates.Parent, self.anchor.Parent = nil, nil
	end
	self.chips:draw(nil, CF(), -1, 1)
	self.burst:draw(nil, CF(), -1, 1)
end

function Root:Destroy()
	self:clear()
	self.chips:Destroy()
	self.burst:Destroy()
end

return Root
