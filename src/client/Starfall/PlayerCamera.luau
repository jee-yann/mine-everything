-- Every shot that has the player in it. Distances are in character units, so
-- tall, small, R6 and R15 avatars are framed the same way.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local Camera = {}

local function mix(a, b, u)
	return a + (b - a) * u
end

local function aspectOf(actor)
	local size = actor.stage.Parent.ViewportSize
	return size.X / math.max(1, size.Y)
end

local function heroHead(actor)
	-- The face in the hero pose before any performance is applied.
	return (actor.mineBearing * CF(0, 96, 0) * CF(actor.rig.rest[actor.head or actor.root].Position)).Position
end

local function heroEye(actor, u)
	local head = heroHead(actor)
	local tall = if aspectOf(actor) < 1 then 1.18 else 1
	local d = actor.unit * actor.portraitDistance * tall
	local eye = head + actor.mineBearing:VectorToWorldSpace(V(mix(-3.1, -0.95, u) * d, mix(-1.9, -1.15, u) * d, mix(-7.6, -6.7, u) * d))
	return eye, head
end

function Camera.glassFrame(actor)
	local eye, head = heroEye(actor, 0.7)
	return CFrame.lookAt(head, eye)
end

function Camera.frame(actor, frame, motion)
	local u, bearing = actor.unit, actor.mineBearing
	local function at(v)
		return bearing * (v * u)
	end
	local function n(a, b)
		return if motion then S.ease(frame, a, b) else 0.6
	end
	local face = if actor.head then actor.head.Position else at(V(0, 1.55, 0))
	local portrait = aspectOf(actor) < 1
	local eye, aim, lens, roll = nil, nil, 40, 0
	if frame < F.arrive then
		-- Over the witness's shoulder. Their screen holds the mine, and the
		-- player walks out of the crowd and into it.
		local w = actor.witness.stand
		local k = n(F.witness - 4, F.arrive + 8)
		eye = w * V(mix(2.95, 2.75, k), mix(1.75, 1.68, k), mix(1.75, 1.4, k))
		aim = w * V(mix(0.35, 0.45, k), mix(1.42, 1.45, k), -2.2)
		lens = if portrait then 64 else 47
	elseif frame < F.sprout then
		-- Meet them head on, a little below the eyes, backing away as they come.
		local k = n(F.arrive, F.arrive + 26)
		local body = actor.root.Position
		local d = u * actor.portraitDistance
		eye = body + bearing:VectorToWorldSpace(V(mix(2.9, 2.4, k) * d, mix(-0.6, 0.0, k) * u, mix(-7.6, -6.9, k) * d))
		aim = body + V(0, 0.72 * u + actor.headroom * 0.6, 0) + bearing:VectorToWorldSpace(V(mix(-0.4, -0.2, k), 0, 0) * u)
		lens = 40
		if motion then
			local rumble = S.ease(frame, F.arrive + 22, F.arrive + 30) * 0.02
			eye += V(math.sin(frame * 2.1), math.sin(frame * 2.9 + 1), 0) * rumble * u
		end
	elseif frame < F.strike then
		-- Ground level. The root breaks the compass between us and the player.
		local k = n(F.sprout, F.strike + 4)
		local tip = actor.strikePoint
		local floor = V(tip.X, actor.floor, tip.Z)
		eye = floor + bearing:VectorToWorldSpace(V(mix(3.3, 2.9, k), 0.6 + 0.1 * k, mix(-4.9, -4.4, k)) * u)
		aim = floor:Lerp(face, 0.5) + bearing:VectorToWorldSpace(V(0.1, mix(-0.1, 0.1, k), 0) * u)
		lens = 50
		local age = frame - F.sprout - 6
		if motion and age >= 0 then
			local jolt = math.exp(-age / 3.2) * math.cos(age * 2.2)
			eye += V(0, 0.07, 0) * jolt * u
			roll = 1.3 * jolt
		end
	elseif frame < F.reveal then
		-- Side on, so the whole arc of the swing is readable.
		local k = n(F.strike, F.autoStrike)
		local tip = actor.strikePoint
		local mid = face:Lerp(tip, 0.5)
		local back = if portrait then 1.25 else 1
		eye = mid + bearing:VectorToWorldSpace(V(mix(8.8, 8.0, k) * back, mix(0.15, 0.05, k), mix(-2.4, -2.0, k)) * u * mix(1, actor.portraitDistance, 0.6))
		aim = mid + bearing:VectorToWorldSpace(V(0, -0.72, -0.2) * u)
		lens = 40
		local wind = frame - F.contact2
		if motion and wind >= -7 then
			-- A breath in with the wind-up, then the lens takes the hit.
			local lean = S.ease(wind, -7, -2)
			lens -= 2.5 * lean
			if wind >= 0 then
				eye += V(0, -0.10, 0) * u * math.cos(wind * 2.4) * math.exp(-wind / 2)
				roll = 1.6 * math.cos(wind * 2) * math.exp(-wind / 2)
			end
		end
	elseif frame < F.answer then
		local age = frame - F.reveal
		-- A fast arrival, a held slow push, a last lift with the chin.
		local k = if motion then 1 - math.exp(-age / 5.5) else 0.9
		local push = if motion then S.ease(frame, F.reveal + 8, F.answer) else 0.5
		local head
		eye, head = heroEye(actor, k * 0.55 + push * 0.45)
		local right = if portrait then 0.05 else 0.95
		aim = head + bearing:VectorToWorldSpace(V(right, -0.80 + actor.headroom * 0.75 / u, 0) * u)
		lens = mix(52, 40, k)
		roll = mix(-11, -3.2, k) + 1.4 * push
	else
		-- Behind the shoulder as the light goes home, rising toward the view
		-- the player is about to have.
		local k = if motion then S.ease(frame, F.answer, F.handoff + 20) else 0.7
		local d = actor.portraitDistance
		eye = at(V(mix(1.9, 0.9, k), mix(1.25, 2.6, k), mix(5.2, 9.0, k) * (0.6 + 0.4 * d)))
		aim = at(V(mix(-1.9, -0.6, k), mix(1.0, 0.9, k), -12))
		lens = mix(46, 52, k)
		roll = 0
	end
	if actor.lens then
		local subject = if frame < F.arrive then 20 elseif frame >= F.reveal then (face - eye).Magnitude else (face - eye).Magnitude
		actor.lens.FocusDistance = subject
		actor.lens.InFocusRadius = if frame < F.arrive then 30 elseif frame < F.sprout then 4 * u elseif frame < F.reveal then 8 * u else 7 * u
		actor.lens.FarIntensity = if frame < F.arrive then 0 elseif frame >= F.reveal then 0.12 else 0.4
		actor.lens.NearIntensity = if frame >= F.reveal and frame < F.answer then 0.75 else 0
	end
	return eye, aim, lens, if motion then math.rad(roll) else 0
end

return Camera
