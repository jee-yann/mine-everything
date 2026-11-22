-- Camera-facing photographic elements at real depths. An exposure supplies
-- every position and pigment, so the image holds between film frames.
local Sprite = {}
Sprite.smoke = "rbxasset://textures/particles/smoke_main.dds"
Sprite.flame = "rbxasset://textures/particles/fire_main.dds"
-- FireSpecs1, from Fire-01 in Euphoric Games Community's VFX PACK.
Sprite.sparks = "rbxassetid://11187840108"

function Sprite.new(part, name, texture, light)
	local socket = Instance.new("Attachment")
	socket.Name, socket.Parent = name, part
	local card = Instance.new("BillboardGui")
	card.Name, card.LightInfluence, card.AlwaysOnTop, card.Enabled = name, light, false, false
	card.Adornee, card.Parent = socket, socket
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size, image.Image, image.Parent = UDim2.fromScale(1, 1), texture, card
	return { socket = socket, card = card, image = image }
end

function Sprite.draw(p, position, width, height, rotation, color, transparency)
	local visible = transparency < 0.995 and width > 0.008 and height > 0.008
	p.card.Enabled = visible
	if not visible then
		return
	end
	p.socket.Position = position
	p.card.Size = UDim2.fromScale(width, height)
	p.image.Rotation, p.image.ImageColor3, p.image.ImageTransparency = rotation, color, math.clamp(transparency, 0, 1)
end
return Sprite
