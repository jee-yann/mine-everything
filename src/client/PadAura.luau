local Collection = game:GetService("CollectionService")
local Prompts = game:GetService("ProximityPromptService")
local Run = game:GetService("RunService")
local Audio = require(script.Parent.HarborAudio)
local W = require(script.Parent.Widgets)
local Aura = {}
local tag = "MiningInteractionPad"

local function create(pad)
	local color = pad:GetAttribute("AuraColor") or pad.Color
	local size = pad.Size
	local y = size.Y * 0.5 + 0.18
	local center = Instance.new("Attachment")
	center.Name, center.Position, center.Parent = "Aura center", Vector3.new(0, y, 0), pad
	local wave = Instance.new("ParticleEmitter")
	wave.Name, wave.Texture = "Rising halo", "rbxasset://textures/ui/Input/Ring_padded.png"
	wave.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	wave.Color, wave.LightEmission, wave.LightInfluence = ColorSequence.new(color), 0.7, 0
	wave.Speed, wave.Lifetime = NumberRange.new(1.25), NumberRange.new(1.15)
	wave.Size = NumberSequence.new(size.Z * 0.52, size.Z * 1.05)
	wave.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.92),
		NumberSequenceKeypoint.new(0.18, 0.53),
		NumberSequenceKeypoint.new(1, 1),
	})
	wave.Enabled, wave.Parent = false, center

	local motes = Instance.new("ParticleEmitter")
	motes.Name, motes.Texture = "Aura sparks", "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color, motes.LightEmission, motes.LightInfluence =
		ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.45)), 0.75, 0
	motes.Speed, motes.Lifetime, motes.SpreadAngle =
		NumberRange.new(0.9, 1.6), NumberRange.new(0.8, 1.4), Vector2.new(7, 7)
	motes.Size = NumberSequence.new(0.43, 0.12)
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Enabled, motes.Parent = false, pad
	return { center = center, wave = wave, motes = motes, state = "far" }
end

local function pulse(aura)
	aura.wave:Emit(1)
	aura.motes:Emit(6)
end

function Aura.start(player, hud)
	local pads = {}
	local function add(pad)
		if not pads[pad] then
			pads[pad] = create(pad)
		end
	end
	Collection:GetInstanceAddedSignal(tag):Connect(add)
	Collection:GetInstanceRemovedSignal(tag):Connect(function(pad)
		local aura = pads[pad]
		if aura then
			pads[pad] = nil
			aura.center:Destroy()
			aura.motes:Destroy()
		end
	end)
	for _, pad in Collection:GetTagged(tag) do
		add(pad)
	end
	local pendingTap
	local function cancelTap()
		pendingTap = nil
	end
	local function updateSellPrompt(prompt)
		prompt.Enabled = not hud.overlay.Visible
		local blocks = player:GetAttribute("Used") or 0
		local value = (player:GetAttribute("BagValue") or 0) * (if player:GetAttribute("DoubleGold") then 2 else 1)
		prompt.ObjectText = if blocks == 0
			then "Pack empty"
			else string.format(
				"Hold to sell %s %s · +%s G",
				W.goldAmount(blocks),
				if blocks == 1 then "block" else "blocks",
				W.goldAmount(value)
			)
	end
	Collection:GetInstanceAddedSignal("OreSellPrompt"):Connect(updateSellPrompt)
	local function refreshSellPrompts()
		for _, prompt in Collection:GetTagged("OreSellPrompt") do
			updateSellPrompt(prompt)
		end
	end
	for _, attribute in { "Used", "BagValue", "DoubleGold" } do
		player:GetAttributeChangedSignal(attribute):Connect(refreshSellPrompts)
	end
	refreshSellPrompts()
	hud.overlay:GetPropertyChangedSignal("Visible"):Connect(function()
		cancelTap()
		refreshSellPrompts()
	end)
	game:GetService("UserInputService").WindowFocusReleased:Connect(cancelTap)
	game:GetService("GuiService").MenuOpened:Connect(cancelTap)
	Prompts.PromptButtonHoldBegan:Connect(function(prompt, who)
		if who == player and prompt:HasTag("OreSellPrompt") and not hud.overlay.Visible then
			pendingTap = { prompt = prompt }
		end
	end)
	Prompts.PromptHidden:Connect(function(prompt)
		if pendingTap and pendingTap.prompt == prompt then
			cancelTap()
		end
	end)
	Prompts.PromptButtonHoldEnded:Connect(function(prompt, who)
		local tap = pendingTap
		if who ~= player or not tap or tap.prompt ~= prompt then
			return
		end
		-- A completed native hold triggers the server sale. Let Triggered or Hidden
		-- cancel this release before treating it as a short tap.
		task.defer(function()
			if pendingTap == tap then
				cancelTap()
				Audio.interact()
				if pads[prompt.Parent] then
					pulse(pads[prompt.Parent])
				end
				hud:openPage("Sell")
			end
		end)
	end)
	Prompts.PromptTriggered:Connect(function(prompt, who)
		if who == player and pendingTap and pendingTap.prompt == prompt then
			cancelTap()
		end
		local aura = pads[prompt.Parent]
		if aura and who == player then
			Audio.interact()
			pulse(aura)
		end
	end)
	local elapsed = 0
	Run.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local human = char and char:FindFirstChildOfClass("Humanoid")
		for pad, aura in pads do
			local state = "far"
			if
				not hud.inOpening
				and root
				and human
				and human.Health > 0
				and (pad.Position - root.Position).Magnitude <= 85
			then
				local at = pad.CFrame:PointToObjectSpace(root.Position)
				local half = pad.Size * 0.5
				local standingHeight = math.max(human.HipHeight + root.Size.Y * 0.5, root.Size.Y * 1.5)
				local onPad = math.abs(at.X) <= half.X
					and math.abs(at.Z) <= half.Z
					and at.Y >= half.Y
					and at.Y <= half.Y + standingHeight + 0.7
					and human.FloorMaterial ~= Enum.Material.Air
				state = if onPad then "standing" else "near"
			end
			if state ~= aura.state then
				local standing, visible = state == "standing", state ~= "far"
				aura.state = state
				aura.wave.Rate, aura.motes.Rate = if standing then 0.85 else 0.45, if standing then 5 else 2.5
				aura.wave.Enabled, aura.motes.Enabled = visible, visible
				if standing then
					pulse(aura)
				end
			end
		end
	end)
end
return Aura
