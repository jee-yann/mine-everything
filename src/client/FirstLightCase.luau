local Gui = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local W = require(script.Parent.Widgets)
local Icons = require(script.Parent.Icons)
local Audio = require(script.Parent.HarborAudio)

return function(hud, name)
	local root = hud.root
	local motion = hud.player:GetAttribute("MenuMotion") ~= false and not Gui.ReducedMotionEnabled
	local group = W.fadeGroup(root, "First Light case", 350, 132)
	group.ZIndex = 35
	W.anchor(group, 0.5, 0.5, UDim2.fromScale(0.5, 0.41))
	local fit = W.scale(group)
	fit.Scale = math.min(1.12, (root.AbsoluteSize.X - 12) / 350, (root.AbsoluteSize.Y - 8) / 132)
	local card = W.frame(group, "Gift", 4, 4, 342, 124, W.panel, 14)
	W.enamel(card, Color3.fromRGB(23, 84, 99), W.panel)
	W.stroke(card, W.gold, 2)
	local well = W.frame(card, "Case display", 8, 8, 104, 108, W.ink, 10)
	local chest = W.frame(well, "Tool case", 12, 58, 80, 31, W.ocean, 5)
	W.stroke(chest, W.aqua, 1.4)
	for _, x in { 12, 59 } do
		W.frame(chest, "Brass band", x, 0, 7, 30, W.gold, 1)
	end
	local lid = W.frame(well, "Lid", 10, 44, 84, 17, W.ocean, 4)
	W.stroke(lid, W.aqua, 1.5)
	W.frame(lid, "Clasp", 37, 10, 10, 11, W.gold, 2)
	local pick = Icons.draw(well, "Power", 24, 20, 54, W.gold)
	pick.Visible = false
	local typeLabel = W.text(card, "FIRST UPGRADE GIFT", 125, 9, 206, 17, 14, W.gold, true)
	local title = W.title(card, "Your pick case", 124, 26, 208, 32, 24, W.white, true)
	local hint = W.text(card, "A gift from the workshop", 125, 57, 207, 19, 15, W.muted, true)
	local action = Instance.new("TextButton")
	action.Name, action.Text = "Case action", "Open case"
	action.Font, action.TextSize, action.TextColor3 = Enum.Font.FredokaOne, 19, W.ink
	action.Position, action.Size = UDim2.fromOffset(124, 77), UDim2.fromOffset(200, 42)
	action.BackgroundColor3, action.BorderSizePixel = W.gold, 0
	W.round(action, 8)
	action.Parent = card

	local prior = Gui.SelectedObject
	-- The purchase screen already owns gamepad focus. In the mine, the gift
	-- stays passive until selected and the player can continue using the pick.
	if Input.PreferredInput == Enum.PreferredInput.Gamepad and hud.overlay.Visible and not Gui.MenuIsOpen then
		Gui.SelectedObject = action
	end
	local revealed, closed = false, false
	local deadline = os.clock() + 2.7
	local function reveal()
		if revealed then return end
		revealed, deadline = true, os.clock() + 2.5
		typeLabel.Text, title.Text = "LEGENDARY PICK AURA", name
		hint.Text = if hud.player:GetAttribute("FirstLight") then "Equipped on your pick!" else "Equip it in Supplies"
		action.Text, action.BackgroundColor3 = "Done", W.aqua
		pick.Visible = true
		if motion then
			pick.Position = UDim2.fromOffset(24, 44)
			W.tween(pick, 0.28, { Position = UDim2.fromOffset(24, 17) })
			W.tween(lid, 0.20, { Position = UDim2.fromOffset(8, 14), Rotation = -11 })
			for i = 1, 5 do
				local angle = math.rad(-150 + (i - 1) * 30)
				local spark = W.frame(well, "Aura spark", 50, 46, 4, 4, if i % 2 == 0 then W.aqua else W.gold, 1)
				spark.Rotation = 45
				W.tween(spark, 0.46, { Position = UDim2.fromOffset(50 + 43 * math.cos(angle), 46 + 39 * math.sin(angle)), BackgroundTransparency = 1 })
			end
		else
			lid.Position, lid.Rotation = UDim2.fromOffset(8, 14), -11
		end
		Audio.unlock(false)
	end
	action.Activated:Connect(function()
		if revealed then closed = true else reveal() end
	end)
	while group.Parent and root.Parent and not closed do
		if os.clock() >= deadline then
			if revealed then break end
			reveal()
		end
		task.wait(0.05)
	end
	if Gui.SelectedObject == action then
		Gui.SelectedObject = if prior and prior.Parent and hud.overlay.Visible then prior else nil
	end
	group:Destroy()
end
