local cut = require(script.Parent.ExposureSheet).frames
local Curve = require(script.Parent.TravelCurve)
local V = Vector3.new
local Run = {}

-- Coordinates relative to the playable mine's grid origin. This is the centre of
-- cell (-2, -1, -7), between the two pairs of lamps on the gallery dig floor.
Run.mouth = V(-9, 0, -39)
Run.depth = 22
Run.shaft = CFrame.new(Run.mouth - V(0, Run.depth, 0)) * CFrame.Angles(-math.pi / 2, 0, 0)
Run.gemFrame = cut.lode + 24

function Run.origin(actor)
	local h = actor.handoff
	local origin = h.origin or (h.landing - V(0, 4.96, 89))
	return origin + ((actor.replayLanding or h.landing) - h.landing)
end

-- Each tangent is in studs per picture so changing the interval cannot put
-- a hitch in the lens. The side slip bends around the first suspended lamp.
local function hermite(a, b, u, span)
	local u2, u3 = u * u, u * u * u
	return a[1] * (2 * u3 - 3 * u2 + 1)
		+ a[2] * (span * (u3 - 2 * u2 + u))
		+ b[1] * (-2 * u3 + 3 * u2)
		+ b[2] * (span * (u3 - u2))
end

local function sample(keys, f)
	local a = keys[1]
	for i = 2, #keys do
		local b = keys[i]
		if f <= b[3] then
			local span = b[3] - a[3]
			return hermite(a, b, math.clamp((f - a[3]) / span, 0, 1), span)
		end
		a = b
	end
	return a[1]
end

-- At the match the shaft's local Y points towards the gallery back wall and
-- its local -Z points straight down. Both views photograph one lens trajectory.
local matchEye, velocity = V(-0.20, 0.05, 21.25), V(0.045, 0.045, -1.05)
local matchLook = V(0.30, 1.02, 16.11)
local deepEye = {
	{ matchEye, velocity, cut.lode },
	{ V(-0.40, 0.93, 10.35), V(-0.09, 0.059, -0.56), cut.lode + 14 },
	{ V(-1.58, 0.72, 7.28), V(0.016, 0.009, -0.031), cut.lode + 32 },
	{ V(-0.76, 0.93, 6.45), V(0.023, 0.002, 0), cut.challenge - 17 },
	{ V(-0.43, 1.04, 7.03), V(0.018, 0.008, 0.075), cut.challenge - 1 },
}
local deepLook = {
	{ matchLook, V(0.045, 0, -0.62), cut.lode },
	{ V(0.28, 0.95, 2.5), V(-0.01, 0, -0.54), cut.lode + 15 },
	{ V(-0.38, 0.96, -1.35), V(0, 0.003, 0), cut.lode + 32 },
	{ V(-0.38, 1.17, -1.35), Vector3.zero, cut.challenge - 1 },
}

-- Positions are in the playable grid's coordinates. Keep the lens low over
-- the bridge, skim left of the hanging lamp, then tip through the opening.
local function buildApproach(actor)
	local origin, u, bearing = Run.origin(actor), actor.unit, actor.mineBearing
	local exit = actor.marker.exit.WorldPosition - origin
	local foot = V(bearing.X - origin.X, exit.Y, bearing.Z - origin.Z)
	local forward = bearing.LookVector
	local start = foot + forward * (3.4 * u)
	local eyes = {
		start + bearing:VectorToWorldSpace(V(2.55, 2.12, 2.8) * u),
		V(-1.70, 3.4, 44), V(-2.05, 4.12, 14), V(-2.7, 4.3, 8), V(-6.5, 5.05, -19.3),
		V(-9.25, 4.68, -32.5), V(-9.43, 2.92, -38.35), Run.shaft * matchEye,
	}
	local aims = {
		start + forward * (4.6 * u) + V(0, 0.67 * u, 0),
		V(0.4, 1.75, 27), V(-0.3, 1.6, 0), V(-1.2, 1.5, -8), V(-9.35, 1.24, -39.2),
		V(-9.4, -0.6, -39.62), V(-9.36, -3.2, -39.8), Run.shaft * matchLook,
	}
	actor.galleryEye = Curve.new(eyes, Run.shaft:VectorToWorldSpace(velocity))
	actor.galleryLook = Curve.new(aims)
end

function Run.gallery(actor, frame, launch, motion)
	local origin = Run.origin(actor)
	if not actor.galleryEye then buildApproach(actor) end
	local curve, signal = actor.galleryEye, actor.marker.signal
	local contact = launch - 4
	local gate = signal:time(signal.sill, contact)
	if not motion then
		local at = if frame < gate then 1 elseif frame < signal:time(signal.sill + 2, contact) then 3 else 5
		return origin + curve.points[at], origin + actor.galleryLook.points[at], 63, 0
	end
	if actor.galleryLaunch ~= launch then
		-- Brake outside the entrance while the head slips under the arch.
		-- Pick it up on the far side and tip over the timber collar after it.
		actor.galleryLaunch = launch
		actor.galleryPace = {
			{ 0, math.min(1.05, curve.stops[3] / (gate - 9 - launch)), launch },
			{ curve.stops[3], 0.61, gate - 9 },
			{ curve.stops[4], 0.32, gate + 4 },
			{ curve.stops[7], 0.72, cut.lode - 5 },
			{ curve.length - 2 * velocity.Magnitude, velocity.Magnitude, cut.lode - 2 },
			{ curve.length, velocity.Magnitude, cut.lode },
		}
	end
	local eye, segment, t = curve:sample(sample(actor.galleryPace, frame))
	local aim = signal:sample(frame, contact)
	if frame <= gate + 4 then
		-- The guide winds down the marker before it runs straight. On a late
		-- press the bridge rail can otherwise pass it on the inside of a bend.
		local gap = aim.Z + math.clamp((frame - contact - 8) * 0.42, 0, 6) - eye.Z
		local behind = if gap >= 1 then gap elseif gap > -1 then (gap + 1) ^ 2 * 0.25 else 0
		eye += V(0, 0, behind)
	end
	local intoShaft = math.clamp((frame - cut.lode + 6) / 5, 0, 1)
	if intoShaft > 0 then
		aim = aim:Lerp(actor.galleryLook:position(segment, t), intoShaft * intoShaft * (3 - 2 * intoShaft))
	end
	local bank = 0
	if frame > cut.lode - 12 then
		-- The gallery camera uses sky-up. The underground camera uses the
		-- back wall as up. Roll into its orientation before crossing the lip.
		local localUp = CFrame.lookAt(eye, aim):VectorToObjectSpace(Run.shaft.UpVector)
		local t = math.clamp((frame - cut.lode + 12) / 11, 0, 1)
		bank = math.deg(math.atan2(-localUp.X, localUp.Y)) * t * t * (3 - 2 * t)
	end
	return origin + eye, origin + aim, 54, bank
end

function Run.chamber(frame, motion, portrait)
	if not motion and frame < cut.lode + 18 then
		return V(-0.2, 0.25, 22.65), V(0.45, 1.1, 8), 60, 0
	end
	local f = if motion then frame else cut.lode + 37
	local t = math.clamp((f - cut.lode) / 32, 0, 1)
	local blend = t * t * (3 - 2 * t)
	local eye, aim = sample(deepEye, f), sample(deepLook, f)
	if portrait then
		aim += V(0.84 * blend, 0, 0)
	end
	return eye, aim, 54 - 12 * blend, math.rad(-2.6 * blend)
end

return Run
