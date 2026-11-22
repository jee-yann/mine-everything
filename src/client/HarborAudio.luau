local SoundService = game:GetService("SoundService")
local Input = game:GetService("UserInputService")

local Audio = {}
local bus = Instance.new("Folder")
bus.Name, bus.Parent = "Harbor audio", SoundService
local function channel(name)
	local group = Instance.new("SoundGroup")
	group.Name, group.Volume, group.Parent = name, 0, SoundService
	return group
end
local musicChannel, sfxChannel = channel("Harbor music"), channel("Harbor effects")
function Audio.volume(key, percent)
	local group = if key == "MusicVolume" then musicChannel else sfxChannel
	group.Volume = percent / 100
end
local function sound(name, asset, volume, pitch, parent)
	local s = Instance.new("Sound")
	s.Name, s.SoundId, s.Volume, s.PlaybackSpeed, s.Parent = name, asset, volume, pitch, parent or bus
	s.SoundGroup = sfxChannel
	return s
end

-- Anthony Mawer, Prima Bossa Nova, from APM's Roblox Creator Store catalog.
local music = sound("Prima Bossa Nova", "rbxassetid://1837070127", 0.095, 1)
music.SoundGroup, music.Looped = musicChannel, true
-- The harbor track enters after the first-visit scene, at the player's own mix level.
function Audio.startHarborMusic()
	if music.IsPlaying or (game:GetService("RunService"):IsStudio() and game.ReplicatedStorage:GetAttribute("MuteTestMusic")) then return end
	music.Volume = 0
	music:Play()
	game:GetService("TweenService"):Create(music, TweenInfo.new(1.4), { Volume = 0.095 }):Play()
end

local pop = "rbxassetid://15675055424" -- Roblox UI Cute Pop
local voices = {
	Hover = sound("Hover pip", pop, 0.055, 1.52),
	Open = sound("Menu bubble", pop, 0.19, 1.13),
	Interact = sound("Counter chime", pop, 0.26, 1.38),
	Close = sound("Close bubble", "rbxassetid://15675081158", 0.15, 1.1),
	Buy = sound("Workshop pop", pop, 0.17, 1.18),
	Job = sound("Job pop", pop, 0.16, 1.31),
	Mine = sound("Grip pop", pop, 0.09, 0.78),
	Select = sound("Switch pop", pop, 0.15, 1.21),
	Reward = sound("Reward bubbles", pop, 0.18, 1.26),
}
for _, voice in voices do
	if voice.SoundId == pop then
		voice.PlaybackRegionsEnabled = true
		voice.PlaybackRegion = NumberRange.new(0, 0.24)
	end
end
local function play(key)
	local voice = voices[key]
	voice.TimePosition = 0
	voice:Play()
end
function Audio.preview()
	play("Select")
end
function Audio.menu(open)
	play(if open then "Open" else "Close")
end
function Audio.interact()
	play("Interact")
end
function Audio.reward(pitch)
	play("Open")
	task.delay(0.10, function()
		voices.Reward.PlaybackSpeed = pitch
		play("Reward")
	end)
end
-- Each ore has its own short attack. Gem finds finish with a rising pop cadence.
local signatures = {
	{ "Stone", 9118628948, 0.15, 0.98, 0.18 },
	{ "Coal", 9125869505, 0.13, 0.94, 0.22 },
	{ "Copper", 9118608006, 0.19, 1.45, 0.33 },
	{ "Iron", 9116673915, 0.14, 0.95, 0.40 },
	{ "Gold", 9113849492, 0.19, 1.18, 0.48 },
	{ "Diamond", 9116394545, 0.20, 1.34, 0.70 },
	{ "Emerald", 9116395089, 0.22, 1.08, 0.85 },
	{ "Amethyst", 9116394545, 0.20, 1.18, 0.74 },
	{ "Sapphire", 9116395089, 0.20, 1.42, 0.77 },
	{ "Emberglass", 9116394545, 0.23, 0.90, 0.75 },
	{ "Starfall", 9116395089, 0.24, 1.6, 0.90 },
}
-- A padded landing gives loose earth a short, low thud.
local dirt = sound("Dirt break", "rbxasset://sounds/action_jump_land.mp3", 0.34, 0.87)
dirt.PlaybackRegionsEnabled = true
dirt.PlaybackRegion = NumberRange.new(0.026, 0.20)
local grit = sound("Rock grit", "rbxassetid://9114657970", 0.16, 1.02)
grit.PlaybackRegionsEnabled, grit.PlaybackRegion = true, NumberRange.new(0.04, 0.19)
local variation = Random.new()

local oreVoices = {}
for _, cue in signatures do
	local s = sound(cue[1] .. " break", "rbxassetid://" .. cue[2], cue[3], cue[4])
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(0, cue[5])
	oreVoices[cue[1]] = s
end

-- Short contact transients leave room for the longer break and discovery sounds.
local function tap(source, from, to, pitch, volume)
	return { asset = source.SoundId, region = NumberRange.new(from, to), pitch = pitch, volume = volume }
end
local digSounds = {
	Dirt = { tap(dirt, 0.033, 0.16, 1.06, 0.23) },
	Stone = { tap(oreVoices.Stone, 0.025, 0.15, 0.90, 0.20) },
	Coal = { tap(oreVoices.Coal, 0, 0.13, 0.86, 0.18) },
	Copper = { tap(oreVoices.Copper, 0, 0.12, 1.16, 0.19), tap(oreVoices.Iron, 0.02, 0.10, 1.42, 0.06) },
	Iron = { tap(oreVoices.Iron, 0.012, 0.16, 0.84, 0.19) },
	Gold = { tap(oreVoices.Stone, 0.03, 0.11, 1.08, 0.13), tap(oreVoices.Gold, 0.09, 0.17, 1.18, 0.13) },
	Diamond = { tap(oreVoices.Copper, 0, 0.09, 1.52, 0.14), tap(oreVoices.Diamond, 0.12, 0.31, 1.55, 0.12) },
	Emerald = { tap(oreVoices.Stone, 0.025, 0.14, 1.18, 0.15), tap(oreVoices.Emerald, 0.15, 0.34, 1.03, 0.12) },
	Amethyst = { tap(oreVoices.Copper, 0, 0.10, 0.92, 0.14), tap(oreVoices.Amethyst, 0.67, 0.83, 0.94, 0.14) },
	Sapphire = { tap(oreVoices.Iron, 0.012, 0.11, 1.22, 0.13), tap(oreVoices.Sapphire, 0.36, 0.55, 1.42, 0.13) },
	Emberglass = { tap(oreVoices.Coal, 0.38, 0.51, 1.22, 0.17), tap(oreVoices.Emberglass, 0.66, 0.82, 0.76, 0.13) },
	Starfall = { tap(oreVoices.Gold, 0.09, 0.17, 1.58, 0.13), tap(oreVoices.Starfall, 1.32, 1.53, 1.86, 0.17) },
}
function Audio.dig(ore, emitter)
	local layers = digSounds[ore]
	if not layers then
		return
	end
	for i, cue in layers do
		local name = if i == 1 then "Pick impact" else "Mineral ring"
		local voice = emitter:FindFirstChild(name)
		if not voice then
			voice = Instance.new("Sound")
			voice.Name, voice.SoundGroup, voice.PlaybackRegionsEnabled = name, sfxChannel, true
			voice.RollOffMode, voice.RollOffMinDistance, voice.RollOffMaxDistance = Enum.RollOffMode.Linear, 12, 48
			voice.Parent = emitter
		end
		voice.SoundId, voice.PlaybackRegion, voice.Volume = cue.asset, cue.region, cue.volume
		voice.PlaybackSpeed = cue.pitch * variation:NextNumber(0.97, 1.03)
		voice.TimePosition = cue.region.Min
		voice:Play()
	end
end
local notes = {}
for i = 1, 5 do
	local voice = voices.Reward:Clone()
	voice.Name, voice.PlaybackSpeed, voice.Parent = "Discovery note " .. i, 1.15 * 2 ^ ((i * 4) / 12), bus
	notes[i] = voice
end
function Audio.origins(parent)
	if music.IsPlaying then
		music:Stop()
	end
	local soundtrack = require(script.Parent.Starfall.Soundtrack)
	return soundtrack(parent, musicChannel, sfxChannel)
end
local unlockNotes = {}
for i = 1, 4 do
	local voice = voices.Reward:Clone()
	voice.Name, voice.Volume, voice.Parent = "Unlock note " .. i, 0.20, bus
	unlockNotes[i] = voice
end
function Audio.unlock(isTitle)
	local pitches = if isTitle then { 1.05, 1.32, 1.57, 2.10 } else { 0.96, 1.21, 1.44 }
	for i, pitch in pitches do
		task.delay((i - 1) * 0.115, function()
			local note = unlockNotes[i]
			note.PlaybackSpeed, note.TimePosition = pitch, 0
			note:Play()
		end)
	end
end

local flourishEnd, flourishRank, flourishSerial = 0, 0, 0
function Audio.ore(loot)
	if loot.Dirt then
		dirt.PlaybackSpeed = variation:NextNumber(0.83, 0.91)
		dirt.TimePosition = dirt.PlaybackRegion.Min
		dirt:Play()
	end
	if loot.Stone or loot.Coal or loot.Copper or loot.Iron then
		grit.PlaybackSpeed, grit.TimePosition = variation:NextNumber(1.0, 1.18), 0.04
		grit:Play()
	end
	local delay, best = 0, 0
	for rank, cue in signatures do
		if loot[cue[1]] then
			best = rank
			local voice = oreVoices[cue[1]]
			task.delay(delay, function()
				voice.TimePosition = 0
				voice:Play()
			end)
			delay += 0.025
		end
	end
	local now = os.clock()
	if best < 5 or (now < flourishEnd and best <= flourishRank) then
		return
	end
	local noteCount = if best == #signatures then 5 elseif best >= 8 then 4 else best - 4
	flourishRank, flourishEnd, flourishSerial = best, now + delay + noteCount * 0.09, flourishSerial + 1
	local serial = flourishSerial
	for note = 1, noteCount do
		task.delay(delay + note * 0.09, function()
			if flourishSerial == serial then
				local chime = notes[note]
				chime:Stop()
				chime:Play()
			end
		end)
	end
end
local lastHover = 0
function Audio.bind(button, cue)
	button.MouseEnter:Connect(function()
		if
			button.Interactable
			and Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
			and os.clock() - lastHover > 0.09
		then
			lastHover = os.clock()
			play("Hover")
		end
	end)
	if cue == "Mine" then
		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				play(cue)
			end
		end)
	else
		button.Activated:Connect(function()
			play(cue or "Open")
		end)
	end
end
return Audio
