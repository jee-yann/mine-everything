-- Music and location effects have separate player-controlled buses.
local sheet = require(script.Parent.ExposureSheet)
local fps, frame = sheet.fps, sheet.frames
local contact, ignition, eruption, breaker = frame.contact / fps, frame.ignition / fps, frame.eruption / fps, frame.breaker / fps
local chooseScoreAt = frame.seam / fps
local scoreIn, scoreOut = (frame.match + 2) / fps, (frame.duration - 1) / fps
local blowAt = frame.contact2 / fps
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

-- Tim Besamusca, "Rising Hope", APM Music on Roblox. The underscore runs below
-- ground. On the bar the player breaks the rock, the full recording takes over
-- from a downbeat of its own. Both are 121.9 bpm, so one bar is 1.97 s, and the
-- last hit of the full version falls on the handoff.
-- https://create.roblox.com/store/asset/1842797951
-- https://create.roblox.com/store/asset/1842797920
local scoreId, themeId = "rbxassetid://1842797951", "rbxassetid://1842797920"
local underscoreBar, themeBar = 29.72, 18.397

-- Recorded effects from Pro Sound Effects and APM in the Creator Store.
local function recorded(name, id, first, last, level, attack, release)
	local v = timbre(name, "", first, last, level, attack, release)
	v.id = "rbxassetid://" .. id
	return v
end

local bank = {
	glass = instrument("Star harmonics", "volume_slider.ogg", 0.154422, 0.157030, 4.5, 0.008, 0.31, 1.65),
	cello = instrument("Low bowed string", "impact_water.mp3", 0.132698, 0.135306, 0.43, 0.38, 0.40),
	horn = instrument("Expedition horns", "impact_water.mp3", 0.633152, 0.635964, 0.83, 0.053, 0.12),
	pulse = instrument("Ostinato bass", "impact_water.mp3", 0.132698, 0.135306, 0.94, 0.032, 0.13, 0.92),
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
	front = timbre("Shockwave arrival", "action_falling.ogg", 2.35, 4.80, 5.3, 0.10, 0.48),
	debris = timbre("Debris at the lens", "impact_explosion_03.mp3", 0.042, 0.70, 0.55, 0.006, 0.29),
	ground = timbre("Basin rumble", "impact_explosion_03.mp3", 0.34, 2.45, 0.68, 0.28, 0.95),
	sea = timbre("Whitewater", "impact_water.mp3", 0.06, 1.86, 0.92, 0.13, 0.37),
	fault = timbre("Rock under strain", "impact_explosion_03.mp3", 0.87, 1.24, 0.36, 0.024, 0.14),
	shard = timbre("Shale through the air", "action_falling.ogg", 2.37, 3.25, 5.30, 0.05, 0.24),
	wind = timbre("Wind in the basin", "action_falling.ogg", 3.12, 7.90, 4.2, 0.52, 0.69),
	cinder = timbre("Fire in the fissure", "action_swim.mp3", 1.87, 3.04, 3.2, 0.33, 0.68),
	flame = timbre("Flame drawn through the vent", "action_falling.ogg", 2.54, 4.36, 6.8, 0.46, 0.80),
	pop = timbre("Cinders spitting", "impact_water.mp3", 0.419, 0.485, 0.47, 0.003, 0.034),
	boulder = timbre("Slumping basalt", "impact_explosion_03.mp3", 0.76, 1.61, 0.47, 0.075, 0.31),
	sand = timbre("Loose shale", "impact_explosion_03.mp3", 1.19, 1.66, 0.34, 0.019, 0.13),
	ember = timbre("Crater crackles", "impact_water.mp3", 0.139, 0.182, 0.34, 0.003, 0.028),
	vein = instrument("Resonance in the seam", "volume_slider.ogg", 0.154422, 0.157030, 2.1, 0.46, 0.84, 0.34),
	iron = timbre("Iron pick at the working mine", "impact_water.mp3", 0.055, 0.125, 0.97, 0.002, 0.026),
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
bank.step = timbre("Boots on the court", "action_footsteps_plastic.mp3", 0.049, 0.16, 1.1, 0.003, 0.05)
bank.step.eq = { 3, -5, -16 }
bank.tone = instrument("Resonance in the crystal", "volume_slider.ogg", 0.154422, 0.157030, 1.9, 0.30, 0.90, 0.22)
bank.tone.room, bank.tone.effect = { 2.2, -7 }, true
bank.facet = instrument("Cut glass", "volume_slider.ogg", 0.154422, 0.157030, 2.2, 0.004, 0.7, 2.4)
bank.facet.room, bank.facet.effect = { 1.8, -8 }, true
-- The loop lands a whole number of samples long and sounds 12 cents flat of
-- the score. Measured, then corrected.
bank.tone.hz *= 0.9932
bank.facet.hz *= 0.9932
bank.under = instrument("Sub under the rock", "impact_water.mp3", 0.132698, 0.135306, 0.52, 0.9, 1.0)
bank.under.eq, bank.under.room, bank.under.effect = { 4, -16, -40 }, { 1.4, -14 }, true
bank.low = recorded("Wind over the rim", 9113286969, 2.0, 30, 9.0, 1.2, 1.2)
bank.ice = recorded("Rock cooling", 9114858767, 1.0, 6.4, 2.2, 0.02, 0.3)
bank.ice.eq = { -4, 0, -8 }
bank.lap = recorded("Water on the rocks", 9120571708, 0.2, 36, 0.62, 0.5, 0.8)
bank.lap.eq = { -2, -2, -6 }
bank.surf = recorded("Surf below the headland", 9119677145, 2.4, 9.4, 0.95, 0.5, 1.0)
bank.gull = recorded("Gulls over the harbor", 9118858259, 0.0, 1.9, 1.6, 0.05, 0.3)
bank.gull.eq, bank.gull.room = { -10, -2, 0 }, { 1.6, -12 }
bank.drone = recorded("Air in the deep workings", 9043359885, 4, 46, 0.34, 1.0, 1.0)
bank.drone.eq = { 2, -8, -20 }
bank.drip = recorded("Water far off", 9126183577, 0, 0.5, 9, 0.002, 0.1)
bank.drip.room = { 2.4, -4 }
bank.crack = recorded("Rock gives", 9118582938, 0.18, 0.85, 1.35, 0.002, 0.2)
bank.run = recorded("Fracture running", 9114858583, 0.12, 1.30, 0.62, 0.02, 0.3)
bank.run.eq = { 2, 0, -6 }
bank.tumble = recorded("Slabs coming down", 9118693443, 0.56, 3.0, 0.62, 0.005, 0.5)
bank.rubble = recorded("Rubble settling", 9118586292, 1.4, 4.2, 0.8, 0.05, 0.9)
bank.rubble.eq = { -2, 0, -4 }
bank.boom = recorded("Body of the break", 9043340902, 0.0, 3.4, 0.62, 0.004, 1.2)
bank.boom.eq = { 3, -6, -18 }
bank.tinkle = recorded("Crystal fragments", 9114601216, 1.0, 3.9, 0.26, 0.04, 0.8)
bank.tinkle.eq, bank.tinkle.room = { -22, -2, 2 }, { 1.4, -10 }
bank.sparkle = recorded("Light on the facets", 9119448154, 1.6, 4.0, 2.6, 0.02, 0.8)
bank.sparkle.eq, bank.sparkle.room = { -14, -2, 2 }, { 2.0, -8 }
bank.pass2 = recorded("Glass crossing the lens", 9120718279, 0.22, 1.2, 0.5, 0.06, 0.2)
bank.pass2.eq = { -8, -2, 2 }
bank.drum = recorded("Something moving below", 9113343298, 0.0, 1.2, 1.0, 0.004, 0.5)
bank.drum.eq, bank.drum.room = { 2, 0, -14 }, { 2.4, -6 }
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
bank.vein.room, bank.vein.effect = { 1.1, -12 }, true
bank.iron.eq, bank.iron.room = { -13, 3, 5 }, { 0.66, -18 }
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
bank.debris.eq = { -3, 1, -6 }
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
bank.sand.eq = { -25, -6, 3 }
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
	play("front", breaker - 0.14, 1.36, 1.46, 1.12, 0.60, "inbound")
	play("blast", breaker, 0.28, 0.70, 0.49, 0.45, "inbound")
	-- The rush carries the wave. A short, quieter report lands with the
	-- first pieces of shale, after the main impact has already decayed.
	play("debris", breaker + 3 / fps, 0.44, 1.13, 0.78, 0.87, "inbound")
	play("fault", breaker + 0.09, 0.22, 1.46, 0.81, 0.96, "left")
	play("shard", breaker + 0.17, 0.66, 1.89, 0.86, 0.63, "inbound")
	play("ground", breaker + 0.24, 3.30, 0.50, 0.67, 0.35)
	play("sea", breaker + 0.34, 1.43, 0.85, 0.63, 0.54)
	play("fault", breaker + 0.61, 0.27, 0.79, 0.66, 0.54, "right")
	play("ear", breaker + 0.65, 1.96, 2.22, 0.69, 1.70)
	play("shudder", 356 / fps, 0.61, 0.47, 0.66, 0.34, "right")
	play("shudder", 402 / fps, 0.48, 0.41, 0.48, 0.32, "left")
	play("flame", aftermath - 0.35, 2.10, 0.94, 0.88, 1.12, "left")
	local dark = frame.dark / fps
	-- The crater empties out. Wind, the last of the fire, rock ticking as it
	-- cools, and one low tone that belongs to the thing on the floor.
	play("low", aftermath + 0.10, dark - aftermath + 0.1, 0.92, 0.42, 0.80)
	play("cinder", aftermath + 0.12, dark - aftermath - 0.6, 0.93, 0.80, 0.60)
	play("ground", aftermath + 0.05, 3.0, 0.42, 0.18, 0.32)
	play("boulder", aftermath + 0.60, 1.2, 0.55, 0.55, 0.40, "left")
	play("sand", aftermath + 1.5, 0.38, 0.85, 0.5, 0.66, "right")
	for i, tick in { 0.30, 1.05, 1.9, 2.75, 3.4 } do
		play("pop", aftermath + tick, 0.047, 1.2 + (i % 3) * 0.3, 0.62, nil, if i % 2 == 0 then "right" else "left")
	end
	play("ice", frame.seam / fps - 0.2, 2.1, 0.62, 1.7, 0.58, "right")
	note("under", aftermath + 1.2, 30, dark - aftermath - 1.4, 0.48)
	note("tone", frame.seam / fps + 0.05, 66, dark - frame.seam / fps - 0.25, 1.35, "left")
	note("tone", frame.seam / fps + 0.55, 73, dark - frame.seam / fps - 0.80, 0.85, "right")

	-- Present day. Water, then light, then the score.
	local now = frame.match / fps
	play("lap", now - 0.15, 5.0, 0.95, 0.85, 1.0, "left")
	play("surf", now + 0.05, 4.6, 0.92, 0.75, 0.96, "right")
	play("gull", now + 1.15, 1.5, 0.92, 0.6, nil, "right")
	play("gull", now + 2.6, 1.2, 0.84, 0.35, nil, "left")
	-- The arch closes the sky off.
	local dig = frame.dig / fps
	play("drone", dig - 0.5, frame.outside / fps - dig + 0.6, 1.0, 1.0)
	play("drip", dig + 0.95, 0.5, 0.92, 0.7, nil, "right")
	play("drip", dig + 3.3, 0.5, 1.12, 0.5, nil, "left")

	local function blow(at, weight)
		play("cloth", (at - 15) / fps, 0.34, 0.80, 0.42 * weight)
		play("swing", (at - 5) / fps, 5 / fps, 0.82, 0.62 * weight, 1.85, "left")
		play("iron", at / fps, 0.10, 1.62, 0.50 * weight, 1.25)
		play("chisel", at / fps, 0.22, 1.30, 0.42 * weight, 0.72)
		play("chip", (at + 2) / fps, 0.13, 1.25, 0.70 * weight, 0.95, "right")
		play("chip", (at + 6) / fps, 0.10, 1.6, 0.42 * weight, 1.2, "left")
		play("sand", (at + 5) / fps, 0.26, 0.85, 0.6 * weight, 0.62, "left")
	end
	blow(frame.firstHit, 0.85)
	blow(frame.secondHit, 1.0)
	local trace = frame.secondHit
	play("crack", (trace + 1) / fps, 0.5, 0.92, 0.55)
	play("run", (trace + 3) / fps, 0.9, 1.2, 0.45, 1.05, "right")
	note("facet", (trace + 3) / fps, 78, 1.4, 0.50, "left")
	note("facet", (trace + 6) / fps, 85, 1.1, 0.28, "right")
	note("tone", (trace + 3) / fps, 66, (frame.outside - trace + 2) / fps, 0.46, "left")
	play("cloth", (trace + 9) / fps, 0.34, 0.78, 0.46)

	-- The cove hears it. Open air, then the ground, then the crystal's own chord
	-- rising out of the doorway.
	local out = frame.outside / fps
	play("lap", out - 0.1, 2.1, 0.96, 0.55, 1.0, "left")
	play("gull", out + 0.05, 0.9, 0.9, 0.30, nil, "right")
	play("drum", (frame.outside + 4) / fps, 1.2, 0.62, 0.95, 0.56)
	play("ground", (frame.outside + 2) / fps, 1.7, 0.46, 0.16, 0.60)
	note("tone", (frame.outside + 4) / fps, 54, 1.6, 0.85)
	note("tone", (frame.outside + 10) / fps, 66, 1.4, 0.95, "left")
	note("tone", (frame.outside + 15) / fps, 73, 1.2, 0.75, "right")
	play("sparkle", (frame.outside + 18) / fps, 1.5, 0.86, 0.85)
	play("gull", (frame.outside + 24) / fps, 0.7, 1.12, 0.34, nil, "left")
	-- A quiet room. The same tone, small, in a television speaker.
	note("facet", frame.living / fps + 0.1, 78, 1.4, 0.55, "left")
	play("cloth", (frame.living + 19) / fps, 0.30, 0.95, 1.5)
	play("cloth", (frame.living + 30) / fps, 0.40, 0.74, 1.2, nil, "right")
	note("facet", (frame.living + 22) / fps, 85, 1.2, 0.34, "left")
	play("cloth", (frame.livingReverse + 5) / fps, 0.30, 0.90, 1.2, nil, "left")
	play("cloth", (frame.livingReverse + 25) / fps, 0.42, 0.78, 1.3, nil, "right")

	-- Outside: boots go past the lens and away toward it.
	local plaza = frame.witness / fps
	play("lap", plaza - 0.15, 2.5, 0.92, 1.0, 0.95, "left")
	for i = 1, 7 do
		local at = frame.witness - 10 + i * 10
		if at >= frame.witness then
			play("step", at / fps, 0.13, 0.78 + 0.05 * (i % 3), 1.5 - 0.15 * i, 0.72, if i > 3 then "right" else nil)
		end
	end
	note("tone", plaza + 0.2, 66, 1.9, 0.60, "right")
	-- Back below.
	local gallery = frame.enter / fps
	play("drone", gallery - 0.25, frame.reveal / fps - gallery + 0.2, 0.96, 1.1)
	for i = 1, 4 do
		play("step", (frame.enter - 8 + i * 10) / fps, 0.13, 0.62 + 0.04 * (i % 2), 1.35, 0.58)
	end
	play("drip", gallery + 1.2, 0.5, 1.0, 1.0, nil, "left")
	note("tone", gallery + 0.2, 66, (frame.contact2 - frame.enter) / fps - 0.1, 1.0, "right")
	note("tone", (frame.strike + 4) / fps, 73, (frame.contact2 - frame.strike) / fps - 0.2, 0.75, "left")

	-- The break: contact, the crack running, the weight letting go, the dust.
	local hit = frame.contact2
	play("cloth", (hit - 10) / fps, 0.30, 0.72, 0.62)
	play("swing", (hit - 5) / fps, 5 / fps, 0.66, 0.85, 2.0, "left")
	play("iron", hit / fps, 0.10, 1.50, 0.58, 1.18)
	play("chisel", hit / fps, 0.24, 1.22, 0.52, 0.70)
	play("crack", hit / fps, 0.6, 0.88, 0.95)
	play("chip", (hit + 2) / fps, 0.13, 1.2, 0.8, 0.9, "right")
	play("run", (hit + 2) / fps, 0.75, 1.05, 0.85, 0.92, "left")
	play("run", (hit + 7) / fps, 0.55, 1.35, 0.5, 1.2, "right")
	play("crack", (hit + 11) / fps, 0.6, 0.72, 0.48, 0.68, "left")
	play("boom", (hit + 12) / fps, 2.2, 0.92, 0.46, 0.84)
	play("tumble", (hit + 13) / fps, 2.0, 0.92, 0.54, 0.88)
	play("tinkle", (hit + 16) / fps, 2.2, 1.12, 1.15, 1.05, "right")
	play("rubble", (hit + 24) / fps, 2.2, 0.95, 0.7, 0.90, "left")
	-- The pocket opens upward into the reveal.
	for i, pitch in { 54, 66, 70, 73 } do
		note("tone", (frame.inside - 4 + i * 2) / fps, pitch, (frame.reveal - frame.inside) / fps + 1.5, 0.30 + 0.05 * i, if i % 2 == 0 then "right" else "left")
	end
	local glassAt = frame.reveal
	play("sparkle", (glassAt - 2) / fps, 2.2, 1.0, 1.1)
	play("tinkle", (glassAt - 3) / fps, 1.3, 1.5, 0.55, 1.35, "left")
	for i, pitch in { 66, 70, 73, 78, 82, 85 } do
		note("facet", (glassAt + (i - 1) * 2.95) / fps, pitch, 1.4, 0.95 - 0.08 * i, ({ "left", "right" })[i % 2 + 1])
	end
	-- One pass, one direction, then air.
	play("pass2", (frame.answer - 9) / fps, 0.9, 0.82, 0.9, 0.74, "pass")
	play("tinkle", (frame.answer - 6) / fps, 1.6, 1.25, 0.45, 1.1, "pass")
	local road = frame.answer / fps
	play("lap", road - 0.15, 4.2, 0.95, 0.72, 1.0, "left")
	play("lap", road + 2.9, (frame.duration - frame.answer) / fps - 2.7, 1.02, 0.9, 0.98, "right")
	play("gull", road + 0.7, 1.4, 0.9, 0.35, nil, "left")
	for i = 2, 6 do
		play("step", (frame.answer - 14 + i * 10) / fps, 0.13, 0.80 + 0.05 * (i % 3), 1.1, 0.72)
	end
	-- Below, once.
	play("drum", (frame.turn - 1) / fps, 1.2, 0.80, 1.5, 0.72)
	play("boom", (frame.turn - 1) / fps, 2.0, 0.62, 0.26, 0.56)
	note("tone", (frame.turn + 1) / fps, 66, 2.2, 0.9)
	play("cloth", (frame.turn + 12) / fps, 0.36, 0.84, 0.34)

	-- With no recordings at all, a plain pulse and pad keep the shape.
	local function alternate(key, exposure, pitch, count, gain)
		note(key, exposure / fps, pitch, count / fps, gain)
		cues[#cues].alternate = true
	end
	for beat = frame.match, frame.handoff, 24 do
		local bar = math.floor((beat - frame.match) / 48)
		alternate("pulse", beat, ({ 42, 42, 39, 37 })[bar % 4 + 1], 11, if beat < frame.contact2 then 0.5 else 0.95)
	end
	for _, h in { { frame.match + 10, 66, 40, 0.5 }, { frame.reaction, 70, 30, 0.6 }, { frame.witness, 73, 40, 0.6 }, { frame.reveal, 78, 44, 1.0 }, { frame.reveal + 46, 82, 30, 0.9 }, { frame.turn + 10, 78, 50, 0.9 } } do
		alternate("horn", h[1], h[2] - 12, h[3], h[4])
	end
	table.sort(cues, function(a, b)
		return a.at < b.at
	end)
	return cues
end

local function makeVoice(preset, parent, channel)
	local s = Instance.new("Sound")
	s.Name, s.SoundGroup = preset.name, channel
	s.SoundId = preset.id or "rbxasset://sounds/" .. preset.file
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
	for _, side in { "left", "right", "outbound", "inbound", "pass" } do
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
	score.Name, score.SoundId = "Rising Hope underscore", scoreId
	score.SoundGroup, score.Volume, score.Parent = musicGroup, 0, parent
	local theme = Instance.new("Sound")
	theme.Name, theme.SoundId = "Rising Hope", themeId
	theme.SoundGroup, theme.Volume, theme.Parent = musicGroup, 0, parent
	local slots, voices = {}, { score, theme }
	local fixed = {}
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
		table.insert(fixed, event)
	end
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(voices)
		end)
	end)
	local nextCue, active = 1, {}
	local useRecording, scoreStarted
	local function startDue(queue, index, t)
		while queue[index] and queue[index].at <= t do
			local event = queue[index]
			local preset = bank[event.key]
			local age = t - event.at
			if age < event.length and (event.at < aftermath or age < 0.5 or event.length > 1) and (not event.alternate or useRecording == false) then
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
	-- The key itself: a small cap bottoming out, and the crystal in it. It plays on
	-- the input, whatever the clock is doing.
	local keyEvents = {}
	for _, q in { { "lift", 0.10, 1.05, 1.0 }, { "paper", 0.07, 0.62, 0.75 }, { "facet", 0.7, 85, 0.50 }, { "facet", 0.6, 90, 0.26 } } do
		local key, pitch = q[1], q[3]
		if bank[key].hz then pitch = 440 * 2 ^ ((pitch - 69) / 12) / bank[key].hz end
		local voice = makeVoice(bank[key], parent, effectsGroup)
		table.insert(keyEvents, { key = key, at = 0, length = q[2], pitch = pitch, glide = pitch, gain = q[4], voice = voice })
	end
	local function press(t)
		for _, event in keyEvents do
			event.at = t
			mix(event, math.min(0.012, bank[event.key].attack))
			event.voice.TimePosition = bank[event.key].first
			event.voice:Play()
			table.insert(active, event)
		end
	end
	local themeStarted
	local function smooth(u)
		u = math.clamp(u, 0, 1)
		return u * u * (3 - 2 * u)
	end
	return function(t)
		-- Commit to one arrangement for this screening. A late network load must
		-- never replace the live arrangement halfway through a phrase.
		if useRecording == nil and t >= chooseScoreAt then
			useRecording = score.IsLoaded and theme.IsLoaded
		end
		local f = t * fps
		if useRecording and t >= scoreIn and t < blowAt + 0.25 then
			if not scoreStarted then
				score.TimePosition = math.max(0, underscoreBar - (blowAt - t))
				score:Play()
				scoreStarted = true
			end
			-- In under the sea, back behind the pick and the rooms, up again as the
			-- player winds up, and out from under the blow.
			local enter = smooth((t - scoreIn) / 2.0)
			local rock = smooth((f - frame.dig + 8) / 20) * (1 - smooth((f - frame.witness + 6) / 18))
			-- It leaves the doorway to the crystal, and the room to its own sounds.
			local doorway = smooth((f - frame.outside + 2) / 8) * (1 - smooth((f - frame.living + 4) / 10))
			local build = smooth((f - frame.enter) / 60)
			local gallery = smooth((f - frame.enter + 4) / 10) * (1 - smooth((f - frame.autoStrike + 12) / 12))
			score.Volume = (1.45 - 0.45 * rock + 0.10 * build - 0.55 * gallery - 0.15 * doorway) * enter * (1 - smooth((t - blowAt) / 0.2))
		elseif scoreStarted and score.IsPlaying then
			score:Stop()
		end
		if useRecording and t >= blowAt and t < scoreOut then
			if not themeStarted then
				theme.TimePosition = themeBar + (t - blowAt)
				theme:Play()
				themeStarted = true
			end
			-- Under the break for its one bar, open on the reveal.
			local open = smooth((f - frame.reveal + 10) / 12)
			local turn = smooth((f - frame.turn + 4) / 4) * (1 - smooth((f - frame.turn - 8) / 22))
			theme.Volume = (0.46 + 0.38 * open) * (1 - 0.5 * turn) * smooth((t - blowAt) / 0.04 + 0.2) * (1 - smooth((t - scoreOut + 1.4) / 1.4))
		elseif themeStarted and theme.IsPlaying then
			theme:Stop()
		end
		local camera = workspace.CurrentCamera
		if camera then
			local view = camera.CFrame
			anchors.left.Position = view * Vector3.new(-9, 0, -13)
			anchors.right.Position = view * Vector3.new(10, 0, -12)
			if t >= passStart and t <= passEnd then
				local pass = math.clamp((t - passStart) / (passEnd - passStart), 0, 1)
				anchors.outbound.Position = view * Vector3.new(-26 + 51 * pass, 4, -31 + 39 * pass)
			elseif t >= breaker - 0.14 and t <= breaker + 0.85 then
				local pass = math.clamp((t - breaker) / 0.62, 0, 1)
				anchors.inbound.Position = view * Vector3.new(20 - 46 * pass, 2, -24 + 31 * pass)
			elseif f >= frame.answer - 12 and f <= frame.answer + 24 then
				local go = math.clamp((f - frame.answer + 10) / 24, 0, 1)
				anchors.pass.Position = view * Vector3.new(14 - 28 * go, 0, -6)
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
	end, press
end
