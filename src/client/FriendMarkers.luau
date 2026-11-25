--!strict
-- Friends stay findable across the mine: a small round headshot floats over each friend's
-- character at any distance (Roblox name tags fade out past 100 studs), and hovering or tapping
-- it shows their name, title, level and the value of their current haul. Headshots stay small
-- so a crowded shaft isn't covered in labels. In an unpublished Studio test every other miner
-- counts as a friend so the markers can be checked.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Expeditions = require(Shared.Expeditions)
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local W = require(script.Parent.Widgets)

local MARKER, CARD = 30, Vector2.new(196, 74)

return function(player: Player, hud: any)
	local practice = RunService:IsStudio() and game.GameId == 0
	local markers: { [Player]: BillboardGui } = {}
	local card = W.frame(hud.root, "Friend card", 0, 0, CARD.X, CARD.Y, W.panel, 10)
	card.Visible, card.ZIndex = false, 30
	W.stroke(card, W.aqua, 2)
	local name = W.title(card, "", 10, 4, CARD.X - 20, 24, 18, W.white, true)
	local title = W.text(card, "", 10, 27, CARD.X - 20, 18, 14, W.violet, true)
	local haul = W.text(card, "", 10, 46, CARD.X - 20, 20, 14, W.gold, true)
	for _, label in { name, title, haul } do
		label.ZIndex = 31
	end
	local shown: Player?

	local function describe(friend: Player)
		local level = friend:GetAttribute("Level") or 1
		local rank = Expeditions.ranks[friend:GetAttribute("EquippedTitle") or 1]
		name.Text = friend.DisplayName
		title.Text = string.format("%s  ·  Lv %d", if rank then rank.name else "Miner", level)
		local value = (friend:GetAttribute("BagValue") or 0) * Rebirth.saleMultiplier(friend)
		haul.Text = string.format("Haul %s / %s  ·  %s G", W.number(friend:GetAttribute("Used") or 0),
			W.number(friend:GetAttribute("PackSlots") or 8), W.number(value))
	end

	local function show(friend: Player?, at: Vector2?)
		shown = friend
		card.Visible = friend ~= nil and at ~= nil
		if friend and at then
			describe(friend)
			local bounds = hud.root.AbsoluteSize
			card.Position = UDim2.fromOffset(
				math.clamp(at.X - CARD.X / 2, 4, math.max(4, bounds.X - CARD.X - 4)),
				math.clamp(at.Y - CARD.Y - 22, 4, math.max(4, bounds.Y - CARD.Y - 4))
			)
		end
	end

	-- Billboard contents report positions in their own canvas, so the card follows the marker's
	-- projected position instead.
	local function screenPoint(gui: BillboardGui): Vector2?
		local adornee = gui.Adornee :: BasePart?
		local camera = workspace.CurrentCamera
		if not adornee or not camera then
			return nil
		end
		local at, onScreen = camera:WorldToViewportPoint(adornee.Position + gui.StudsOffsetWorldSpace)
		if not onScreen then
			return nil
		end
		local inset = hud.root.AbsolutePosition
		return Vector2.new(at.X, at.Y) - inset
	end

	local function attach(friend: Player)
		local character = friend.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local gui = markers[friend] or Instance.new("BillboardGui")
		gui.Name = "Friend marker"
		gui.Size = UDim2.fromOffset(MARKER, MARKER)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
		gui.AlwaysOnTop, gui.Active, gui.LightInfluence = true, true, 0
		gui.MaxDistance = 4000
		gui.ResetOnSpawn = false
		gui.Adornee = root
		if not gui:FindFirstChild("Headshot") then
			local face = Instance.new("ImageButton")
			face.Name, face.Size, face.BackgroundColor3 = "Headshot", UDim2.fromScale(1, 1), W.panel
			face.AutoButtonColor = false
			local corner = Instance.new("UICorner")
			corner.CornerRadius, corner.Parent = UDim.new(1, 0), face
			W.stroke(face, W.aqua, 2)
			face.Parent = gui
			task.spawn(function()
				local ok, image = pcall(Players.GetUserThumbnailAsync, Players, math.max(friend.UserId, 1),
					Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				if ok then
					face.Image = image
				end
			end)
			local function hover()
				show(friend, screenPoint(gui))
			end
			face.MouseEnter:Connect(hover)
			face.Activated:Connect(function()
				if shown == friend then
					show(nil)
				else
					hover()
				end
			end)
			face.MouseLeave:Connect(function()
				if shown == friend then
					show(nil)
				end
			end)
		end
		gui.Parent = player:WaitForChild("PlayerGui")
		markers[friend] = gui
	end

	local function track(friend: Player)
		if friend == player then
			return
		end
		task.spawn(function()
			local isFriend = practice
			if not isFriend then
				local ok, result = pcall(player.IsFriendsWith, player, friend.UserId)
				isFriend = ok and result
			end
			if not isFriend then
				return
			end
			friend.CharacterAdded:Connect(function()
				task.wait()
				attach(friend)
			end)
			attach(friend)
		end)
	end

	for _, other in Players:GetPlayers() do
		track(other)
	end
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(other)
		if markers[other] then
			markers[other]:Destroy()
			markers[other] = nil
		end
		if shown == other then
			show(nil)
		end
	end)
	RunService.Heartbeat:Connect(function()
		local friend = shown
		if friend and markers[friend] then
			show(friend, screenPoint(markers[friend]))
		end
	end)
end
