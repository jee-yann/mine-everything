-- The edit is in whole picture frames. Source seconds address the Blender
-- animation, the historical island states and the character performance.
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
	aftermath = 384,
	seam = 462,
	recovery = 513,
	landing = 645,
	settlement = 711,
	overview = 849,
	match = 921,
	present = 939,
	measure = 989,
	proofStrike = 1028,
	revealGem = 1053,
	portrait = 1107,
	commission = 1179,
	beacon = 1241,
	prompt = 1253,
	autoStrike = 1324,
	mineRun = 1384,
	lode = 1420,
	challenge = 1492,
	handoff = 1514,
	endBlend = 1558,
	duration = 1562,
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
	{ frames.seam, 10.02 },
	{ frames.recovery, scene.recovery },
	{ frames.landing, scene.landing },
	{ frames.settlement, scene.settlement },
	{ frames.overview, scene.overview },
	{ frames.match, scene.match },
	{ frames.present, scene.present },
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
