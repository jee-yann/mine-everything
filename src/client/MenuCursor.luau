-- While a menu is open the pointer is an arrow, and a hand only over a button that can be pressed.
-- Roblox shows its hand over any panel that blocks clicks, so the menu draws its own pointer.
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Run = game:GetService("RunService")

local folder = "rbxasset://textures/Cursors/KeyboardMouse/"
local arrow, hand, beam = folder .. "ArrowFarCursor.png", folder .. "ArrowCursor.png", folder .. "IBeamCursor.png"

return function(hud)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.ScreenInsets, gui.DisplayOrder = "Menu pointer", false, Enum.ScreenInsets.None, 50
	local pointer = Instance.new("ImageLabel")
	pointer.Name, pointer.BackgroundTransparency, pointer.Image = "Pointer", 1, arrow
	pointer.AnchorPoint, pointer.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(64, 64)
	pointer.Parent = gui
	gui.Enabled, gui.Parent = false, hud.root.Parent.Parent

	local function shapeAt(at)
		for _, item in hud.player.PlayerGui:GetGuiObjectsAtPosition(at.X, at.Y) do
			if item:IsA("TextBox") then return beam end
			if item:IsA("GuiButton") then
				return if item.Interactable and item.Visible then hand else arrow
			end
		end
		return arrow
	end

	local showing = false
	local function set(on)
		if on == showing then return end
		showing = on
		gui.Enabled, Input.MouseIconEnabled = on, not on
	end
	Run.RenderStepped:Connect(function()
		local open = hud.overlay.Visible and Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
			and not GuiService.MenuIsOpen and not (hud.chatInput and hud.chatInput.IsFocused)
		local at = open and Input:GetMouseLocation()
		-- The top bar belongs to Roblox and keeps the normal pointer.
		local inset = GuiService:GetGuiInset()
		if not at or at.Y < inset.Y then
			set(false)
			return
		end
		set(true)
		pointer.Position = UDim2.fromOffset(at.X, at.Y)
		pointer.Image = shapeAt(at - inset)
	end)
end
