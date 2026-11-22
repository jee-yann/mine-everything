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
	measure = 1037,
	proofStrike = 1076,
	revealGem = 1101,
	portrait = 1155,
	commission = 1227,
	beacon = 1289,
	prompt = 1301,
	autoStrike = 1372,
	mineRun = 1432,
	lode = 1468,
	challenge = 1540,
	handoff = 1562,
	endBlend = 1606,
	duration = 1610,
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
	{ frames.measure, scene.present + (scene.handoff - scene.present) * 50 / 575 },
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
