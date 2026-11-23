local Score = require(script.Parent.Score)
local Beats = require(script.Parent.Beats)

local function newVoice(parent, group, preset)
	local s = Instance.new("Sound")
	s.Name = preset.name
	s.SoundId = "rbxasset://sounds/" .. preset.file
	s.SoundGroup = group
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(preset.first, preset.last)
	s.Looped = preset.loop == true
	s.Volume = 0
	if preset.eq then
		local eq = Instance.new("EqualizerSoundEffect")
		eq.LowGain, eq.MidGain, eq.HighGain = table.unpack(preset.eq)
		eq.Parent = s
	end
	if preset.room then
		local verb = Instance.new("ReverbSoundEffect")
		verb.DecayTime, verb.WetLevel = table.unpack(preset.room)
		verb.Density, verb.Diffusion = 0.76, 0.84
		verb.Parent = s
	end
	if preset.chorus then
		local chorus = Instance.new("ChorusSoundEffect")
		chorus.Depth, chorus.Mix, chorus.Rate = 0.16, 0.16, 0.46
		chorus.Parent = s
	end
	if preset.at then
		s.RollOffMode = Enum.RollOffMode.Linear
		s.RollOffMinDistance, s.RollOffMaxDistance = 28, 180
	end
	s.Parent = parent
	return s
end

local function source(parent, name)
	local p = Instance.new("Part")
	p.Name = name
	p.Transparency, p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = 1, true, false, false, false, false
	p.Size = Vector3.one * 0.1
	p.Parent = parent
	return p
end

-- Build the voices before the first frame. Overlapping notes need separate
-- voices. The rest of each phrase can reuse the same instrument.
return function(screen, musicGroup, sfxGroup)
	local events = Score.compose(Beats)
	local camera = workspace.CurrentCamera
	local stage = Instance.new("Folder")
	stage.Name, stage.Parent = "Cinematic sound sources", camera
	local bridge, gallery = source(stage, "Survey hammer"), source(stage, "Sound beneath the gallery")
	local flyby = source(stage, "Passing iron")
	local strings, violas = source(stage, "Bowed strings"), source(stage, "Short strings")
	local sources = {
		bridge = bridge, gallery = gallery, flyby = flyby, strings = strings, violas = violas,
	}
	screen.Destroying:Once(function()
		stage:Destroy()
	end)
	local pools = {}
	for _, e in events do
		local preset = Score.bank[e.key]
		local slots = pools[e.key] or {}
		pools[e.key] = slots
		local slot
		for _, candidate in slots do
			if candidate.untilTime <= e.t then
				slot = candidate
				break
			end
		end
		if not slot then
			local parent = if preset.at then sources[preset.at] else screen
			slot = { sound = newVoice(parent, if preset.music then musicGroup else sfxGroup, preset) }
			table.insert(slots, slot)
		end
		slot.untilTime = e.t + e.length
		e.sound = slot.sound
	end
	local net = game:GetService("ReplicatedStorage"):FindFirstChild("EndlessMiningNet")
	local active = {}
	local nextEvent = 1
	local function update(t)
		strings.Position = camera.CFrame:PointToWorldSpace(Vector3.new(-6, 0, -17))
		violas.Position = camera.CFrame:PointToWorldSpace(Vector3.new(7, 0, -17))
		if t >= 2.22 and t < 2.79 then
			local travel = math.clamp((t - 2.34) / 0.40, 0, 1)
			flyby.Position = camera.CFrame:PointToWorldSpace(Vector3.new(-14 + 32*travel, 3, -22 + 26*travel))
		end
		-- The late-streaming stand-in plays high above the island. Give its gallery
		-- the same apparent direction/distance as the real one in the live harbor.
		local gate = net and net:GetAttribute("Entrance")
		if gate and (camera.CFrame.Position - gate).Magnitude < 220 then
			bridge.Position = gate + Vector3.new(0, -2, 23)
			gallery.Position = gate + Vector3.new(0, -4, -17)
		else
			bridge.Position = camera.Focus.Position
			gallery.Position = camera.Focus.Position + camera.CFrame.LookVector * 17 - Vector3.yAxis * 4
		end
		for i = #active, 1, -1 do
			local e = active[i]
			local age = t - e.t
			if age >= e.length then
				e.sound:Stop()
				table.remove(active, i)
			else
				e.sound.Volume, e.sound.PlaybackSpeed = Score.mix(e, age)
			end
		end
		while events[nextEvent] and events[nextEvent].t <= t do
			local e = events[nextEvent]
			nextEvent += 1
			local age = t - e.t
			local preset = Score.bank[e.key]
			if age < e.length and (preset.loop or age < 0.19) then
				-- On a frame that lands exactly on contact, let a hard transient
				-- sound immediately. The next render may be 16–67 ms away.
				local onset = if preset.attack <= 0.012 then math.max(age, preset.attack) else age
				e.sound.Volume, e.sound.PlaybackSpeed = Score.mix(e, onset)
				local elapsed = if preset.keepAttack then 0 else age * e.rate
				local span = preset.last - preset.first
				e.sound.TimePosition = preset.first + (if preset.loop then elapsed % span else math.min(elapsed, span))
				e.sound:Play()
				table.insert(active, e)
			end
		end
	end
	return update
end
