-- Original music and Foley for It Knocked Back. The instrument loops are cut
-- from Roblox's bundled sounds. Their periods tune each voice. The film has
-- its own melody, envelopes and percussion.
local Score = {}
local function sample(name, file, first, last, gain, attack, release)
	return { name = name, file = file, first = first, last = last, gain = gain, attack = attack, release = release }
end
local function instrument(name, file, first, last, rootHz, gain, attack, release)
	local s = sample(name, file, first, last, gain, attack, release)
	s.loop, s.rootHz, s.music = true, rootHz, true
	return s
end

local bank = {
	-- A short loop with a measured pitch can be articulated as a horn or drum.
	horn = instrument("Cape horn", "impact_water.mp3", 0.123175, 0.126122, 339.23, 0.24, 0.075, 0.16),
	stroke = instrument("Spiccato strings", "action_jump_land.mp3", 0.064694, 0.072358, 130.47, 1.67, 0.012, 0.105),
	drum = sample("Frame drum", "impact_water.mp3", 0.048, 0.215, 0.44, 0.003, 0.11),
	drumHead = instrument("Drum skin", "action_jump_land.mp3", 0.064694, 0.072358, 130.47, 2.75, 0.007, 0.17),
	-- A measured 11 ms grain supplies the warm fundamental and its upper partials.
	bow = instrument("Bowed stone", "action_jump_land.mp3", 0.079, 0.090, 1 / 0.011, 1.40, 0.43, 0.32),
	airString = instrument("Air strings", "action_footsteps_plastic.mp3", 0.081, 0.090, 1 / 0.009, 2.45, 0.34, 0.34),
	reed = instrument("Cove reed", "action_get_up.mp3", 0.180, 0.188, 1 / 0.008, 3.35, 0.16, 0.22),
	glass = sample("Glass harmonics", "volume_slider.ogg", 0.015, 0.66, 0.48, 0.012, 0.14),

	wind = sample("Thin upper air", "action_falling.ogg", 0.56, 5.40, 3.0, 0.33, 0.27),
	pass = sample("Wake crossing the lens", "action_falling.ogg", 1.95, 2.84, 4.65, 0.045, 0.19),
	hot = sample("Atmospheric friction", "impact_water.mp3", 0.54, 1.17, 0.36, 1.8, 0.10),
	rumble = sample("Approach rumble", "impact_explosion_03.mp3", 0.47, 0.93, 0.16, 1.6, 0.09),
	hit = sample("Landfall", "action_jump_land.mp3", 0.035, 0.18, 3.85, 0.003, 0.035),
	wave = sample("Pressure front", "impact_explosion_03.mp3", 0.265, 1.43, 0.69, 0.018, 0.15),
	slab = sample("Basalt slab", "action_jump_land.mp3", 0.047, 0.238, 3.42, 0.005, 0.088),
	ash = sample("Ash over shore", "impact_water.mp3", 0.34, 1.36, 0.61, 0.21, 0.48),
	strata = sample("Settling rubble", "action_get_up.mp3", 0.10, 0.41, 1.70, 0.022, 0.20),
	core = sample("Violet fault", "volume_slider.ogg", 0.028, 0.74, 1.34, 0.012, 0.31),
	deep = instrument("Subsurface pressure", "action_jump_land.mp3", 0.079, 0.090, 1 / 0.011, 2.4, 0.13, 0.64),
	surf = sample("Tide through crater", "action_swim.mp3", 0.25, 3.87, 2.2, 0.62, 0.75),
	rain = sample("Rain in the canopy", "impact_water.mp3", 0.42, 1.17, 0.52, 0.60, 0.59),
	bird = sample("Shore bird", "volume_slider.ogg", 0.045, 0.10, 0.18, 0.036, 0.054),
	wood = sample("Decking mallet", "action_footsteps_plastic.mp3", 0.032, 0.132, 2.45, 0.006, 0.032),
	rail = sample("Siding spike", "volume_slider.ogg", 0.018, 0.105, 0.44, 0.004, 0.055),
	rope = sample("Rope through pulley", "action_jump.mp3", 0.06, 0.21, 1.15, 0.035, 0.07),
	cart = sample("Ore cart bearings", "action_get_up.mp3", 0.115, 0.310, 1.43, 0.19, 0.30),
	lamp = sample("Lantern wick", "action_jump.mp3", 0.085, 0.159, 0.86, 0.005, 0.055),

	tap = sample("Survey knock", "action_jump_land.mp3", 0.040, 0.149, 3.92, 0.003, 0.032),
	tapMetal = sample("Hammer head", "volume_slider.ogg", 0.018, 0.075, 0.33, 0.004, 0.044),
	reply = sample("Returned knock", "action_footsteps_plastic.mp3", 0.034, 0.155, 4.30, 0.014, 0.12),
	chamber = sample("Gallery resonance", "action_jump_land.mp3", 0.079, 0.090, 2.15, 0.022, 0.56),
	pick = sample("Pick bites basalt", "action_jump_land.mp3", 0.034, 0.172, 3.95, 0.002, 0.071),
	split = sample("Fracture", "action_get_up.mp3", 0.175, 0.28, 1.86, 0.006, 0.08),
	shard = sample("Starfall resonance", "volume_slider.ogg", 0.040, 0.67, 0.76, 0.018, 0.35),
	lead = sample("Survey lead voice", "ouch.ogg", 0.124535, 0.128617, 0.43, 0.019, 0.056),
	player = sample("Explorer voice", "ouch.ogg", 0.065283, 0.068367, 0.34, 0.025, 0.041),
	vowel = sample("Vocal overtone", "volume_slider.ogg", 0.094, 0.099, 0.19, 0.023, 0.049),
}
Score.bank = bank
bank.glass.music, bank.glass.rootHz = true, 392
bank.drum.music = true
bank.stroke.decay, bank.drumHead.decay = 4.5, 4
bank.stroke.chorus = true
bank.horn.eq, bank.stroke.eq = { 1, 1, -8 }, { -4, 2, -8 }
bank.drum.eq, bank.drumHead.eq = { 5, -5, -18 }, { 2, -2, -13 }
bank.pass.eq = { -8, 1, -2 }
bank.slab.eq = { 3, 2, -11 }
bank.horn.room, bank.stroke.room, bank.drum.room = { 0.7, -18 }, { 0.47, -19 }, { 0.59, -16 }
bank.airString.at, bank.stroke.at = "strings", "violas"
bank.pass.at = "flyby"
bank.bow.vibrato, bank.horn.vibrato, bank.reed.vibrato = 0.005, 0.003, 0.007
for _, key in { "wind", "hot", "rumble", "surf", "rain", "bird", "cart", "chamber", "lead", "player", "vowel" } do
	bank[key].loop = true
end
-- SoundEffect levels are in dB. A dry foreground leaves room for the long,
-- darker gallery tail when the rhythm comes back.
bank.bow.eq, bank.airString.eq = { 1, -1, -7 }, { -3, 1, -4 }
bank.reed.eq = { -2, 2, -5 }
bank.airString.chorus, bank.bow.chorus = true, true
bank.glass.room, bank.airString.room, bank.reed.room = { 1.75, -13 }, { 1.3, -16 }, { 0.85, -18 }
bank.hot.eq, bank.rumble.eq, bank.wave.eq = { -10, -2, 0 }, { 4, -10, -24 }, { 4, -3, -13 }
bank.strata.eq, bank.core.eq, bank.deep.eq = { 3, -4, -15 }, { 0, -3, -8 }, { 4, -3, -18 }
bank.strata.room, bank.core.room, bank.deep.room = { 0.60, -18 }, { 1.42, -11 }, { 1.7, -14 }
bank.deep.music = false
bank.bird.room, bank.wood.room, bank.lamp.room = { 0.48, -20 }, { 0.32, -21 }, { 0.55, -18 }
bank.reply.eq, bank.chamber.eq = { 4, -2, -15 }, { 4, -1, -14 }
bank.reply.room, bank.chamber.room, bank.shard.room = { 1.2, -12 }, { 2.1, -10 }, { 1.9, -9 }
bank.lead.eq, bank.player.eq, bank.vowel.eq = { -8, 2, -8 }, { -8, 3, -7 }, { -5, -1, -7 }
bank.tapMetal.at, bank.chamber.at = "bridge", "gallery"
-- These strikes are cut from the first few milliseconds of the sample. Start
-- at the strike on a late render frame as well, so the scrape cannot replace it.
for _, key in { "tap", "tapMetal", "reply", "hit", "pick", "slab" } do
	bank[key].keepAttack = true
end

function Score.compose(beats)
	local events = {}
	local function cue(key, t, length, rate, strength, endRate)
		table.insert(
			events,
			{ key = key, t = t, length = length, rate = rate, level = strength or 1, endRate = endRate or rate }
		)
	end
	local function note(key, t, pitch, length, strength, bend)
		local rate = 440 * 2 ^ ((pitch - 69) / 12) / bank[key].rootHz
		cue(key, t, length, rate, strength, if bend then rate * 2 ^ (bend / 12) else rate)
	end
	local function drum(t, weight, pitch)
		cue("drum", t, 0.24, 0.77, weight)
		note("drumHead", t + 0.009, pitch, 0.34, weight, -3)
	end

	-- One air bed acquires a low harmonic, crosses the listener at the flyby
	-- and breaks off before contact. The score yields the shore to the blast.
	local hit = beats.impact
	note("bow", 0.06, 45, 2.07, 0.37)
	cue("wind", 0.36, 2.14, 0.47, 0.48, 1.35)
	cue("pass", 2.34, 0.40, 1.52, 1.21, 0.65)
	cue("rumble", 2.72, 3.33, 0.36, 0.93, 0.91)
	cue("hot", 3.04, 2.84, 0.65, 1.04, 1.38)

	cue("hit", hit, 0.18, 0.78, 1.24)
	note("deep", hit + 0.035, 34, 1.43, 1.08, -4)
	cue("wave", hit + 0.055, 1.39, 0.79, 1.08, 0.48)
	cue("ash", hit + 1.09, 2.17, 0.59, 0.76, 1.12)
	-- The perspective changes to the offshore listener. The sea-front
	-- arrives late and recedes before cutting back inside the crater.
	cue("wave", 8.77, 0.59, 0.47, 0.70, 0.38)
	cue("strata", 9.42, 0.41, 0.57, 0.41)
	cue("core", 9.60, 0.86, 0.89, 0.69, 0.73)
	note("deep", 10.02, 50, 0.69, 0.36, -2)
	cue("slab", 11.09, 0.27, 0.48, 0.47)

	-- The island's orbit becomes the metre: two quiet voices at first, then
	-- an off-beat string ostinato, drum skin, and the sounds of the shipyard.
	local history = beats.history
	local pulse = 0.36
	local bars = {
		{50, 57, 62}, {46, 53, 65}, {43, 55, 62},
		{47, 54, 66}, {43, 55, 67}, {45, 57, 64},
	}
	local sunPhrase = {
		{0.32, 74, 1.06}, {1.66, 69, 0.60}, {2.41, 76, 1.44}, {4.39, 74, 0.61},
		{5.43, 69, 1.03}, {6.84, 71, 1.20}, {8.46, 74, 0.78}, {9.55, 78, 1.54},
		{11.68, 76, 0.64}, {12.51, 79, 0.85}, {13.69, 78, 0.86}, {14.79, 74, 1.35},
	}
	for bar, pitches in bars do
		local t = history + (bar - 1) * 8 * pulse
		local length = if bar == 6 then 1.95 else 2.82
		note("bow", t, pitches[1], length, 0.49 + math.min(bar, 4) * 0.049)
		note("airString", t + 0.10, pitches[2], length - 0.13, 0.62)
		if bar >= 2 then
			local offsets = if bar == 6 then {0, 1.5, 3, 4} else {0, 1.5, 3, 4.5, 6, 7}
			for j, beat in offsets do
				note("stroke", t + beat * pulse, pitches[1 + ((j - 1) % 3)] + 12,
					0.31, (if j == 1 or j == 4 then 0.80 else 0.57) * math.min(1, bar * 0.26))
			end
		end
		if bar >= 3 then
			drum(t, 0.37 + bar * 0.034, 40)
			drum(t + 3 * pulse, 0.34, 47)
			if bar < 6 then drum(t + 6 * pulse, 0.40, 43) end
		end
	end
	for index, n in sunPhrase do
		note("reed", history + n[1], n[2], n[3], if index < 5 then 0.54 else 0.68)
		if index == 1 or index == 4 or index == 8 or index == 12 then
			note("glass", history + n[1], n[2] + 12, 0.73, 0.30)
		end
	end
	cue("surf", 12.49, 7.12, 0.60, 0.76, 0.93)
	cue("rain", history + 2.20, 2.48, 1.32, 0.47, 0.89)
	for i, t in {4.53, 4.80, 5.10} do
		cue("bird", history + t, 0.16, if i == 2 then 3.48 else 2.8, 0.58, 3.25)
	end
	cue("rope", history + 6.05, 0.33, 0.63, 0.85)
	for i, t in {6.35, 6.63, 7.03, 9.10, 9.46, 9.82, 10.71, 11.08, 11.43, 12.97, 13.33, 13.69} do
		cue("wood", history + t, 0.16, if i % 3 == 1 then 0.77 else 1.12, if i % 3 == 1 then 0.87 else 0.66)
	end
	cue("strata", history + 8.56, 0.53, 0.74, 0.43, 0.52)
	cue("rope", history + 12.96, 0.44, 0.60, 0.80)
	cue("rail", history + 13.34, 0.13, 1.36, 0.43)
	cue("rail", history + 13.71, 0.13, 1.77, 0.58)
	cue("cart", history + 14.23, 0.91, 0.65, 0.67, 1.46)
	cue("lamp", history + 15.53, 0.13, 1.28, 0.73)

	-- Perspective carries the survey. The outgoing taps have bright metal
	-- edges. Their answering envelopes broaden into an octave beneath the floor.
	for i, t in beats.outbound do
		cue("tap", t, 0.18, if i == 3 then 0.85 else 0.97, if i == 3 then 1.10 else 1.0)
		cue("tapMetal", t + 0.012, 0.10, if i == 3 then 1.50 else 1.83, 0.68)
	end
	for i, t in beats.returned do
		cue("reply", t, 0.29, 0.84 - 0.09 * i, 1.07)
		cue("chamber", t + 0.021, if i == 3 then 0.96 else 0.34, 0.94 + 0.046 * i, 0.81, 0.70)
	end
	cue("pick", beats.pick, 0.27, 0.90)
	cue("split", beats.pick + 0.24, 0.19, 0.81, 0.77)
	cue("reply", beats.answer, 0.32, 0.54, 1.19)
	cue("chamber", beats.answer + 0.020, 1.58, 1.15, 0.97, 0.70)
	cue("shard", beats.answer + 0.105, 1.08, 1.37, 0.86, 0.96)
	note("deep", beats.answer + 0.074, 38, 1.38, 0.47)
	note("bow", beats.arrival - 0.12, 50, 3.69, 0.64)
	note("airString", beats.arrival + 0.06, 57, 3.49, 0.62)
	note("horn", beats.arrival + 0.19, 62, 1.11, 0.48)
	note("reed", beats.arrival + 1.33, 69, 0.62, 0.67)
	note("reed", beats.arrival + 2.15, 76, 1.31, 0.55)
	note("glass", beats.arrival + 2.16, 76, 0.93, 0.31)
	cue("wind", beats.arrival - 0.33, 3.92, 0.57, 0.21, 0.68)

	-- Four distinct inflections, like an order, a question, a dare and a
	-- realization. Only isolated vowel cycles play. The dialogue owns its timing.
	local lines = {
		{{0.06, 0.15, 0.76, 0.93}, {0.25, 0.16, 0.84, 0.73}, {0.51, 0.13, 0.83, 0.67}},
		{{0.07, 0.24, 0.72, 1.05}, {0.41, 0.17, 0.90, 0.68}},
		{{0.06, 0.12, 0.83, 1.06}, {0.24, 0.24, 0.97, 1.11}},
		{{0.12, 0.23, 0.93, 0.71}},
	}
	for i, line in beats.dialogue do
		local voice = if line[3] == "SURVEY LEAD" then "lead" else "player"
		for j, syllable in lines[i] or {} do
			local at, len, from, to = line[1] + syllable[1], syllable[2], syllable[3], syllable[4]
			if at + len <= line[2] then
				local stress = if j == 1 then 0.68 else 0.51
				cue(voice, at, len, from, stress, to)
				cue("vowel", at + 0.008, len - 0.016, from * 1.18, stress * 0.54, to)
			end
		end
	end
	table.sort(events, function(a, b)
		return a.t < b.t
	end)
	return events
end

local function smooth(x)
	local u = math.clamp(x, 0, 1)
	return u * u * (3 - 2 * u)
end
function Score.mix(event, age)
	local s = bank[event.key]
	local attack = math.min(s.attack, event.length * 0.41)
	local release = math.min(s.release, event.length * 0.60)
	local envelope = smooth(age / attack) * smooth((event.length - age) / release)
	if s.decay then
		envelope *= math.exp(-s.decay * math.max(0, age - attack))
	end
	local rate = event.rate + (event.endRate - event.rate) * smooth(age / event.length)
	if s.vibrato then
		rate *= 1 + s.vibrato * math.sin(age * math.pi * 9.4) * smooth(age / 0.35)
	end
	return s.gain * (if s.music then 1.42 else 1) * event.level * envelope, rate
end
return Score
