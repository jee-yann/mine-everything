local MineSite = {}
local counterStyles = {
	Sell = { "SELL ORE", Color3.fromRGB(255, 199, 83) },
	Shop = { "UPGRADE", Color3.fromRGB(100, 230, 221) },
	Jobs = { "JOBS", Color3.fromRGB(216, 155, 253) },
	Store = { "OUTFITTERS", Color3.fromRGB(255, 154, 184) },
	Book = { "ORE INDEX", Color3.fromRGB(148, 237, 156) },
	Supplies = { "SUPPLIES", Color3.fromRGB(255, 194, 108) },
}
local function markCounter(pad, style)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face, gui.SizingMode = "Interaction pad", Enum.NormalId.Top, Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize, gui.LightInfluence, gui.Parent = Vector2.new(120, 240), 0.15, pad
	local panel = Instance.new("Frame")
	panel.Position, panel.Size = UDim2.fromScale(0.03, 0.06), UDim2.fromScale(0.94, 0.88)
	panel.BorderSizePixel, panel.BackgroundColor3, panel.BackgroundTransparency =
		0, style[2]:Lerp(Color3.fromRGB(34, 38, 49), 0.65), 0.12
	panel.ClipsDescendants, panel.Parent = true, gui
	local edge = Instance.new("UIStroke")
	edge.Thickness, edge.Color, edge.Parent = 3, style[2], panel
	local label = Instance.new("TextLabel")
	label.Text, label.Font, label.TextScaled = style[1], Enum.Font.FredokaOne, true
	label.Rotation, label.AnchorPoint = 90, Vector2.new(0.5, 0.5)
	label.Size, label.Position = UDim2.fromOffset(180, 54), UDim2.fromScale(0.5, 0.5)
	label.BackgroundTransparency, label.TextColor3, label.TextStrokeTransparency, label.Parent =
		1, Color3.fromRGB(255, 251, 228), 0.42, panel
	pad:SetAttribute("AuraColor", style[2])
	pad:AddTag("MiningInteractionPad")
end

function MineSite.bind(map, world)
	-- The surface is authored in Workspace so it can be explored in edit mode.
	map:PivotTo(CFrame.new(world.origin))
	local market = map["Shore market"]
	local harbor = map["Harbor Plaza"]
	local landing = map["Sand path and bridge"].Landing
	local bench = require(game.ReplicatedStorage.Shared.FieldBench)
	local samples = bench.build(bench.location(landing.Position + Vector3.yAxis * 4))
	samples.Parent = map
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
	sell.HoldDuration, sell.ClickablePrompt = 0.85, true
	for key, prompt in stations do
		markCounter(prompt.Parent, counterStyles[key])
	end
	return {
		spawn = map["Sand path and bridge"].Landing,
		samples = samples:FindFirstChild("Consult samples", true),
		stations = stations,
		court = harbor["Miners Court"],
	}
end

return MineSite
