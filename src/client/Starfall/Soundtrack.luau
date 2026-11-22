-- Music and location effects have separate player-controlled buses.
local sheet = require(script.Parent.ExposureSheet)
local fps, frame = sheet.fps, sheet.frames
local contact, ignition, eruption, breaker = frame.contact / fps, frame.ignition / fps, frame.eruption / fps, frame.breaker / fps
local chooseScoreAt = 458 / fps
local scoreIn, scoreOut = frame.settlement / fps, (frame.duration - 1) / fps
local backswing = 8
local automaticContact = frame.autoStrike + backswing
local aftermath = frame.aftermath / fps
local passStart, passEnd = frame.flyby / fps, frame.coast / fps

local function timbre(name, file, first, last, level, attack, release)
	return { name = name, file = file, first = first, last = last, level = level, attack = attack, release = release }
end

local function instrument(name, file, first, last, level, attack, release, decay)
	local voice = timbre(name, file, first, last, level, attack, release)
	voice.hz = 1 / (last - first)
	voice.decay = decay
	return voice
end

-- 2nd Foundation Music, "The Final Push 30B", courtesy of APM Music on Roblox.
-- https://create.roblox.com/store/asset/1848015198
local scoreId = "rbxassetid://1848015198"

local bank = {
	glass = instrument("Star harmonics", "volume_slider.ogg", 0.154422, 0.157030, 4.5, 0.008, 0.31, 1.65),
	cello = instrument("Low bowed string", "impact_water.mp3", 0.132698, 0.135306, 0.43, 0.38, 0.40),
	horn = instrument("Expedition horns", "impact_water.mp3", 0.633152, 0.635964, 0.83, 0.053, 0.12),
	pulse = instrument("Ostinato bass", "action_jump_land.mp3", 0.046712, 0.050454, 1.58, 0.013, 0.078, 0.92),
	tide = timbre("Tide under the stars", "action_swim.mp3", 1.34, 2.92, 0.92, 0.38, 0.54),
	swell = timbre("Atmospheric entry", "action_falling.ogg", 0.72, 5.42, 7.7, 0.44, 0.14),
	pass = timbre("Ablation flypast", "action_falling.ogg", 3.03, 4.92, 6.85, 0.18, 0.15),
	tunnel = timbre("Air drawn through the mine", "action_falling.ogg", 2.52, 4.93, 5.6, 0.24, 0.40),
	drift = timbre("Gallery stone resonance", "impact_explosion_03.mp3", 0.49, 1.61, 0.34, 0.14, 0.90),
	shear = timbre("Crystal skin tearing away", "action_swim.mp3", 0.20, 1.07, 3.10, 0.018, 0.19),
	pressure = timbre("Pressure front", "impact_explosion_03.mp3", 0.44, 2.06, 0.78, 1.30, 0.11),
	shudder = timbre("Headland tremor", "impact_water.mp3", 0.04, 0.88, 0.99, 0.035, 0.35),
	fracture = timbre("Landfall", "impact_water.mp3", 0.055, 0.125, 0.99, 0.002, 0.017),
	split = timbre("Crust split", "impact_water.mp3", 0.073, 0.151, 0.88, 0.002, 0.060),
	ear = instrument("Residual ringing", "volume_slider.ogg", 0.154422, 0.157030, 1.40, 0.024, 0.39, 1.45),
	vent = timbre("Eruption", "impact_explosion_03.mp3", 0.026, 1.69, 1.09, 0.003, 0.33),
	body = timbre("Ignition body", "impact_explosion_03.mp3", 0.075, 1.42, 0.61, 0.017, 0.37),
	echo = timbre("Report from the far rock face", "impact_explosion_03.mp3", 0.22, 1.35, 0.44, 0.09, 0.56),
	steam = timbre("Steam escaping the broken shore", "action_swim.mp3", 2.05, 3.26, 3.1, 0.75, 0.68),
	collapse = timbre("Collapsing crater wall", "impact_explosion_03.mp3", 0.18, 0.95, 0.83, 0.22, 0.58),
	blast = timbre("Shockwave bow", "impact_water.mp3", 0.047, 0.72, 1.48, 0.005, 0.19),
	front = timbre("Shockwave arrival", "impact_explosion_03.mp3", 0.049, 1.78, 0.97, 0.003, 0.37),
	ground = timbre("Basin rumble", "impact_explosion_03.mp3", 0.34, 2.45, 0.68, 0.28, 0.95),
	sea = timbre("Whitewater", "impact_water.mp3", 0.06, 1.86, 0.92, 0.13, 0.37),
	fault = timbre("Rock under strain", "action_jump_land.mp3", 0.026, 0.24, 2.05, 0.004, 0.10),
	shard = timbre("Shale through the air", "action_falling.ogg", 2.37, 3.25, 5.30, 0.05, 0.24),
	wind = timbre("Wind in the basin", "action_falling.ogg", 3.12, 7.90, 4.2, 0.52, 0.69),
	cinder = timbre("Fire in the fissure", "action_swim.mp3", 1.87, 3.04, 3.2, 0.33, 0.68),
	flame = timbre("Flame drawn through the vent", "action_falling.ogg", 2.54, 4.36, 6.8, 0.46, 0.80),
	pop = timbre("Cinders spitting", "action_footsteps_plastic.mp3", 1.211, 1.273, 2.75, 0.003, 0.022),
	boulder = timbre("Slumping basalt", "action_jump_land.mp3", 0.031, 0.235, 2.25, 0.007, 0.20),
	sand = timbre("Loose shale", "action_footsteps_plastic.mp3", 0.047, 0.245, 1.86, 0.003, 0.085),
	ember = timbre("Crater crackles", "action_jump.mp3", 0.02, 0.112, 1.16, 0.002, 0.024),
	keel = timbre("Keel in the shallows", "action_swim.mp3", 0.45, 2.55, 3.4, 0.065, 0.24),
	pulley = timbre("Ore hoist pulley", "action_get_up.mp3", 0.094, 0.406, 3.05, 0.062, 0.09),
	cloth = timbre("Survey sleeve", "action_swim.mp3", 1.16, 1.72, 1.70, 0.05, 0.10),
	lift = timbre("Pick settles on shoulder", "action_footsteps_plastic.mp3", 0.049, 0.16, 1.56, 0.003, 0.04),
	fly = timbre("Lettering rush", "action_falling.ogg", 2.37, 3.25, 7.42, 0.022, 0.04),
	slam = timbre("Title slam", "action_jump_land.mp3", 0.029, 0.34, 2.45, 0.004, 0.13),
	paper = timbre("Letterpress snap", "action_footsteps_plastic.mp3", 1.211, 1.281, 2.52, 0.002, 0.033),
	prism = instrument("Ore facet glints", "volume_slider.ogg", 0.154422, 0.157030, 2.15, 0.008, 0.46, 3.75),
	swing = timbre("Pick cuts the air", "action_falling.ogg", 3.08, 4.00, 8.9, 0.07, 0.05),
	chisel = timbre("Pick strikes Starfall", "impact_water.mp3", 0.047, 0.40, 1.38, 0.002, 0.13),
	chip = timbre("Starfall chips scatter", "action_footsteps_plastic.mp3", 0.043, 0.19, 2.23, 0.004, 0.055),
	ring = instrument("Resonating ore", "volume_slider.ogg", 0.154422, 0.157030, 2.65, 0.002, 0.56, 3.20),
}
bank.body.eq = { 5, -7, -22 }
bank.echo.eq = { -5, -2, -13 }
bank.steam.eq = { -18, 1, 3 }
bank.steam.loop = true
bank.lift.eq = { -9, 1, 3 }
bank.horn.eq, bank.horn.room = { -5, 1, -6 }, { 0.55, -17 }
bank.pulse.eq = { 3, -1, -8 }
bank.fly.eq, bank.swing.eq = { -7, -1, 5 }, { -17, 2, 7 }
bank.slam.eq, bank.paper.eq = { 6, 0, -6 }, { -20, 1, 5 }
bank.prism.room, bank.ring.room = { 0.81, -11 }, { 0.95, -14 }
bank.prism.effect, bank.ring.effect = true, true
bank.chisel.eq, bank.chip.eq = { -5, 2, 6 }, { -16, 3, 1 }
bank.pulley.eq, bank.pulley.loop = { -14, 4, -4 }, true
bank.glass.room = { 1.1, -12 }
bank.cello.eq = { 1, -3, -13 }
bank.cello.room = { 1.3, -13 }
bank.tide.eq = { -2, -5, -15 }
bank.pass.eq = { -8, 1, 3 }
bank.tunnel.eq, bank.tunnel.room = { -7, 2, -5 }, { 0.68, -13 }
bank.drift.eq, bank.drift.room = { 3, -8, -18 }, { 1.45, -11 }
bank.shear.eq = { -19, -1, 4 }
bank.pressure.eq = { 2, -8, -20 }
bank.shudder.eq = { 4, -12, -26 }
bank.fracture.eq = { -10, 1, 5 }
bank.split.eq = { -17, 1, 5 }
bank.ear.eq = { -45, -8, -3 }
bank.vent.eq = { 1, 0, 2 }
bank.collapse.eq = { 1, -2, -6 }
bank.collapse.loop = true
bank.blast.eq = { -5, 2, 5 }
bank.front.eq = { 1, 1, -2 }
bank.ground.eq = { 4, -9, -19 }
bank.sea.eq = { 1, -3, -5 }
bank.fault.eq = { -4, 1, 2 }
bank.shard.eq = { -17, -2, 3 }
bank.cinder.eq = { -27, -9, 5 }
bank.flame.eq = { -16, 3, 5 }
bank.pop.eq = { -21, -1, 4 }
bank.boulder.eq = { 3, -1, -12 }
bank.boulder.room = { 0.6, -18 }
bank.cinder.loop, bank.flame.loop = true, true
bank.ember.eq = { -16, -4, 4 }
bank.wind.eq = { -6, -5, -2 }
bank.sand.pan, bank.ember.pan, bank.sea.pan = "left", "right", "left"
bank.cinder.pan = "right"
bank.ear.effect = true

local function arrange()
	local cues = {}
	local function play(key, at, length, pitch, gain, glide, path)
		table.insert(cues, {
			key = key, at = at, length = length,
			pitch = pitch, gain = gain, glide = glide or pitch, path = path,
		})
	end
	local function note(key, at, pitch, length, gain, path)
		play(key, at, length, 440 * 2 ^ ((pitch - 69) / 12) / bank[key].hz, gain, nil, path)
	end
	-- The star's open fifth returns inside the unreached lode.
	note("glass", 0.16, 76, 1.36, 0.82)
	note("glass", 1.33, 83, 1.09, 0.53)
	play("tide", 0.03, 2.27, 0.52, 0.86)
	play("swell", 1.48, 5.57, 0.38, 0.96, 1.21)
	play("pressure", 3.95, 3.18, 0.27, 0.91, 0.73)
	-- The pitch breaks as the hot body clears the lens. A flake of its
	-- crust follows on the same bearing, a few exposures behind.
	play("pass", passStart, passEnd - passStart, 1.90, 1.12, 0.47, "outbound")
	play("shear", sheet.secondsAt(3.42), 0.46, 2.13, 0.97, 0.74, "outbound")
	-- The headland keeps the pressure of the approach while the body is offscreen.
	play("wind", 7.18, 5.38, 0.80, 0.27, 0.57)
	play("pressure", 7.12, contact - 7.12, 0.32, 1.02, 0.77)
	note("cello", 7.65, 36, 2.26, 0.71)
	play("shudder", 200 / fps, 0.57, 0.46, 0.64, 0.60)
	play("shudder", 229 / fps, 0.42, 0.66, 0.87, 0.42)
	play("shear", frame.terminal / fps, contact - frame.terminal / fps, 1.35, 0.78, 2.30, "left")
	-- A bone-dry contact and the held image lead the expansion by three frames.
	-- The rock face answers from the right after the first pressure and debris.
	play("fracture", contact, ignition - contact, 1.85, 0.74, 1.50)
	play("split", contact, 0.079, 2.83, 0.24, 2.20)
	play("vent", ignition, 1.72, 0.99, 1.02, 0.67)
	play("body", ignition, 1.62, 0.66, 0.83, 0.47)
	play("collapse", ignition + 0.23, breaker - ignition + 0.48, 0.44, 0.69, 0.78)
	play("ear", ignition + 0.22, 0.93, 3.16, 0.31, 2.50)
	play("echo", eruption, 1.20, 0.67, 0.75, 0.57, "right")
	play("fault", contact + 0.42, 0.24, 0.72, 0.82, 0.53, "right")
	play("shard", eruption + 0.34, 0.78, 1.36, 0.75, 0.62, "left")
	play("fault", eruption + 1.06, 0.22, 0.94, 0.82, 0.59, "left")
	play("flame", eruption + 1.12, 2.27, 0.52, 0.91, 1.42, "right")
	play("pressure", breaker - 1.55, 1.62, 0.29, 0.62, 0.94)
	play("sea", breaker - 1.10, 1.16, 0.49, 0.63, 1.12, "left")
	play("front", breaker, 1.67, 0.87, 1.03, 0.52)
	play("blast", breaker, 0.42, 1.34, 0.92, 0.64, "inbound")
	play("fault", breaker + 0.09, 0.22, 1.46, 0.81, 0.96, "left")
	play("shard", breaker + 0.17, 0.66, 1.89, 0.86, 0.63, "inbound")
	play("ground", breaker + 0.13, 3.90, 0.63, 0.80, 0.39)
	play("sea", breaker + 0.34, 1.43, 0.85, 0.63, 0.54)
	play("fault", breaker + 0.61, 0.27, 0.79, 0.66, 0.54, "right")
	play("ear", breaker + 0.65, 1.96, 2.22, 0.69, 1.70)
	play("shudder", 356 / fps, 0.61, 0.47, 0.66, 0.34, "right")
	play("shudder", 402 / fps, 0.48, 0.41, 0.48, 0.32, "left")
	play("shudder", 447 / fps, 0.39, 0.37, 0.34, 0.29, "left")
	-- The pressure exhausts itself. Turbulent air feeding the hot vent, fine
	-- crackles and a collapsing block keep their own depths across the basin.
	play("flame", aftermath - 0.35, 4.12, 0.94, 0.88, 1.24, "left")
	play("cinder", aftermath + 0.12, 5.99, 0.93, 1.05, 1.19)
	play("wind", aftermath + 0.64, 6.07, 0.68, 1.02, 0.45)
	play("steam", aftermath + 1.80, 3.72, 0.73, 0.54, 0.41, "left")
	play("ground", aftermath + 2.06, 2.73, 0.38, 0.29, 0.27, "right")
	play("flame", aftermath + 2.65, 3.50, 1.37, 0.78, 0.60, "right")
	play("boulder", aftermath + 0.51, 0.54, 0.51, 1.03, 0.39, "left")
	play("boulder", aftermath + 0.90, 0.30, 0.69, 0.65, 0.56, "left")
	play("boulder", aftermath + 1.08, 0.20, 0.88, 0.38, 0.72, "left")
	for i, rock in { 0.30, 1.16, 2.27, 3.54, 4.68 } do
		local side = if i == 2 or i == 4 then "right" else "left"
		play("sand", aftermath + rock, 0.19 + 0.018 * i, 1.24 - i * 0.13, 1.19 - i * 0.085, nil, side)
	end
	for i, tick in { 0.21, 0.73, 0.78, 1.93, 2.10, 3.52, 3.58, 4.44, 5.12 } do
		local side = if i % 4 < 2 then "right" else "left"
		play("pop", aftermath + tick, 0.047, 1.21 + (i % 5) * 0.26, 0.69 + (i % 4) * 0.13, nil, side)
		if i % 3 == 1 then
			play("ember", aftermath + tick + 0.08, 0.074, 1.48 + (i % 4) * 0.16, 0.93)
		end
	end

	-- Water, cable and the two loose chips bridge the successive settlements.
	play("wind", frame.recovery / fps + 0.40, 6.20, 0.61, 0.37, 0.41, "left")
	note("glass", (frame.recovery + 42) / fps, 67, 1.85, 0.34)
	note("glass", (frame.landing - 12) / fps, 74, 1.52, 0.31)
	play("keel", frame.landing / fps, 1.48, 0.83, 0.86, 0.57)
	play("tide", (frame.landing + 14) / fps, 2.17, 0.53, 0.62, 0.65)
	play("pulley", 789 / fps, 44 / fps, 0.73, 1.04, 1.22, "left")
	play("sand", 829 / fps, 0.17, 1.20, 0.76, 0.86, "right")
	play("sand", 836 / fps, 0.11, 1.69, 0.49, 1.18, "right")
	-- At the trial, first hear the point test the stone. The blow has a dry
	-- attack; the two halves land on separate beats before the jewel rings.
	play("sand", (frame.present + 4) / fps, 0.22, 0.73, 0.68, 0.62, "left")
	play("cloth", (frame.measure - 7) / fps, 0.42, 0.83, 0.78)
	play("lift", (frame.measure + 3) / fps, 0.10, 1.37, 0.72)
	play("swing", (frame.proofStrike - 5) / fps, 5 / fps, 1.18, 0.78, 2.03, "left")
	play("split", frame.proofStrike / fps, 0.21, 0.83, 1.24, 0.55)
	play("fault", (frame.proofStrike + 2) / fps, 0.22, 0.94, 1.05, 0.60, "left")
	play("boulder", (frame.proofStrike + 10) / fps, 0.35, 0.71, 1.06, 0.53, "right")
	play("sand", (frame.proofStrike + 16) / fps, 0.20, 0.90, 0.75, 0.68, "left")
	note("prism", (frame.revealGem + 6) / fps, 83, 0.72, 0.64, "right")
	note("prism", (frame.revealGem + 14) / fps, 90, 0.52, 0.35, "right")
	play("lift", (frame.portrait + 2) / fps, 0.14, 1.18, 0.95)
	play("paper", frame.commission / fps, 0.15, 0.91, 0.88)
	note("prism", (frame.mineRun - 15) / fps, 86, 0.43, 0.42, "signal")
	play("tunnel", frame.mineRun / fps, (frame.lode - frame.mineRun + 3) / fps, 0.75, 1.05, 1.88, "inbound")
	-- The buried fault answers the struck beacon one octave lower.
	note("ring", (frame.lode - 5) / fps, 67, 0.94, 0.62, "signal")
	play("drift", (frame.lode - 2) / fps, 1.39, 0.62, 0.70, 0.48)
	note("prism", (frame.lode + 4) / fps, 69, 0.88, 0.51, "left")
	note("prism", (frame.lode + 32) / fps, 88, 0.63, 0.90, "right")
	note("prism", (frame.lode + 33) / fps, 100, 0.30, 0.31, "right")

	-- Each line arrives in two movements. The last downbeat is wider and
	-- heavier, while the small ore stamp has a dry, paper-like slap.
	local function title(lead, headline, weight, pitch)
		play("fly", (lead - 5) / fps, 7 / fps, 0.71, weight * 0.67, 1.93, "right")
		play("paper", lead / fps, 0.10, 1.52, weight * 0.52)
		play("slam", headline / fps, 0.31, pitch, weight)
		play("paper", headline / fps, 0.11, 1.06, weight * 0.76, 0.80)
	end
	title(906, 910, 1.04, 0.71)
	title(frame.portrait + 7, frame.portrait + 9, 1.07, 0.85)
	title(frame.lode + 13, frame.lode + 15, 0.55, 0.83)
	title(frame.challenge + 2, frame.challenge + 4, 1.14, 0.64)

	-- These voices share one response to the player's actual windup.
	-- Their intervals are laid out at the automatic strike for pool allocation.
	local hitIndex = #cues + 1
	play("swing", (automaticContact - backswing) / fps, backswing / fps, 0.56, 1.0, 2.31, "right")
	play("chisel", automaticContact / fps, 0.24, 1.52, 1.11, 0.71)
	note("ring", automaticContact / fps, 79, 0.91, 1.22)
	note("ring", (automaticContact + 1) / fps, 90, 0.49, 0.67, "left")
	play("chip", (automaticContact + 2) / fps, 0.14, 1.43, 0.86, 1.03, "right")
	play("chip", (automaticContact + 5) / fps, 0.10, 1.83, 0.53, 1.24, "left")
	note("prism", (automaticContact + 6) / fps, 74, 0.24, 0.55, "left")
	note("prism", (automaticContact + 11) / fps, 81, 0.39, 0.65)
	note("prism", (automaticContact + 19) / fps, 88, 0.49, 0.50, "signal")
	for i = hitIndex, #cues do
		cues[i].strike = true
	end

	-- A rising fifth first heard over the dark water becomes a G-major horn
	-- call. The local arrangement has a pickup, a developing phrase and a coda,
	-- so an unavailable performance still gives the story a scored ending.
	local function alternate(key, exposure, pitch, count, gain)
		note(key, exposure / fps, pitch, count / fps, gain)
		cues[#cues].alternate = true
	end
	local roots = { 43, 43, 40, 36, 43, 38, 40, 36, 43, 38, 36, 40, 38, 43, 38, 36, 40, 38, 43, 36, 40, 38, 43 }
	for bar, root in roots do
		local beat = 458 + (bar - 1) * 48
		alternate("pulse", beat, root, 11, 1.34)
		alternate("pulse", beat + 24, root + 7, 7, 0.98)
		if bar >= 4 then
			alternate("pulse", beat + 18, root + 12, 4, 0.68)
			alternate("pulse", beat + 36, root + (if bar % 2 == 0 then 12 else 7), 8, 0.86)
		end
	end
	for _, phrase in {
		{ 474, 62, 16 }, { 494, 67, 31 }, { 536, 69, 13 }, { 555, 71, 30 },
		{ 600, 67, 13 }, { 620, 69, 12 }, { 644, 74, 30 }, { 686, 71, 13 },
		{ 710, 72, 22 }, { 740, 71, 9 }, { 752, 67, 14 }, { 776, 69, 12 },
		{ 800, 74, 28 }, { 840, 67, 10 }, { 853, 71, 11 }, { 869, 74, 13 },
		{ 891, 76, 14 }, { 910, 79, 38 }, { 960, 74, 18 }, { 990, 71, 18 },
		{ 1020, 74, 18 }, { 1042, 79, 22 }, { 1076, 72, 12 }, { 1094, 74, 14 },
		{ 1116, 79, 30 }, { 1156, 78, 11 }, { 1170, 79, 14 },
		{ 1201, 76, 24 }, { 1240, 74, 16 }, { 1274, 71, 22 }, { 1310, 74, 14 },
		{ 1346, 79, 25 }, { 1382, 81, 16 }, { 1410, 83, 21 }, { 1450, 78, 21 },
		{ 1496, 79, 35 }, { 1535, 74, 10 }, { 1548, 79, 12 },
	} do
		alternate("horn", phrase[1], phrase[2], phrase[3], if phrase[1] < 640 then 0.88 else 1.23)
	end
	for _, answer in { { 624, 74 }, { 852, 76 }, { 915, 86 }, { 1028, 83 }, { 1133, 86 }, { 1172, 91 } } do
		alternate("glass", answer[1], answer[2], 17, 0.45)
	end
	table.sort(cues, function(a, b)
		return a.at < b.at
	end)
	return cues
end

local function makeVoice(preset, parent, channel)
	local s = Instance.new("Sound")
	s.Name, s.SoundGroup = preset.name, channel
	s.SoundId = "rbxasset://sounds/" .. preset.file
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(preset.first, preset.last)
	s.Looped = preset.hz ~= nil or preset.loop == true
	if s.Looped then
		s.LoopRegion = s.PlaybackRegion
	end
	s.Volume = 0
	s.RollOffMinDistance, s.RollOffMaxDistance = 40, 120
	if preset.eq then
		local eq = Instance.new("EqualizerSoundEffect")
		eq.LowGain, eq.MidGain, eq.HighGain = table.unpack(preset.eq)
		eq.Parent = s
	end
	if preset.room then
		local reverb = Instance.new("ReverbSoundEffect")
		reverb.DecayTime, reverb.WetLevel = table.unpack(preset.room)
		reverb.Parent = s
	end
	s.Parent = parent
	return s
end

local function mix(event, age)
	local s = bank[event.key]
	local gain = math.min(1, age / s.attack, (event.length - age) / s.release)
	if s.decay then
		gain *= math.exp(-s.decay * math.max(0, age - s.attack))
	end
	event.voice.Volume = s.level * event.gain * math.max(0, gain)
	event.voice.PlaybackSpeed = event.pitch + (event.glide - event.pitch) * age / event.length
end

return function(parent, musicGroup, effectsGroup)
	local rig = Instance.new("Folder")
	rig.Name, rig.Parent = "Cinematic sound sources", workspace.CurrentCamera
	local anchors = {}
	for _, side in { "left", "right", "outbound", "inbound", "signal" } do
		local point = Instance.new("Part")
		point.Name, point.Anchored, point.Transparency = side, true, 1
		point.CanQuery, point.CanTouch, point.CanCollide, point.CastShadow = false, false, false, false
		point.Size, point.Parent = Vector3.one * 0.1, rig
		anchors[side] = point
	end
	parent.Destroying:Once(function()
		rig:Destroy()
	end)

	local events = arrange()
	local score = Instance.new("Sound")
	score.Name, score.SoundId = "The Final Push 30B", scoreId
	score.SoundGroup, score.Volume, score.Parent = musicGroup, 0, parent
	local slots, voices = {}, { score }
	local fixed, strikes = {}, {}
	for _, event in events do
		local preset = bank[event.key]
		local position = event.path or preset.pan
		local poolKey = event.key .. (position or "")
		local pool = slots[poolKey] or {}
		slots[poolKey] = pool
		local chosen
		for _, candidate in pool do
			if candidate.untilTime <= event.at then
				chosen = candidate
				break
			end
		end
		if not chosen then
			chosen = {
				sound = makeVoice(
					preset,
					anchors[position] or parent,
					if preset.hz and not preset.effect then musicGroup else effectsGroup
				),
			}
			table.insert(pool, chosen)
			table.insert(voices, chosen.sound)
		end
		event.voice, chosen.untilTime = chosen.sound, event.at + event.length
		table.insert(if event.strike then strikes else fixed, event)
	end
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(voices)
		end)
	end)
	local nextCue, nextStrike, active = 1, 1, {}
	local strikeAt
	local useRecording, scoreStarted
	local function startDue(queue, index, t)
		while queue[index] and queue[index].at <= t do
			local event = queue[index]
			local preset = bank[event.key]
			local age = t - event.at
			if age < event.length and (not event.alternate or useRecording == false) then
				local span = preset.last - preset.first
				local elapsed = age * (event.pitch + (event.glide - event.pitch) * age / (2 * event.length))
				-- Enter a sustained sound in time after a dropped render. Percussion
				-- still strikes at its attack while its authored cue window is open.
				local seek = if event.voice.Looped then elapsed % span
					elseif age > 0.06 and preset.attack > 0.01 then elapsed else 0
				if seek < span then
					mix(event, math.min(event.length, math.max(age, math.min(preset.attack, 0.012))))
					event.voice.TimePosition = preset.first + seek
					event.voice:Play()
					table.insert(active, event)
				end
			end
			index += 1
		end
		return index
	end
	local function duck(t, reach)
		return math.clamp(math.min((t - reach + 0.09) / 0.09, (reach + 0.30 - t) / 0.26), 0, 1)
	end
	return function(t, strikeFrame, signalPosition)
		if not strikeAt and (strikeFrame ~= nil or t >= (automaticContact - backswing) / fps) then
			strikeAt = (strikeFrame or automaticContact) / fps
			for _, event in strikes do
				event.at += strikeAt - automaticContact / fps
			end
		end
		-- Commit to one arrangement for this screening. A late network load must
		-- never replace the live arrangement halfway through a phrase.
		if useRecording == nil and t >= chooseScoreAt then
			useRecording = score.IsLoaded and score.TimeLength >= 24
			if useRecording then
				local speed = math.min(1, score.TimeLength / (scoreOut - scoreIn))
				score.PlaybackSpeed = speed
				if speed < 0.99 then
					local tuning = Instance.new("PitchShiftSoundEffect")
					tuning.Octave, tuning.Parent = 1 / speed, score
				end
			end
		end
		if useRecording and t >= scoreIn and t < scoreOut then
			local age = t - scoreIn
			if not scoreStarted then
				score.TimePosition = age * score.PlaybackSpeed
				score:Play()
				scoreStarted = true
			end
			local emphasis = math.max(duck(t, 789 / fps), duck(t, 910 / fps), duck(t, frame.proofStrike / fps),
				duck(t, (frame.portrait + 9) / fps), duck(t, frame.lode / fps), duck(t, (frame.challenge + 4) / fps))
			if strikeAt then
				emphasis = math.max(emphasis, duck(t, strikeAt))
			end
			-- Ease the same orchestra underneath the measured blow and let it
			-- rise naturally with the emerald, the guild portrait and the mine.
			local trial = math.clamp(math.min((t * fps - frame.present + 18) / 24, (frame.revealGem + 20 - t * fps) / 23), 0, 1)
			local envelope = math.clamp(math.min(age / 1.15, (scoreOut - t) / 0.70), 0, 1)
			score.Volume = (1.22 - 0.46 * trial - 0.32 * emphasis) * envelope
		elseif scoreStarted and score.IsPlaying then
			score:Stop()
		end
		local camera = workspace.CurrentCamera
		if camera then
			local view = camera.CFrame
			if signalPosition then
				anchors.signal.Position = signalPosition
			end
			anchors.left.Position = view * Vector3.new(-9, 0, -13)
			anchors.right.Position = view * Vector3.new(10, 0, -12)
			if t >= passStart and t <= passEnd then
				local pass = math.clamp((t - passStart) / (passEnd - passStart), 0, 1)
				anchors.outbound.Position = view * Vector3.new(-26 + 51 * pass, 4, -31 + 39 * pass)
			elseif t >= breaker and t <= breaker + 0.85 then
				local pass = math.clamp((t - breaker) / 0.62, 0, 1)
				anchors.inbound.Position = view * Vector3.new(20 - 46 * pass, 2, -24 + 31 * pass)
			elseif t >= frame.mineRun / fps then
				local rush = math.clamp((t * fps - frame.mineRun) / (frame.lode - frame.mineRun), 0, 1)
				anchors.inbound.Position = view * Vector3.new(-3 + 4 * rush, 1, -20 + 25 * rush)
			end
		end
		for i = #active, 1, -1 do
			local event = active[i]
			local age = t - event.at
			if age >= event.length then
				event.voice:Stop()
				table.remove(active, i)
			else
				mix(event, age)
			end
		end
		nextCue = startDue(fixed, nextCue, t)
		if strikeAt then
			nextStrike = startDue(strikes, nextStrike, t)
		end
	end
end
