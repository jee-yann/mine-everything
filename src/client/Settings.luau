local Slider = require(script.Parent.Slider)
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Preferences = require(game:GetService("ReplicatedStorage").Shared.Preferences)
local W = require(script.Parent.Widgets)
local Audio = require(script.Parent.HarborAudio)
local Settings = {}
Settings.__index = Settings

function Settings.new(player, net)
	local self = setmetatable({ values = table.clone(Preferences.defaults), player = player, net = net }, Settings)
	local function load()
		if not player:GetAttribute("ProfileReady") then
			return
		end
		for key in Preferences.defaults do
			local value = player:GetAttribute(key)
			if Preferences.valid(key, value) then
				self.values[key] = value
			end
		end
		Audio.volume("MusicVolume", if self.values.MusicMuted then 0 else self.values.MusicVolume)
		Audio.volume("SfxVolume", if self.values.SfxMuted then 0 else self.values.SfxVolume)
	end
	player:GetAttributeChangedSignal("ProfileReady"):Connect(load)
	load()
	return self
end

local function speakerIcon(button)
	W.frame(button, "Speaker base", 8, 18, 10, 10, W.ink, 2)
	local horn = W.frame(button, "Horn", 13, 13, 11, 20, W.ink)
	horn.ClipsDescendants, horn.BackgroundTransparency = true, 1
	local cone = W.frame(horn, "Cone", 3, 3, 15, 15, W.ink, 2)
	cone.Rotation = 45
	local waves = W.frame(button, "Waves", 27, 13, 12, 20, W.ink)
	waves.BackgroundTransparency = 1
	for i, angle in { -35, 0, 35 } do
		local ray = W.frame(waves, "Ray", if i == 2 then 3 else 0, (i - 1) * 7 + 2, 7, 3, W.ink, 2)
		ray.Rotation = angle
	end
	local slash = W.frame(button, "Mute slash", 7, 20, 31, 4, W.white, 2)
	slash.Rotation, slash.ZIndex = -48, 2
	W.stroke(slash, W.ink, 1.5)
	return waves, slash
end

function Settings:slider(menu, i, key, muteKey, title, tint)
	local row = W.frame(menu.list, title, 1, 1 + (i - 1) * 69, 447, 62, W.card, 10)
	W.enamel(row, tint:Lerp(W.panel, 0.68), W.panel)
	W.title(row, title, 14, 1, 216, 26, 19, W.white, true)
	local percent = W.title(row, "", 302, 1, 75, 26, 17, tint)
	local mute = W.button(row, "Mute", 390, 9, 45, 44, tint, "", "Select")
	local waves, slash = speakerIcon(mute)
	local paint
	local function draw()
		local value, muted = self.values[key], self.values[muteKey]
		local ready = self.player:GetAttribute("ProfileReady") == true and not self.resetPending
		paint(value / 100, ready and not muted)
		percent.Text, percent.TextColor3 = value .. "%", if muted then W.muted else tint
		waves.Visible, slash.Visible = not muted, muted
		mute.BackgroundColor3 = if muted then W.muted else tint
		mute.Interactable = ready
	end
	local function change(value)
		self.values[key] = math.clamp(math.round(value), 0, 100)
		Audio.volume(key, if self.values[muteKey] then 0 else self.values[key])
		draw()
	end
	paint = Slider.new(menu, row, UDim2.fromOffset(8, 24), UDim2.fromOffset(367, 36), tint,
		function(fraction) change(fraction * 100) end,
		function(step) change(self.values[key] + step * 5) end,
		function()
			self.net.Action:FireServer("Preference", key, self.values[key])
			if key == "SfxVolume" and not self.values[muteKey] then Audio.preview() end
		end)
	mute.Activated:Connect(function()
		local muted = not self.values[muteKey]
		self.values[muteKey] = muted
		Audio.volume(key, if muted then 0 else self.values[key])
		self.net.Action:FireServer("Preference", muteKey, muted)
		draw()
		if key == "SfxVolume" and not muted then Audio.preview() end
	end)
	table.insert(menu.updates, draw)
end

function Settings:resetRow(menu)
	local row = W.frame(menu.list, "Reset progress", 1, 208, 447, 62, W.card, 10)
	W.enamel(row, W.ruby:Lerp(W.panel, 0.45), W.panel)
	local title = W.title(row, "Reset progress", 14, 5, 282, 25, 20, W.white, true)
	local detail = W.text(row, "Start this miner again at level 1.", 14, 32, 297, 21, 14, W.muted, true)
	local review = W.button(row, "Review", 322, 9, 113, 44, W.muted, "Reset…", "Select")
	local erase = W.button(row, "Erase", 165, 9, 145, 44, W.ruby, "Erase progress", "Select")
	erase.TextColor3 = W.white
	local revision
	local function draw()
		local status = self.player:GetAttribute("SaveStatus")
		local ready = self.player:GetAttribute("ProfileReady") and not self.resetPending
			and (status == "Practice session" or status == "Saving enabled" or status == "Save delayed")
		review.Interactable, erase.Interactable = ready == true, ready == true
		erase.Visible = revision ~= nil and not self.resetPending
		review.Text = if self.resetPending then "Resetting…" elseif revision then "Cancel" else "Reset…"
		title.Text = if revision then "Start over?" else "Reset progress"
		detail.Text = if revision then "This is permanent." elseif ready or self.resetPending
			then "Start this miner again at level 1." else "Available with a loaded save or in practice."
	end
	review.Activated:Connect(function()
		if menu.closing or self.resetPending then return end
		revision = if revision == nil then self.player:GetAttribute("ProgressResets") or 0 else nil
		menu.status.Text = if revision then "Erase gold, gear, skills, discoveries and all other progress?" else ""
		draw()
	end)
	erase.Activated:Connect(function()
		if revision == nil or self.resetPending or menu.closing then return end
		self.resetPending = true
		self.net.Action:FireServer("ResetProgress", revision)
		revision = nil
		menu.status.Text = "Resetting your miner…"
		menu:refresh()
	end)
	table.insert(menu.updates, draw)
end

function Settings:build(menu)
	self:slider(menu, 1, "MusicVolume", "MusicMuted", "Music volume", W.aqua)
	self:slider(menu, 2, "SfxVolume", "SfxMuted", "Sound effects", W.gold)
	local _, detail, button = menu:row(3, "Menu animations", "Settings", W.violet)
	detail.Text = "Slide panels in and out"
	table.insert(menu.updates, function()
		button.Text = if self.values.MenuMotion then "On" else "Off"
		button.Interactable = self.player:GetAttribute("ProfileReady") == true and not self.resetPending
	end)
	button.Activated:Connect(function()
		self.values.MenuMotion = not self.values.MenuMotion
		menu:refresh()
		self.net.Action:FireServer("Preference", "MenuMotion", self.values.MenuMotion)
	end)
	if Config.AllowProgressReset then
		self:resetRow(menu)
	end
	local index = if Config.AllowProgressReset then 5 else 4
	local _, guideDetail, skip = menu:row(index, "First expedition", "Index", W.gold)
	table.insert(menu.updates, function()
		local step = self.player:GetAttribute("ExpeditionStep")
		skip.Interactable = step ~= nil and step ~= "Done" and step ~= "Skipped"
		skip.Text = if step == "Done" then "Finished" elseif step == "Skipped" then "Off" else "Skip guide"
		guideDetail.Text = if skip.Interactable then "Follow the mining guide in the world." else "Explore at your own pace."
	end)
	skip.Activated:Connect(function()
		if skip.Interactable then self.net.Action:FireServer("SkipExpedition") end
	end)
	local _, filmDetail, replay = menu:row(index + 1, "Where the Stars Took Root", "Book", W.violet)
	filmDetail.Text, replay.Text = "How Citrine Cove became a mining island.", "Replay intro"
	table.insert(menu.updates, function()
		replay.Interactable = self.player:GetAttribute("IntroSeen") == true and not self.resetPending
	end)
	replay.Activated:Connect(function()
		if replay.Interactable and not menu.closing then menu.replayOpening() end
	end)
	return index + 1
end
return Settings
