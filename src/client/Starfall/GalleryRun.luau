local cut = require(script.Parent.ExposureSheet).frames
local Curve = require(script.Parent.TravelCurve)
local V = Vector3.new
local Run = {}

-- Coordinates relative to the playable mine's grid origin. This is the centre of
-- cell (-2, -1, -7), between the two pairs of lamps on the gallery dig floor.
Run.mouth = V(-9, 0, -39)
Run.depth = 22
Run.shaft = CFrame.new(Run.mouth - V(0, Run.depth, 0)) * CFrame.Angles(-math.pi / 2, 0, 0)

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
local matchLook = V(-0.20, 0.91, 14.85)
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
		V(-1.70, 3.4, 44), V(-2.05, 4.12, 12), V(-6.5, 5.05, -19.3),
		V(-9.25, 4.68, -32.5), V(-9.43, 2.92, -38.35), Run.shaft * matchEye,
	}
	local aims = {
		start + forward * (4.6 * u) + V(0, 0.67 * u, 0),
		V(0.4, 1.75, 27), V(-2.5, 3.75, -15), V(-9.35, 1.24, -39.2),
		V(-9.4, -0.6, -39.62), V(-9.36, -3.2, -39.8), Run.shaft * matchLook,
	}
	actor.galleryEye = Curve.new(eyes, Run.shaft:VectorToWorldSpace(velocity))
	actor.galleryLook = Curve.new(aims)
end

function Run.gallery(actor, frame, launch, motion)
	local origin = Run.origin(actor)
	if not actor.galleryEye then buildApproach(actor) end
	local curve = actor.galleryEye
	if not motion then
		local at = if frame < cut.mineRun then 2 else 4
		return origin + curve.points[at], origin + actor.galleryLook.points[at], 54, 0
	end
	local span = math.max(1, cut.lode - launch)
	local elapsed = math.clamp(frame - launch, 0, span)
	-- Distance is linear over the whole approach. In the last twelve pictures
	-- match the speed of the lens already travelling inside the shaft.
	local blend = math.min(12, span)
	local speed = (curve.length - velocity.Magnitude * blend / 2) / (span - blend / 2)
	local tail = math.max(0, elapsed - (span - blend))
	local distance = speed * elapsed + (velocity.Magnitude - speed) * tail * tail / (2 * blend)
	local eye, segment, t = curve:sample(distance)
	local aim = actor.galleryLook:position(segment, t)
	return origin + eye, origin + aim, 54, 0
end

function Run.chamber(frame, motion, portrait)
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
