local Scenery = {}
local V = Vector3.new

function Scenery.part(parent, name, cf, size, tint, material, class)
	local p = Instance.new(class or "Part")
	p.Name, p.CFrame, p.Size = name, cf, size
	p.Color, p.Material = Color3.fromHex(tint), material or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Scenery.strut(parent, name, a, b, w, h, tint, material)
	return Scenery.part(parent, name, CFrame.lookAt((a + b) / 2, b), V(w, h, (a - b).Magnitude), tint, material)
end

-- Split a drawn triangular facet at the foot of its longest edge.
function Scenery.facet(parent, name, a, b, c, tint, material)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local n = ac:Cross(ab)
	if n.Magnitude < 0.0001 then
		return
	end
	local right, back = n.Unit, bc.Unit
	local up = back:Cross(right)
	local height = math.abs(ab:Dot(up))
	for i, v in { b, c } do
		local depth = math.abs((v - a):Dot(back))
		if depth > 0.002 then
			local sign = if i == 1 then 1 else -1
			local part = Scenery.part(
				parent,
				name,
				CFrame.fromMatrix((a + v) * 0.5, right * sign, up, back * sign),
				V(0.012, height, depth),
				tint,
				material,
				"WedgePart"
			)
			part.CastShadow = false
		end
	end
end

function Scenery.light(parent, tint, range, power)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Parent = Color3.fromHex(tint), range, power, parent
	return light
end

function Scenery.group(name)
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = name, CFrame.identity
	return model
end

function Scenery.ease(t, a, b)
	local u = math.clamp((t - a) / (b - a), 0, 1)
	return u * u * (3 - 2 * u)
end

return Scenery
