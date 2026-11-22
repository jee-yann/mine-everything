-- Soft eddies occupy several depths of the sculpted cloud. Each repeat has
-- a defined birth and death, including when a cut skips over an exposure.
local Sprite = require(script.Parent.WorldSprite)
local Vapour = {}
local V = Vector3.new
local warm, orange = Color3.fromHex("FFD085"), Color3.fromHex("F56E32")
local dense, soot, mist = Color3.fromHex("B0533D"), Color3.fromHex("50495A"), Color3.fromHex("A09DA7")

function Vapour.add(packet, id, ground)
	local sources = {}
	for i = 1, if ground then 2 else 5 do
		local angle = id * 1.71 + i * 2.14
		local sprite = Sprite.new(
			packet.model.PrimaryPart,
			if ground then "Windblown soot" else "Turbulent vapor",
			Sprite.smoke,
			if ground then 0.27 else 0.13
		)
		sources[i] = { sprite = sprite, angle = angle, life = 0.64 + 0.11 * ((i + id) % 4), phase = (
			(13 * i + id * 7) % 29
		) / 29 }
	end
	packet.vapour = { sources = sources, ground = ground, pigment = 0.12 * math.sin(id * 1.754) }
end

function Vapour.draw(packet, scale, heat, alpha, age)
	local v = packet.vapour
	local temperature = math.clamp(heat + v.pigment, 0, 1)
	local glow = if temperature < 0.36
		then warm:Lerp(orange, temperature / 0.36)
		else orange:Lerp(soot, math.clamp((temperature - 0.36) / 0.41, 0, 1))
	local smoke = if temperature < 0.45
		then dense:Lerp(soot, temperature * 0.9)
		else soot:Lerp(mist, (temperature - 0.45) / 0.55)
	for i, source in v.sources do
		local u = (age / source.life + source.phase) % 1
		local a = source.angle + 0.23 * u
		local reach = if v.ground then 1 else 1.44
		local offset = V(
			reach * (3.9 + 1.6 * u) * math.cos(a) + 0.65 * u,
			(i - 2) * 1.13 + 3.6 * u,
			reach * (3.1 + 0.7 * u) * math.sin(a)
		) * scale
		local diameter = scale * (if v.ground then 10.4 else 13.8 + i * 1.05) * (0.62 + 0.68 * u)
		local veil = math.sin(math.pi * u) ^ 0.66 * (1 - alpha) * (if v.ground then 0.61 else 0.86)
		local tint = if v.ground
			then soot:Lerp(smoke, 0.36 + 0.54 * u)
			else glow:Lerp(smoke, math.clamp(0.13 * i + 0.51 * u, 0, 1))
		Sprite.draw(
			source.sprite,
			offset,
			diameter * (1.07 + 0.08 * math.sin(a)),
			diameter,
			a * 53 + u * (if i % 2 == 0 then 39 else -44),
			tint,
			1 - veil
		)
	end
end
return Vapour
