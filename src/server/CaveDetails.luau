local Players = game:GetService("Players")
local Details = {}
function Details.place(grid, support, feature)
	local lava = feature == "Lava"
	local item = Instance.new("Part")
	item.Name = if lava then "Lava seam" elseif feature == "Egg" then "Drake egg" else "Survey cache"
	item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch = true, false, false, lava
	item.Size = if lava
		then Vector3.new(support.Size.X - 0.06, 0.20, support.Size.Z - 0.06)
		else Vector3.new(2.35, 1.5, 1.65)
	if feature == "Egg" then
		item.Shape, item.Size = Enum.PartType.Ball, Vector3.new(1.65, 2.2, 1.65)
	end
	item.Material = if lava or feature == "Egg" then Enum.Material.Neon else Enum.Material.WoodPlanks
	item.Color = if lava
		then Color3.fromRGB(255, 88, 24)
		elseif feature == "Egg" then Color3.fromRGB(173, 116, 255)
		else Color3.fromRGB(175, 113, 60)
	item.Position = support.Position + Vector3.yAxis * (support.Size.Y + item.Size.Y) / 2
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Brightness, lamp.Range, lamp.Parent =
		item.Color, if lava then 0.85 else 0.48, if lava then 11 else 8, item
	if lava then
		item.Touched:Connect(function(body)
			local player = Players:GetPlayerFromCharacter(body.Parent)
			if player and grid.onFeature then
				grid.onFeature(player, feature, item)
			end
		end)
	else
		if feature == "Cache" then
			-- A chunky surveyor's crate in the game's blocky, ink-edged style: flat painted body, a
			-- darker lid, citrine corner caps and a glowing citrine on the lid. Built from plain
			-- blocks rather than a planked prop.
			item.Material, item.Color = Enum.Material.SmoothPlastic, Color3.fromRGB(176, 112, 64)
			local function block(name, size, offset, color, material)
				local b = Instance.new("Part")
				b.Name, b.Anchored, b.CanCollide, b.CanTouch, b.CanQuery = name, true, false, false, false
				b.Size, b.Position = size, item.Position + offset
				b.Color, b.Material = color, material or Enum.Material.SmoothPlastic
				b.Parent = item
				return b
			end
			local s = item.Size
			block("Lid", Vector3.new(s.X + 0.12, 0.42, s.Z + 0.12), Vector3.new(0, s.Y / 2 + 0.05, 0), Color3.fromRGB(120, 70, 40))
			block("Band", Vector3.new(s.X + 0.06, 0.22, s.Z + 0.06), Vector3.new(0, -0.1, 0), Color3.fromRGB(62, 40, 30))
			for _, x in { -1, 1 } do
				for _, z in { -1, 1 } do
					block("Corner cap", Vector3.new(0.34, s.Y + 0.5, 0.34),
						Vector3.new(x * (s.X / 2 - 0.08), 0.05, z * (s.Z / 2 - 0.08)), Color3.fromRGB(255, 199, 74))
				end
			end
			local gem = block("Citrine", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, s.Y / 2 + 0.42, 0),
				Color3.fromRGB(255, 214, 92), Enum.Material.Neon)
			gem.Orientation = Vector3.new(0, 45, 45)
			local outline = Instance.new("SelectionBox")
			outline.Name, outline.Adornee, outline.Color3 = "Ink edge", item, Color3.fromRGB(26, 22, 30)
			outline.LineThickness, outline.SurfaceTransparency, outline.Parent = 0.05, 1, item
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText, prompt.ActionText, prompt.MaxActivationDistance, prompt.HoldDuration =
			item.Name, if feature == "Egg" then "Hatch" else "Open", 9, 0.25
		prompt.Triggered:Connect(function(player)
			if item.Parent and grid.onFeature and grid.onFeature(player, feature, item) then
				item:Destroy()
			end
		end)
		prompt.Parent = item
	end
	item.Parent = support
end
return Details
