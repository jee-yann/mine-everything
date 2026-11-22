return function(folder, drake, thumbnail)
	local model = Instance.new("Model")
	model.Name = if drake then "Cave drake" else "Pocket rock"
	local function piece(name, size, at, color, turn)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Color = name, size, color
		part.Material = Enum.Material.Slate
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(turn or 0))
		part.Parent = model
		return part
	end
	local stone = Color3.fromRGB(137, 147, 163)
	local face = piece("River stone", Vector3.new(1.55, 0.92, 1.12), Vector3.zero, stone, -4)
	if drake then
		face.Name, face.Color = "Drake head", Color3.fromRGB(111, 83, 179)
		piece("Body", Vector3.new(1.1, 0.85, 1.5), Vector3.new(0, -0.12, 0.8), face.Color)
		piece("Tail", Vector3.new(0.39, 0.37, 1.25), Vector3.new(0, -0.14, 2.0), face.Color)
		for _, side in { -1, 1 } do
			local wing = piece(
				"Wing",
				Vector3.new(1.32, 0.18, 0.95),
				Vector3.new(side * 0.98, 0.3, 0.8),
				Color3.fromRGB(117, 205, 222),
				side * 26
			)
			wing.Material = Enum.Material.Glass
			piece(
				"Horn",
				Vector3.new(0.20, 0.56, 0.24),
				Vector3.new(side * 0.48, 0.6, 0.1),
				Color3.fromRGB(255, 218, 142),
				-side * 18
			)
		end
	else
		piece("Crown", Vector3.new(1.16, 0.35, 0.84), Vector3.new(-0.09, 0.46, 0.01), Color3.fromRGB(159, 170, 183), -7)
	end
	for _, side in { -1, 1 } do
		piece(
			"Foot",
			Vector3.new(0.46, 0.22, 0.55),
			Vector3.new(side * 0.42, -0.46, -0.05),
			Color3.fromRGB(85, 96, 116)
		)
		piece("Eye", Vector3.new(0.16, 0.22, 0.12), Vector3.new(side * 0.35, 0.1, -0.60), Color3.fromRGB(30, 38, 54))
		piece("Glint", Vector3.one * 0.067, Vector3.new(side * 0.35 - 0.025, 0.15, -0.67), Color3.new(1, 1, 1))
	end
	piece("Smile", Vector3.new(0.22, 0.075, 0.08), Vector3.new(0, -0.10, -0.59), Color3.fromRGB(51, 54, 66))
	model.PrimaryPart, model.Parent = face, folder
	if thumbnail then return model end
	local tag = Instance.new("BillboardGui")
	tag.Name, tag.Size, tag.StudsOffsetWorldSpace, tag.MaxDistance =
		"Pet name", UDim2.fromOffset(85, 15), Vector3.yAxis, 22
	tag.Adornee, tag.Parent = face, model
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency, label.Size, label.TextSize, label.Font =
		1, UDim2.fromScale(1, 1), 12, Enum.Font.FredokaOne
	label.TextColor3, label.TextStrokeTransparency, label.Parent = Color3.fromRGB(255, 231, 188), 0.25, tag
	return model, label
end
