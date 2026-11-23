local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local clear = NumberSequence.new(1)

-- Replication continues behind the film. Remember the most recent value so
-- equipment that changes in the middle of a shot comes back in its new state.
local function hold(item, key, value)
	local previous = item[key]
	item[key] = value
	local connection = item:GetPropertyChangedSignal(key):Connect(function()
		if item[key] ~= value then
			previous = item[key]
			item[key] = value
		end
	end)
	return function()
		connection:Disconnect()
		if item[key] == value then
			item[key] = previous
		end
	end
end

local function conceal(item, viewer, silent)
	if item:IsA("Sound") then
		-- Roblox updates movement volumes while a character changes state.
		-- Muting this route lets its controller keep the right playback level.
		return hold(item, "SoundGroup", silent)
	elseif item:IsA("AudioPlayer") then
		return hold(item, "Volume", 0)
	elseif viewer then
		return nil
	elseif item:IsA("BasePart") or item:IsA("Decal") then
		return hold(item, "LocalTransparencyModifier", 1)
	elseif item:IsA("Humanoid") then
		return hold(item, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)
	elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") then
		return hold(item, "Transparency", clear)
	elseif item:IsA("LayerCollector") or item:IsA("Light") or item:IsA("Highlight")
		or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") then
		return hold(item, "Enabled", false)
	elseif item:IsA("ForceField") or item:IsA("HandleAdornment") then
		return hold(item, "Visible", false)
	end
	return nil
end

local function hideCharacter(character, viewer, silent)
	local hidden = {}
	local function added(item)
		if not hidden[item] then hidden[item] = conceal(item, viewer, silent) end
	end
	local function removed(item)
		if hidden[item] then
			hidden[item]()
			hidden[item] = nil
		end
	end
	local adding = character.DescendantAdded:Connect(added)
	local removing = character.DescendantRemoving:Connect(removed)
	for _, item in character:GetDescendants() do added(item) end
	return function()
		adding:Disconnect()
		removing:Disconnect()
		for _, restore in hidden do restore() end
	end
end

return function(viewer)
	local silent = Instance.new("SoundGroup")
	silent.Name, silent.Volume, silent.Parent = "Character sounds during the film", 0, game:GetService("SoundService")
	local watching = {}
	local function watch(player)
		if watching[player] then return end
		local restore
		local function swap(character)
			if restore then restore() end
			restore = if character then hideCharacter(character, player == viewer, silent) else nil
		end
		local changed = player:GetPropertyChangedSignal("Character"):Connect(function() swap(player.Character) end)
		watching[player] = function()
			changed:Disconnect()
			swap(nil)
		end
		swap(player.Character)
	end
	local function forget(player)
		if watching[player] then
			watching[player]()
			watching[player] = nil
		end
	end
	local added = Players.PlayerAdded:Connect(watch)
	local removing = Players.PlayerRemoving:Connect(forget)
	for _, player in Players:GetPlayers() do watch(player) end
	local bubbles = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
	local restoreBubbles = bubbles and hold(bubbles, "Enabled", false)
	return function()
		added:Disconnect()
		removing:Disconnect()
		for _, stop in watching do stop() end
		silent:Destroy()
		if restoreBubbles then restoreBubbles() end
	end
end
