-- The edit is in whole picture frames. Source seconds address the Blender
-- animation, the impact simulation and the character performance.
local scene = require(script.Parent.Timeline)
local frames = table.freeze({
	open = 0,
	entry = 54,
	crystal = 96,
	flyby = 156,
	coast = 210,
	terminal = 237,
	contact = 240,
	ignition = 243,
	waveLaunch = 255,
	eruption = 260,
	shore = 302,
	breaker = 324,
	-- Everything below is the second half. Frames before 384 are approved.
	aftermath = 384,
	seam = 452,
	dark = 500,
	match = 506,
	boulevard = 572,
	dig = 614,
	firstHit = 638,
	crack = 670,
	secondHit = 674,
	reaction = 696,
	outside = 718,
	living = 760,
	livingReverse = 802,
	witness = 844,
	enter = 892,
	strike = 934,
	prompt = 942,
	autoStrike = 996,
	contact2 = 1006,
	break2 = 1014,
	inside = 1032,
	-- One bar of the score after the blow.
	reveal = 1053,
	answer = 1124,
	turn = 1170,
	handoff = 1218,
	endBlend = 1266,
	duration = 1270,
})
local cuts = {
	{ frames.open, 0 },
	{ frames.entry, scene.entry },
	{ frames.crystal, scene.entry + 19 / 24 },
	{ frames.flyby, scene.entry + 41 / 24 },
	{ frames.coast, scene.entry + 49 / 24 },
	{ frames.contact, scene.contact },
	{ frames.waveLaunch, scene.waveLaunch },
	{ frames.eruption, scene.eruption },
	{ frames.shore, scene.shore },
	{ frames.breaker, scene.breaker },
	{ frames.aftermath, scene.aftermath },
	-- Expose the last ancient simulation sample, then jump directly to
	-- the settled island. No intermediate year is sampled on a picture.
	{ frames.match - 1, 10.12 },
	{ frames.match, scene.match },
	{ frames.handoff, scene.handoff },
	{ frames.endBlend, scene.endBlend },
	{ frames.duration, scene.duration },
}
local Sheet = { fps = 24, frames = frames }

local function interpolate(value, from, to)
	for i = 2, #cuts do
		local a, b = cuts[i - 1], cuts[i]
		if value < b[from] then
			local n = math.max(0, (value - a[from]) / (b[from] - a[from]))
			return a[to] + (b[to] - a[to]) * n
		end
	end
	return cuts[#cuts][to]
end

function Sheet.sceneTime(frame)
	return interpolate(frame, 1, 2)
end

function Sheet.frameForScene(t)
	return interpolate(t, 2, 1)
end

function Sheet.secondsAt(t)
	return Sheet.frameForScene(t) / Sheet.fps
end

function Sheet.frameAt(seconds)
	return math.clamp(math.floor(seconds * Sheet.fps + 1e-7), 0, frames.duration)
end

return table.freeze(Sheet)
