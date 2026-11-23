-- Mineral jets describe complete, differently timed ballistic arcs. Each
-- cubic is the exact segment of its parabola between the two moving endpoints.
local Crater = require(script.Parent.Crater)
local P = require(script.Parent.Props)
local V, CF, rgb, ease = Vector3.new, CFrame.new, Color3.fromHex, P.ease

local Jets = {}
Jets.__index = Jets
local function makeBeam(parent, a, b, name, textured)
	local beam = Instance.new("Beam")
	beam.Name, beam.Attachment0, beam.Attachment1 = name, a, b
	beam.FaceCamera, beam.Segments = true, 12
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(if textured then "DCC4A4" else "EE9B58")),
		ColorSequenceKeypoint.new(0.63, rgb(if textured then "AD9994" else "FFD79A")),
		ColorSequenceKeypoint.new(1, rgb(if textured then "C3AEA4" else "FFF1BF")),
	})
	if textured then
		beam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		beam.TextureMode = Enum.TextureMode.Stretch
	end
	beam.LightInfluence, beam.LightEmission = if textured then 0.43 else 0, if textured then 0.18 else 0.75
	beam.Parent = parent
	return beam
end

function Jets.new(parent)
	local origin = P.box(parent, "Vaporized ejecta paths", Vector3.zero, Vector3.one * 0.12, "786676")
	origin.Transparency, origin.CastShadow = 1, false
	local self = setmetatable({ origin = origin, paths = {} }, Jets)
	local rng = Random.new(731088)
	for group, fan in
		{ { 0.38, 5, 31, 32 }, { 1.26, 4, 26, 37 }, { 2.62, 3, 24, 22 }, { 3.83, 4, 36, 19 }, { 5.27, 3, 33, 27 } }
	do
		for i = 1, fan[2] do
			local theta = fan[1] + (i - (fan[2] + 1) / 2) * 0.082 + rng:NextNumber(-0.033, 0.033)
			local h = fan[3] * rng:NextNumber(0.71, 1.18)
			local v = V(math.cos(theta) * h, fan[4] * rng:NextNumber(0.77, 1.14), math.sin(theta) * h)
			local a, b = Instance.new("Attachment", origin), Instance.new("Attachment", origin)
			local delay = 0.04 + group * 0.018 + i * 0.018
			local dust = makeBeam(origin, a, b, "Entrained fine dust", true)
			local hot = makeBeam(origin, a, b, "Melt filament", false)
			table.insert(self.paths, {
				a = a,
				b = b,
				dust = dust,
				hot = hot,
				v = v,
				delay = delay,
				width = rng:NextNumber(0.43, 1.1),
				duration = rng:NextNumber(0.82, 1.34),
				seed = V(math.cos(theta) * 1.9, Crater.contactHeight(delay) + 0.22, math.sin(theta) * 1.9),
			})
		end
	end
	return self
end

function Jets:draw(age)
	local grav = V(0, -31, 0)
	for _, p in self.paths do
		local s = age - p.delay
		local visible = s > 0 and s < p.duration
		p.dust.Enabled, p.hot.Enabled = visible, visible and s < 0.90
		if visible then
			local tail = math.max(0, s - (0.12 + 0.67 * ease(s, 0.06, 0.75)))
			local dt = s - tail
			local va, vb = p.v + grav * tail, p.v + grav * s
			p.a.Position, p.b.Position =
				p.seed + p.v * tail + grav * (tail * tail * 0.5), p.seed + p.v * s + grav * (s * s * 0.5)
			p.a.Axis, p.b.Axis = va.Unit, vb.Unit
			for _, beam in { p.dust, p.hot } do
				beam.CurveSize0, beam.CurveSize1 = va.Magnitude * dt / 3, vb.Magnitude * dt / 3
			end
			local fade = ease(s, p.duration * 0.58, p.duration)
			p.dust.Transparency = NumberSequence.new(0.09 + fade * 0.91, 0.42 + fade * 0.58)
			p.dust.Width0, p.dust.Width1 = p.width * (1.3 + 4 * s), p.width * 0.55
			p.hot.Width0, p.hot.Width1 = p.width * 0.13, p.width * 0.23
			p.hot.Transparency = NumberSequence.new(0.62 + 0.38 * fade, 0.12 + 0.88 * fade)
		end
	end
end

return Jets
