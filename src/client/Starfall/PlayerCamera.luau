-- Every shot that has the player in it. Distances are in character units, so
-- tall, small, R6 and R15 avatars are framed the same way. Moving shots use
-- `glide`: they are already travelling on their first exposure and still
-- travelling on their last.
local S = require(script.Parent.Scenery)
local F = require(script.Parent.ExposureSheet).frames
local V, CF = Vector3.new, CFrame.new
local Camera = {}

local function mix(a, b, u)
	return a + (b - a) * u
end

function Camera.glide(frame, a, b, lean)
	local u = math.clamp((frame - a) / (b - a), 0, 1)
	return u + (lean or -0.25) * math.sin(2 * math.pi * u) / (2 * math.pi)
end

local function aspectOf(actor)
	local size = actor.stage.Parent.ViewportSize
	return size.X / math.max(1, size.Y)
end

local function restHead(actor)
	return (actor.galleryStand * CF(0, 0, 0.3 * actor.unit) * CF(actor.rig.rest[actor.head or actor.root].Position)).Position
end

local function heroEye(actor, u)
	local head = restHead(actor)
	local d = actor.unit * actor.portraitDistance * (if aspectOf(actor) < 1 then 1.18 else 1)
	return head + actor.galleryStand:VectorToWorldSpace(V(mix(-1.9, -1.0, u) * d, mix(-1.55, -1.05, u) * d, mix(-7.2, -6.6, u) * d)), head
end

function Camera.glassFrame(actor)
	local eye, head = heroEye(actor, 0.7)
	return CFrame.lookAt(head, eye)
end

-- From inside the pocket, through the hole, at the person who made it.
local function pocketEye(actor, u)
	return actor.hole * V(mix(0.35, 0.05, u), mix(-0.55, -0.35, u), mix(-3.3, -2.3, u))
end

function Camera.frame(actor, frame, motion)
	local u = actor.unit
	local function n(a, b, lean)
		return if motion then Camera.glide(frame, a, b, lean) else 0.6
	end
	local face = if actor.head then actor.head.Position else actor.galleryStand.Position
	local portrait = aspectOf(actor) < 1
	local eye, aim, lens, roll = nil, nil, 40, 0
	local focus, radius, far, near = nil, 30, 0, 0
	if frame < F.enter then
		local w = actor.witness.stand
		local k = n(F.witness, F.enter)
		eye = w * V(mix(3.05, 2.65, k), mix(1.78, 1.66, k), mix(1.95, 1.35, k))
		aim = w * V(mix(0.30, 0.50, k), mix(1.42, 1.45, k), -2.2)
		lens = if portrait then 64 else 47
	elseif frame < F.strike then
		-- Beside the rock, looking back along the gallery. The player walks into
		-- the light of the thing they came to see.
		local at = actor.faceAt
		local k = n(F.enter, F.strike)
		local body = at:PointToObjectSpace(face)
		eye = at * V(mix(4.6, 4.0, k), mix(2.5, 2.6, k), mix(0.55, 0.8, k))
		aim = at * V(mix(-0.4, body.X - 0.35, 0.55 + 0.35 * k), body.Y - 0.35 * u, mix(5.4, body.Z, 0.5 + 0.5 * k))
		lens = if portrait then 56 else 46
		focus, radius, far = (face - eye).Magnitude, 4, 0.3
	elseif frame < F.break2 then
		-- Side on. The whole arc of the swing is readable and ends on the rock.
		local at = actor.faceAt
		local k = n(F.strike, F.contact2 + 4, -0.1)
		local tip = at:PointToObjectSpace(actor.strikePoint)
		local back = if portrait then 1.3 else 1
		local d = u * mix(1, actor.portraitDistance, 0.6)
		eye = at * V(tip.X + mix(8.8, 7.9, k) * back * d, tip.Y + mix(0.15, -0.05, k), mix(5.0, 4.5, k) * d)
		aim = at * V(tip.X - 0.1, tip.Y - 0.12 * u, 2.1 * d)
		lens = 38
		local wind = frame - F.contact2
		if motion and wind >= -7 then
			lens -= 2 * S.ease(wind, -7, -2)
			if wind >= 0 then
				local jolt = math.exp(-wind / 2)
				eye += V(0, -0.09 * u * math.cos(wind * 2.4) * jolt, 0)
				roll = 1.4 * math.cos(wind * 2) * jolt
			end
		end
		focus, radius, far = (actor.strikePoint - eye).Magnitude, 6, 0.28
	elseif frame < F.inside then
		-- On the rock. The crack runs, the slab lets go.
		local hole = actor.hole
		local k = n(F.break2, F.inside)
		local age = frame - F.contact2
		local shake = if motion then 0.06 * S.ease(age, 8, 14) * math.exp(-math.max(0, age - 14) / 7) else 0
		eye = hole * V(mix(-5.0, -4.3, k) + shake * math.sin(age * 2.7), mix(1.0, 0.7, k) + shake * math.cos(age * 3.3), mix(3.3, 3.0, k))
		aim = hole * V(mix(0.35, 0.2, k), -0.1, 0.35)
		lens = 42
		focus, radius, far = (hole.Position - eye).Magnitude, 4, 0.2
	elseif frame < F.reveal then
		local k = n(F.inside, F.reveal)
		eye = pocketEye(actor, k)
		aim = face + V(0, -0.1 * u, 0)
		lens = if portrait then 66 else 52
		focus, radius, near = (face - eye).Magnitude, 2.6, 0.2
	elseif frame < F.answer then
		-- The same lens keeps coming out of the rock and settles into the
		-- portrait, then drifts with the glass until it carries us away.
		local age = frame - F.reveal
		local k = if motion then math.clamp(1 - math.exp(-age / 6.5) * (1 + age / 40), 0, 1) else 0.95
		local drift = if motion then math.clamp(age / (F.answer - F.reveal), 0, 1) else 0.5
		local start = pocketEye(actor, 1)
		local goal, head = heroEye(actor, drift)
		local carry = if motion then S.ease(frame, F.answer - 12, F.answer + 10) else 0
		eye = start:Lerp(goal, k) + actor.galleryStand:VectorToWorldSpace(V(1.3 * carry * u, 0, 0))
		local right = if portrait then 0.05 else 0.95
		aim = face:Lerp(head, k) + actor.galleryStand:VectorToWorldSpace(V(right * k, (-0.1 - 0.68 * k) + actor.headroom * 0.75 / u * k, 0) * u)
		lens = mix(52, 40, k)
		roll = mix(0, -3.4, k) + 1.6 * drift
		focus, radius, near, far = (face - eye).Magnitude, 7 * u, 0.6, 0.1
	else
		-- On the boulevard, where the glass leaves us: in front of the player,
		-- with the mine they came out of behind them. They turn back to it, and
		-- the lens is already where the player's own camera will be.
		local road = actor.roadStand
		local d = u * actor.portraitDistance
		local walkIn = n(F.answer - 8, F.turn + 8, 0)
		local rise = if motion then S.ease(frame, F.turn - 2, F.handoff + 24) else 0.8
		local bodyZ = road:PointToObjectSpace(actor.root.Position).Z * (1 - rise)
		local reach = mix(mix(8.6, 8.4, walkIn) * d, 10.5 * u * (0.6 + 0.4 * actor.portraitDistance), rise)
		eye = road * V(mix(-3.4, -2.9, walkIn) * d * (1 - rise), mix(mix(-0.2, 0.3, walkIn) * u, 3.0 * u, rise), bodyZ - reach)
		aim = road * V(mix(-0.75, 0, rise) * u, mix(0.75 * u + actor.headroom * 0.5, 0.75 * u, rise), bodyZ + 2)
		lens = mix(40, 52, rise)
		focus, radius, far = (face - eye).Magnitude, mix(9, 60, rise), mix(0.18, 0, rise)
	end
	if actor.lens then
		actor.lens.FocusDistance = focus or 20
		actor.lens.InFocusRadius, actor.lens.FarIntensity, actor.lens.NearIntensity = radius, far, near
	end
	return eye, aim, lens, if motion then math.rad(roll) else 0
end

return Camera
