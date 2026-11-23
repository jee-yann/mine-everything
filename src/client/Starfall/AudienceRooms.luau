local S = require(script.Parent.Scenery)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local Rooms = {}

-- A hole in each set lets the gameplay camera photograph the actual player
-- and workbench, with the foreground viewers overlapping the receiver.
local function box(world, name, x, y, z, w, h, d, color, material)
	return S.part(world, name, CF(x, y, z), V(w, h, d), color, material)
end

local function shell(world, shot)
	local w, h, y = shot.width, shot.width * 9 / 16, shot.y
	local receiver = S.group("Receiver")
	receiver.Parent = world
	box(receiver, "Upper wall", 0, y + h / 2 + 20, -0.15, 100, 40, 0.24, shot.wall)
	box(receiver, "Lower wall", 0, y - h / 2 - 20, -0.15, 100, 40, 0.24, shot.wall)
	for _, side in { -1, 1 } do
		box(receiver, "Wall", side * (w / 2 + 25), y, -0.15, 50, h + 0.02, 0.24, shot.wall)
		box(receiver, "Device side", side * (w / 2 + shot.rim * 0.5), y, 0.025, shot.rim, h + shot.rim * 2, 0.16, shot.case)
		box(receiver, "Device edge", 0, y + side * (h / 2 + shot.rim * 0.5), 0.025, w, shot.rim, 0.16, shot.case)
	end
	if shot.roll then
		local sideWidth = 0.15
		for _, s in { -1, 1 } do
			box(receiver, "Phone chin", s * (w / 2 + sideWidth / 2), y, 0.06, sideWidth, h + 0.08, 0.10, shot.case)
			box(receiver, "Lavender case rail", 0, y + s * (h / 2 + 0.078), 0.045, w + 0.21, 0.039, 0.10, "B5A3D3")
			local endcap = box(receiver, "Rounded case end", s * (w / 2 + 0.128), y, 0.044, 0.14, h + 0.13, 0.105, "A18DBE")
			endcap.Shape = Enum.PartType.Ball
		end
		box(receiver, "Volume rocker", -0.26, y + h / 2 + 0.106, 0.03, 0.28, 0.035, 0.08, "CCC5D4")
		local camera = box(receiver, "Front camera", w / 2 + 0.065, y, 0.13, 0.065, 0.065, 0.025, "92A6BE")
		camera.Shape = Enum.PartType.Ball
		receiver:PivotTo(CF(0, y, 0) * A(0, 0, shot.roll) * CF(0, -y, 0))
	end
	box(world, "Floor", 0, -0.10, 5, 100, 0.20, 40, shot.floor, Enum.Material.WoodPlanks)
	box(world, "Baseboard", 0, 0.16, 0.01, 30, 0.32, 0.13, shot.trim)
	return receiver
end

local function book(world, x, y, z, w, h, d, cover, angle)
	local at = CF(x, y, z) * A(0, angle or 0, 0)
	S.part(world, "Page edges", at, V(w - 0.05, h, d - 0.04), "C8BBA3")
	for _, side in { -1, 1 } do
		S.part(world, "Book cover", at * CF(0, side * h / 2, 0), V(w, 0.035, d), cover)
	end
	S.part(world, "Binding", at * CF(-w / 2, 0, 0), V(0.045, h + 0.035, d), cover)
end

local function specimen(world, x, y, z, size)
	local at = CF(x, y, z)
	local matrix = S.part(world, "Mineral matrix", at * CF(0, 0.10 * size, 0), V(0.92, 0.30, 0.65) * size, "696474", Enum.Material.Slate)
	matrix.Shape = Enum.PartType.Ball
	for i, color in { "4BAA94", "70D3B3", "388778" } do
		local k = ({ 0.69, 1.0, 0.56 })[i] * size
		local axis = at * CF((i - 2) * 0.23 * size, 0.13 * size, (i % 2) * 0.07 * size)
			* A(0, i * 0.51, (2 - i) * 0.26)
		S.part(world, "Emerald prism", axis * CF(0, 0.29 * k, 0), V(0.22, 0.58, 0.22) * k, color)
		S.part(world, "Cut mineral face", axis * CF(0, 0.645 * k, 0), V(0.22, 0.15, 0.22) * k, "91D9BC", nil, "WedgePart")
	end
end

local function plant(world, x, y, z, size)
	box(world, "Glazed plant pot", x, y + 0.24 * size, z, 0.48 * size, 0.48 * size, 0.48 * size, "B97759")
	box(world, "Pot rim", x, y + 0.45 * size, z, 0.54 * size, 0.10 * size, 0.54 * size, "D59771")
	for i = 1, 7 do
		local angle = i * 2.4
		local at = CF(x, y + 0.47 * size, z) * A(0, angle, 0) * A(0.28 + 0.13 * (i % 3), 0, 0)
		local leaf = S.part(world, "Leaf", at * CF(0, 0.32 * size, 0), V(0.25, 0.74, 0.10) * size,
			if i % 2 == 0 then "6D9A7D" else "497E74")
		leaf.Shape = Enum.PartType.Ball
	end
end

local function framedCove(world, x, y, z, scale)
	local function tile(name, dx, dy, dz, w, h, d, color)
		return box(world, name, x + dx * scale, y + dy * scale, z + dz * scale, w * scale, h * scale, d * scale, color)
	end
	tile("Oak picture frame", 0, 0, 0, 2.02, 1.55, 0.12, "86644F")
	tile("Picture mat", 0, 0, 0.08, 1.88, 1.41, 0.06, "E5DAC1")
	tile("Harbor sky", 0, 0, 0.13, 1.61, 1.13, 0.035, "91B1B8")
	tile("Sea", 0, -0.33, 0.16, 1.61, 0.46, 0.023, "468588")
	local sun = tile("Evening sun", 0.39, 0.20, 0.17, 0.36, 0.36, 0.03, "EEC78A")
	sun.Shape = Enum.PartType.Ball
	S.part(world, "Sail in print", CF(x - 0.19 * scale, y, z + 0.19 * scale) * A(0, -math.pi / 2, 0),
		V(0.03, 0.49, 0.40) * scale, "F3DDAD", nil, "WedgePart")
	tile("Hull in print", -0.21, -0.24, 0.21, 0.67, 0.08, 0.03, "77524F")
end

local function lamp(world, x, y, z, scale, shade)
	box(world, "Lamp foot", x, y + 0.06, z, 0.72 * scale, 0.12, 0.55 * scale, "946D48")
	box(world, "Lamp stem", x, y + 0.54 * scale, z, 0.11 * scale, 0.98 * scale, 0.11 * scale, "A68257")
	local cap = box(world, "Lamp shade", x, y + 1.13 * scale, z, 0.58 * scale, 1.02 * scale, 1.02 * scale, shade)
	cap.Shape, cap.CFrame = Enum.PartType.Cylinder, cap.CFrame * A(0, 0, math.pi / 2)
end

local function bedroom(world)
	-- Moonlit window, folds in the drapes, and a small pool of light on the quilt.
	box(world, "Window frame", 2.23, 4.51, 0.01, 2.14, 2.49, 0.15, "555C85")
	box(world, "Night outside", 2.23, 4.51, 0.11, 1.94, 2.28, 0.07, "263457")
	local moon = box(world, "Moon", 2.64, 5.12, 0.21, 0.41, 0.41, 0.10, "DEE4F3")
	moon.Shape = Enum.PartType.Ball
	for i = 1, 8 do
		box(world, "Star", 1.44 + (i * 0.41) % 1.57, 4.38 + (i * 0.79) % 1.08, 0.17, 0.035, 0.04, 0.02, "A4BDE1")
	end
	box(world, "Sash", 2.18, 4.51, 0.23, 0.075, 2.23, 0.08, "5B6283")
	box(world, "Window sill", 2.23, 3.31, 0.15, 2.39, 0.12, 0.44, "6B7090")
	box(world, "Curtain pole", 2.26, 5.97, 0.26, 2.84, 0.09, 0.10, "77728C")
	for i = 0, 4 do
		local h = 0.26 + 0.12 * (i % 3)
		box(world, "Distant rooftops", 1.48 + i * 0.35, 3.46 + h / 2, 0.165, 0.36, h, 0.04, "303850")
		box(world, "Lit window", 1.53 + i * 0.35, 3.46 + h * 0.68, 0.195, 0.05, 0.075, 0.02, "C4A77E")
	end
	for _, x in { 1.13, 3.35 } do
		for i = 0, 2 do
			box(world, "Curtain pleat", x + i * 0.12, 4.53, 0.23 + (i % 2) * 0.07, 0.15, 2.65, 0.16,
				if i == 1 then "54577D" else "414466")
		end
	end
	box(world, "Headboard", -3.60, 2.02, 1.41, 0.25, 2.18, 2.95, "735765")
	for _, z in { 0.02, 2.81 } do
		box(world, "Bedpost", -3.60, 2.11, z, 0.24, 2.49, 0.24, "977380")
	end
	box(world, "Bed frame", -0.82, 1.45, 1.42, 5.55, 0.29, 2.98, "735765")
	box(world, "Mattress", -0.81, 1.78, 1.42, 5.48, 0.43, 2.93, "BEB3C8")
	box(world, "Folded quilt", 0.82, 2.02, 1.42, 2.23, 0.17, 2.99, "728BB0")
	box(world, "Quilt over the side", 0.82, 1.78, 2.88, 2.23, 0.49, 0.10, "647C9F")
	for i = 0, 2 do
		box(world, "Woven stripe", 0.16 + 0.18 * i, 2.114, 1.42, 0.07, 0.019, 2.98, "C7BFD3")
		box(world, "Woven stripe", 0.16 + 0.18 * i, 1.78, 2.95, 0.07, 0.50, 0.02, "AAA9C1")
	end
	for row = 0, 4 do
		for col = 0, 1 do
			local patch = box(world, "Patchwork diamond", 0.89 + col * 0.44, 2.116, 0.25 + row * 0.54,
				0.28, 0.014, 0.28, if (row + col) % 2 == 0 then "A8B5C9" else "899CB9")
			patch.CFrame *= A(0, math.pi / 4, 0)
		end
	end
	local pillow = box(world, "Pillow", -2.98, 2.42, 1.43, 1.04, 0.49, 2.27, "C9BDD0")
	pillow.CFrame *= A(0, 0, -0.45)
	pillow.Shape = Enum.PartType.Ball
	local cushion = box(world, "Second pillow", -3.05, 2.62, 0.63, 0.95, 0.66, 1.13, "9392B5")
	cushion.CFrame *= A(0, -0.21, -0.55)
	cushion.Shape = Enum.PartType.Ball
	box(world, "Bedside table", 2.42, 1.23, 0.53, 1.54, 2.31, 0.94, "594654")
	box(world, "Drawer", 2.42, 1.96, 1.02, 1.29, 0.48, 0.05, "715666")
	box(world, "Drawer pull", 2.42, 1.95, 1.07, 0.30, 0.07, 0.09, "A29692")
	lamp(world, 2.64, 2.42, 0.46, 0.65, "8F879E")
	book(world, 2.12, 2.44, 0.76, 0.67, 0.10, 0.42, "596C8B", -0.14)
	specimen(world, 2.11, 2.53, 0.71, 0.42)
	-- Pinned field sketches and a reading shelf make this a collector's bedroom.
	box(world, "Reading shelf", -2.39, 4.94, 0.21, 2.82, 0.11, 0.57, "776779", Enum.Material.Wood)
	specimen(world, -2.65, 5.01, 0.20, 0.78)
	book(world, -1.63, 5.05, 0.18, 0.85, 0.12, 0.38, "A2929A", 0.06)
	book(world, -1.66, 5.18, 0.19, 0.71, 0.09, 0.33, "627993", -0.06)
	S.strut(world, "Photo line", V(-4.52,4.39,0.11), V(-2.48,4.20,0.11), 0.031, 0.028, "A49CAA")
	S.strut(world, "Photo line", V(-2.48,4.20,0.11), V(-0.96,4.39,0.11), 0.031, 0.028, "A49CAA")
	for i, tint in { "759C9D", "AD8D8B", "8C93A8" } do
		local x, y = -4.1 + (i - 1) * 1.15, if i == 2 then 3.94 else 4.01
		local at = CF(x, y, 0.16) * A(0, 0, (i - 2) * 0.11)
		S.part(world, "Instant photo", at, V(0.51, 0.63, 0.025), "CCC1BF")
		S.part(world, "Coast study", at * CF(0,0.046,0.022), V(0.41,0.43,0.017), tint)
		S.part(world, "Cliff in photo", at * CF(0,-0.066,0.034), V(0.41,0.15,0.014), "526272")
		S.part(world, "Peg", at * CF(0,0.30,0.04), V(0.067,0.12,0.06), "B8A583")
	end
end

local function livingRoom(world)
	for i = -6, 6 do
		box(world, "Painted panel", i * 1.53, 1.15, 0.03, 1.47, 1.95, 0.065, if i % 2 == 0 then "64887E" else "678A80")
	end
	box(world, "Chair rail", 0, 2.16, 0.11, 21, 0.095, 0.20, "A7B5A2")
	box(world, "Television stand", 0, 2.22, 0.11, 1.25, 0.60, 0.36, "313B45")
	box(world, "Television foot", 0, 1.96, 0.35, 2.64, 0.13, 0.91, "414D55")
	box(world, "Oak media console", 0, 1.07, 0.44, 7.67, 1.65, 0.87, "9F714F", Enum.Material.Wood)
	box(world, "Console shelf", 0, 1.04, 0.90, 3.05, 1.13, 0.05, "4F4241")
	box(world, "Shelf divider", 0, 1.12, 0.96, 3.08, 0.12, 0.10, "BD9367")
	for _, x in { -2.63, 2.63 } do
		box(world, "Door", x, 1.06, 0.91, 2.00, 1.37, 0.11, "BC8C60")
		box(world, "Brass knob", x * 0.71, 1.15, 1.00, 0.13, 0.13, 0.10, "DEC28B")
	end
	for i, cover in { "607695", "B67760", "738E7A", "D0B281" } do
		box(world, "Books by the television", -1.27 + i * 0.22, 1.38, 0.99, 0.19, 0.42 - (i % 2) * 0.05, 0.20, cover)
	end
	specimen(world, 2.98, 1.91, 0.43, 0.65)
	local cart = box(world, "Toy mine cart", 1.02, 0.51, 4.31, 0.90, 0.39, 0.60, "628C91")
	for _, dx in { -0.25, 0.25 } do
		for _, dz in { -0.31, 0.31 } do
			local wheel = box(world, "Cart wheel", cart.Position.X + dx, 0.269, cart.Position.Z + dz, 0.22, 0.22, 0.09, "5E5351")
			wheel.Shape = Enum.PartType.Ball
		end
	end
	specimen(world, 1.02, 0.70, 4.31, 0.59)
	box(world, "Rug", 0, 0.04, 3.99, 8.60, 0.07, 5.12, "CCAB7E")
	for _, s in { -1, 1 } do
		box(world, "Woven rug border", s * 3.98, 0.085, 3.99, 0.12, 0.02, 4.88, "936854")
	end
	box(world, "Couch cushion", -2.66, 1.36, 3.11, 3.40, 0.49, 1.82, "698C86")
	box(world, "Upholstered sofa back", -2.71, 1.87, 3.99, 3.55, 1.11, 0.37, "5B7F7A")
	for _, x in { -3.47, -2.42, -1.42 } do
		box(world, "Back pillow seam", x, 1.87, 4.184, 0.035, 1.03, 0.019, "547572")
	end
	local throw = box(world, "Throw pillow", -3.56, 2.01, 3.39, 0.97, 0.94, 0.37, "DBA46E")
	throw.CFrame *= A(-0.19, -0.17, -0.14)
	S.part(world, "Pillow braid", throw.CFrame * CF(0,0,0.195), V(0.95,0.17,0.025), "EDD1A6")
	box(world, "Couch arm", -4.36, 1.80, 3.24, 0.46, 1.43, 2.16, "547B78")
	box(world, "Fabric sofa base", -2.66, 0.84, 3.17, 3.61, 0.65, 1.95, "4A6C6A")
	box(world, "Side table", 4.77, 1.22, 0.64, 1.66, 2.38, 1.12, "AB805A")
	lamp(world, 4.77, 2.45, 0.61, 1.40, "F9D49D")
	for i, color in { "BD6658", "CDA358", "688D91" } do
		local block = box(world, "Toy block", 1.62 + i * 0.40, 0.25, 3.52 - (i % 2) * 0.33, 0.45, 0.44, 0.43, color)
		block.CFrame *= A(0, i * 0.28, 0)
	end
	framedCove(world, -5.11, 4.64, 0.08, 1.28)
	plant(world, -5.28, 1.58, 0.68, 1.28)
	box(world, "Plant stool", -5.28, 1.45, 0.70, 1.15, 0.20, 0.93, "967151")
	for _, x in { -5.67,-4.89 } do
		box(world, "Stool leg", x, 0.71, 0.78, 0.14, 1.42, 0.16, "806447")
	end
	-- The reverse sees the other side of the same sofa. Set in this direction
	-- only, so a wide lens looking across the kid's shoulder can pass through.
	local back = S.group("Living room reverse wall")
	box(back, "Sunlit wall", 0, 5, 7.11, 38, 17, 0.31, "D6C2A7")
	for _, side in { -1, 1 } do
		box(back, "Return wall", side * 7.0, 4, 3.50, 0.22, 13, 7.25, "C1AA8B")
		box(back, "Return chair rail", side * 6.86, 2.13, 3.50, 0.13, 0.12, 7.25, "AB8D71")
	end
	box(back, "Reverse chair rail", 0, 2.13, 6.88, 38, 0.13, 0.17, "B4977D")
	box(back, "Window casing", -2.75, 4.12, 6.86, 2.93, 3.47, 0.20, "A47C5B")
	box(back, "Afternoon light", -2.75, 4.12, 6.72, 2.67, 3.19, 0.12, "EADBBC")
	box(back, "Window muntin", -2.75, 4.12, 6.61, 0.10, 3.15, 0.12, "C6A486")
	box(back, "Window muntin", -2.75, 4.09, 6.61, 2.65, 0.10, 0.12, "C6A486")
	for _, x in { -4.25,-1.24 } do
		for fold = 0, 2 do
			box(back, "Linen curtain", x + fold * 0.13, 4.03, 6.58 - 0.065 * (fold % 2), 0.17, 3.79, 0.21,
				if fold == 1 then "AA8173" else "B99381")
		end
	end
	box(back, "Sideboard", 0.95, 1.24, 6.13, 2.68, 2.34, 1.0, "A17C5D", Enum.Material.Wood)
	plant(back, 0.91, 2.43, 6.01, 1.28)
	book(back, 0.03, 2.48, 5.98, 0.60, 0.10, 0.42, "71919A", -0.10)
	return back
end

local function computerRoom(world)
	box(world, "Desk alcove", 0, 1.03, 0.025, 20, 1.93, 0.08, "667B89")
	box(world, "Oak dado", 0, 2.07, 0.10, 20, 0.095, 0.18, "AC8D73", Enum.Material.Wood)
	-- An exposed-brick strip and a hanging pinboard frame the shared workstation.
	box(world, "Chimney breast", 7.41, 3.97, 0.025, 3.2, 7.94, 0.15, "CAB7A4")
	for row = 0, 15 do
		for col = -1, 3 do
			local left = col * 0.8 + (row % 2) * 0.4
			local start, stop = math.max(0, left), math.min(3.2, left + 0.8)
			if stop - start > 0.04 then
				box(world, "Fired brick", 5.81 + (start + stop) / 2, 0.25 + row * 0.50, 0.13,
					stop - start - 0.027, 0.472, 0.15, if (row + col) % 3 == 0 then "A67D6E" else "B68A78")
			end
		end
	end
	for i = -9, 9 do
		local x = i * 0.34
		if math.abs(x) > 2.5 then
			box(world, "Acoustic slat", x, 4.25, -0.005, 0.31, 3.66, 0.07, "657B88")
		else
			box(world, "Acoustic slat", x, 5.91, -0.005, 0.31, 0.34, 0.07, "657B88")
			box(world, "Acoustic slat", x, 2.64, -0.005, 0.31, 0.44, 0.07, "657B88")
		end
	end
	box(world, "Desk pad", -0.12, 2.359, 1.08, 4.73, 0.025, 1.11, "52646C")
	box(world, "Monitor neck", 0, 2.72, 0.08, 0.29, 0.77, 0.30, "4A505D")
	box(world, "Monitor foot", 0, 2.39, 0.34, 1.45, 0.12, 0.91, "41454F")
	box(world, "Desk", 0, 2.22, 0.91, 8.30, 0.24, 1.81, "BC8D64")
	for _, x in { -3.57, 3.57 } do
		box(world, "Desk leg", x, 1.10, 1.45, 0.24, 2.21, 0.23, "60535D")
	end
	box(world, "Keyboard", 0, 2.39, 1.31, 2.63, 0.12, 0.79, "323643")
	for row = 1, 3 do
		for key = 1, 10 do
			box(world, "Key", (key - 5.5) * 0.245, 2.465, 1.03 + 0.18 * row, 0.20, 0.045, 0.12,
				if key > 8 then "9299A4" else "686C79")
		end
	end
	local mouse = box(world, "Mouse", 1.73, 2.47, 1.25, 0.34, 0.22, 0.49, "D4CCBC")
	mouse.Shape = Enum.PartType.Ball
	box(world, "Computer tower", 3.20, 3.43, 0.51, 1.12, 2.15, 0.99, "3A404E")
	for _, y in { 2.96, 3.83 } do
		local fan = box(world, "Computer fan", 3.20, y, 1.04, 0.76, 0.76, 0.09, "73C0CE")
		fan.Shape = Enum.PartType.Ball
		local hub = box(world, "Fan hub", 3.20, y, 1.10, 0.42, 0.42, 0.07, "45495C")
		hub.Shape = Enum.PartType.Ball
		for i = 0, 4 do
			local theta = i * math.pi * 2 / 5
			local blade = box(world, "Fan blade", 3.20 + 0.226 * math.cos(theta), y + 0.226 * math.sin(theta), 1.105,
				0.16, 0.055, 0.035, "657482")
			blade.CFrame *= A(0, 0, theta + 0.61)
		end
	end
	box(world, "Desk chair seat", -1.8, 1.64, 2.93, 2.27, 0.36, 1.75, "606572")
	box(world, "Desk chair back", -1.8, 1.96, 3.76, 2.07, 0.61, 0.31, "555867")
	box(world, "Desk chair stem", -1.8, 0.77, 2.95, 0.22, 1.51, 0.25, "393E4A")
	for _, y in { 3.11, 4.87, 6.35 } do
		box(world, "Wall shelf", -4.65, y, 0.20, 2.30, 0.14, 0.58, "AD8062")
	end
	for i, color in { "496679", "CBA276", "A65F65", "DDD1AF", "637C76" } do
		box(world, "Books", -5.31 + i * 0.26, 5.37 - 0.09 * (i % 2), 0.21, 0.22, 0.86 - 0.18 * (i % 2), 0.39, color)
	end
	specimen(world, -4.55, 3.19, 0.24, 1.15)
	plant(world, -5.08, 6.44, 0.26, 1.19)
	book(world, -2.97, 2.43, 0.56, 0.90, 0.11, 0.59, "677E95", -0.11)
	book(world, -2.92, 2.56, 0.53, 0.77, 0.11, 0.53, "BE9969", 0.09)
	box(world, "Corkboard rim", 4.78, 5.58, 0.06, 2.67, 1.89, 0.17, "886C58")
	box(world, "Cork", 4.78, 5.58, 0.171, 2.48, 1.70, 0.055, "BC9A77")
	for i, color in { "7B9FA2", "B58C97", "97AD8E" } do
		local x = 3.96 + (i - 1) * 0.76
		local at = CF(x, 5.56 + (i % 2) * 0.18, 0.23) * A(0, 0, (i - 2) * 0.13)
		S.part(world, "Pinned print", at, V(0.67, 0.87, 0.035), "E2D6BA")
		S.part(world, "Geology print", at * CF(0, 0.06, 0.026), V(0.51, 0.51, 0.026), color)
		S.part(world, "Mineral silhouette", at * CF(0, 0.08, 0.048) * A(0, 0, 0.55), V(0.20, 0.33, 0.024), "E7DBBA")
		S.part(world, "Pin", at * CF(0, 0.40, 0.05), V(0.072, 0.06, 0.043), "AF6857")
	end
	-- A cable hangs under the desk, crossing behind the chair.
	local cable = {
		V(-0.23, 2.20, 0.64), V(-0.17, 1.16, 0.72), V(0.60, 0.86, 0.74), V(1.65, 1.02, 0.72), V(3.16, 2.17, 0.56),
	}
	for i = 2, #cable do
		S.strut(world, "Monitor cable", cable[i - 1], cable[i], 0.051, 0.051, "485361")
	end
end

Rooms.bedroom = {
	name = "Bedroom", build = bedroom, width = 1.57, y = 3.36, z = 7.60, rim = 0.055, roll = -0.17, case = "293046",
	wall = "414564", floor = "4B4456", trim = "655E71", ambient = "787D9E", light = "BDCFFF",
	cast = { { seat = 1, x = -1.75, y = 0.50, z = 0.85, yaw = -1.11, scale = 0.77, seated = true } },
}
Rooms.livingRoom = {
	name = "Living room", build = livingRoom, width = 6.20, y = 4.39, z = 11.80, rim = 0.115, case = "262D3A",
	wall = "789990", floor = "A37F62", trim = "D1B78E", ambient = "9E9090", light = "FFDFAB",
	cast = { { seat = 2, x = -2.10, y = 0.26, z = 3.04, yaw = -0.41, scale = 0.67, seated = true } },
}
Rooms.computer = {
	name = "Computer room", build = computerRoom, width = 4.67, y = 4.27, z = 12.50, rim = 0.105, case = "2B3542",
	wall = "8494A2", floor = "937866", trim = "B7A492", ambient = "9A8D96", light = "F9DDC3",
	cast = {
		{ seat = 3, x = -1.82, y = 0.24, z = 2.78, yaw = -0.48, scale = 0.83, seated = true },
		{ seat = 4, x = 3.60, y = 0.01, z = 2.48, yaw = 0.89, scale = 0.93 },
		{ seat = 5, x = -4.24, y = 0.01, z = 2.48, yaw = -0.96, scale = 0.93 },
	},
}

function Rooms.build(shot, cast, warm)
	local world = Instance.new("WorldModel")
	world.Name = shot.name
	local receiver = shell(world, shot)
	local reverse = shot.build(world)
	local fans = {}
	for _, place in shot.cast do
		table.insert(fans, {
			rig = cast:viewer(world, place.seat, place.scale, warm),
			foot = CF(place.x, place.y, place.z) * A(0, place.yaw, 0),
			place = place,
		})
	end
	return { world = world, fans = fans, shot = shot, receiver = receiver, reverse = reverse }
end

return Rooms
