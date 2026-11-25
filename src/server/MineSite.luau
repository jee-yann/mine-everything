local MineSite = {}
local counterStyles = {
	Sell = { "SELL ORE", Color3.fromRGB(255, 199, 83) },
	Shop = { "UPGRADE", Color3.fromRGB(100, 230, 221) },
	Jobs = { "JOBS", Color3.fromRGB(216, 155, 253) },
	Store = { "OUTFITTERS", Color3.fromRGB(255, 154, 184) },
	Book = { "ORE INDEX", Color3.fromRGB(148, 237, 156) },
	Supplies = { "SUPPLIES", Color3.fromRGB(255, 194, 108) },
}
-- The plate a customer stands on: the service's name in bright type with a mark either side.
local function markCounter(pad, style)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face, gui.SizingMode = "Interaction pad", Enum.NormalId.Top, Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize, gui.LightInfluence, gui.Brightness, gui.Parent = Vector2.new(312, 600), 0, 1.7, pad
	local panel = Instance.new("Frame")
	panel.Size, panel.BackgroundTransparency, panel.ClipsDescendants = UDim2.fromScale(1, 1), 1, true
	panel.Parent = gui
	-- The face's long side runs up the canvas, so everything is laid out on its side.
	local label = Instance.new("TextLabel")
	label.Text, label.Font, label.TextScaled = style[1], Enum.Font.FredokaOne, true
	label.Rotation, label.AnchorPoint, label.Position = 90, Vector2.new(0.5, 0.5), UDim2.fromScale(0.56, 0.5)
	label.Size, label.BackgroundTransparency = UDim2.fromOffset(540, 150), 1
	label.TextColor3 = Color3.fromRGB(255, 253, 240)
	local outline = Instance.new("UIStroke")
	outline.Thickness, outline.Color, outline.LineJoinMode, outline.Parent =
		9, style[2]:Lerp(Color3.fromRGB(20, 18, 40), 0.72), Enum.LineJoinMode.Round, label
	label.Parent = panel
	-- Chevrons toward the counter.
	for i = 1, 3 do
		local arrow = Instance.new("TextLabel")
		arrow.Name, arrow.Text, arrow.Font, arrow.TextSize = "Arrow", "▲", Enum.Font.FredokaOne, 62
		arrow.Rotation, arrow.AnchorPoint = 90, Vector2.new(0.5, 0.5)
		arrow.Size, arrow.Position = UDim2.fromOffset(90, 70), UDim2.new(0.86, 0, 0.5, (i - 2) * 96)
		arrow.BackgroundTransparency, arrow.TextColor3, arrow.TextTransparency = 1, style[2], if i == 2 then 0 else 0.35
		arrow.Parent = panel
	end
	pad:SetAttribute("AuraColor", style[2])
	pad:AddTag("MiningInteractionPad")
end

function MineSite.bind(map, world)
	-- The surface is authored in Workspace so it can be explored in edit mode.
	map:PivotTo(CFrame.new(world.origin))
	local market = map["Shore market"]
	local harbor = map["Harbor Plaza"]
	local stations = {
		Sell = market.Sell["Service mat"].Service,
		Shop = market.Upgrades["Service mat"].Service,
	}
	for _, name in { "Jobs", "Store", "Book", "Supplies" } do
		stations[name] = harbor[name].Counter.Service
	end
	local sell = stations.Sell
	sell:AddTag("OreSellPrompt")
	sell.ActionText, sell.ObjectText = "Tap to choose ores", "Hold to sell whole pack"
	sell.HoldDuration, sell.ClickablePrompt = 0.65, true
	for key, prompt in stations do
		markCounter(prompt.Parent, counterStyles[key])
	end
	return {
		spawn = map["Sand path and bridge"].Landing,
		stations = stations,
		court = harbor["Miners Court"],
	}
end

return MineSite
