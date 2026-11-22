-- Builds the Ink & Facet art for mine block faces. The looks live in OreLooks and the
-- shapes in ReliefKit; this module turns a block name into a cached, cloned model.
-- All coordinates are in the plane of one six-stud face: x right, y up, z out of the face.
local Looks = require(script.Parent.OreLooks)
local Kit = require(script.Parent.ReliefKit)
local Art = {}

local hex = Color3.fromHex
local ink = hex(Looks.ink)

local function colors(list)
	local out = table.create(#list)
	for i, value in list do
		out[i] = hex(value)
	end
	return out
end

local function resolve(entry)
	return {
		palette = colors(entry.palette),
		accent = entry.accent and colors(entry.accent),
		glow = entry.glow and hex(entry.glow),
		sparkle = entry.sparkle,
		ink = ink,
	}
end

local function seed(name)
	local h = 7
	for i = 1, #name do
		h = (h * 31 + string.byte(name, i)) % 2147483647
	end
	return h
end

function Art.isMineral(name)
	return Looks.ores[name] ~= nil
end

-- The light colour of a glowing ore, or nil.
function Art.glow(name)
	local entry = Looks.ores[name]
	return entry and entry.glow and hex(entry.glow)
end

-- The rock colour of a block. `grade` is the stone colour at the block's depth.
function Art.rockColor(name, grade)
	local rock = Looks.rock[name]
	if rock and rock.color then
		return hex(rock.color)
	end
	local ore = Looks.ores[name]
	if ore then
		return grade:Lerp(hex(ore.palette[2]), Looks.hostTint)
	end
	return grade
end

-- Whether the rock face of cell `p` facing `face` (a NormalId value) gets decor.
function Art.decorates(name, p, face)
	local rock = Looks.rock[name]
	return rock ~= nil and rock.every ~= nil and (p.X * 73 + p.Y * 19 + p.Z * 37 + face * 11) % rock.every == 0
end

local templates = {}
local function cached(key, fill)
	local template = templates[key]
	if not template then
		template = Instance.new("Model")
		fill(template)
		template.WorldPivot = CFrame.identity
		templates[key] = template
	end
	return template:Clone()
end

-- Whether the ore has crystals that break out of the block.
function Art.hasCrown(name)
	local entry = Looks.ores[name]
	return entry ~= nil and entry.crown ~= nil
end

-- The relief for one open face of an ore block. Pass `crown = false` for the faces that
-- should stay flush: a block's crystals break out of only one face.
function Art.face(name, cf, scale, crown)
	crown = crown ~= false
	local model = cached(name .. (if crown then "+" else "-"), function(m)
		local entry = Looks.ores[name]
		local look = resolve(entry)
		m.Name = name .. " relief"
		Kit.recipes[entry.relief](m, look, Random.new(seed(name)))
		if crown and entry.crown then
			Kit.crowns[entry.crown](m, look)
		end
	end)
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cf)
	return model
end

-- Only the crystals that break out of an ore block, for faces that show a drawing.
function Art.crown(name, cf)
	local model = cached(name .. "^", function(m)
		local entry = Looks.ores[name]
		m.Name = name .. " crystals"
		Kit.crowns[entry.crown](m, resolve(entry))
	end)
	model:PivotTo(cf)
	return model
end

-- Decor for one open face of a rock block (Dirt, Stone or Calcite). `variant` picks one of a few layouts.
function Art.decor(name, cf, variant)
	variant = variant or 1
	local model = cached(name .. "#" .. variant, function(m)
		local entry = Looks.rock[name]
		m.Name = name .. " decor"
		Kit.recipes[entry.decor](m, resolve(entry), Random.new(seed(name) + variant * 7919))
	end)
	model:PivotTo(cf)
	return model
end

return Art
