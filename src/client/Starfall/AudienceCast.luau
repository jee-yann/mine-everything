local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local Rig = require(script.Parent.Parent.CinematicActors.RobloxRig)
local S = require(script.Parent.Scenery)
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles

local Cast = {}
Cast.__index = Cast

-- Clothes and hair for the classic Roblox actors, in shot order.
local wardrobe = {
	{ "677CD5", "DBA67E", "3B3043", "423E66", "bun" },
	{ "E09345", "9D6350", "382D30", "355F78", "curls" },
	{ "548E83", "E3B089", "68432C", "384551", "side part" },
	{ "A45A72", "8F5D48", "322A36", "454259", "bun" },
	{ "6274AC", "C68F68", "50383F", "383F53", "curls" },
}

function Cast.new()
	local self = setmetatable({ templates = {}, loading = {}, seated = {}, closed = false }, Cast)
	local player = Players.LocalPlayer
	if player and player.UserId > 0 then
		task.spawn(function()
			local ok, pages = pcall(Players.GetFriendsAsync, Players, player.UserId)
			if not ok or self.closed then
				return
			end
			-- Only five seats. Keep yields and asset loading off the picture clock.
			for seat, friend in pages:GetCurrentPage() do
				if seat > #wardrobe then
					break
				end
				task.spawn(function()
					local loaded, model = pcall(Players.CreateHumanoidModelFromUserIdAsync, Players, friend.Id)
					if not loaded or not model then
						return
					end
					if self.closed or self.seated[seat] then
						model:Destroy()
						return
					end
					-- Creating a Model does not load its meshes or its clothing
					-- textures. A partly downloaded avatar can look like floating hair.
					self.loading[model] = true
					local complete = true
					local ready = pcall(function()
						ContentProvider:PreloadAsync({ model }, function(_, status)
							if status ~= Enum.AssetFetchStatus.Success then complete = false end
						end)
					end)
					self.loading[model] = nil
					if self.closed or self.seated[seat] or not ready or not complete then
						model:Destroy()
					else
						self.templates[seat] = model
					end
				end)
			end
		end)
	end
	return self
end

local function casualClothes(rig, seat)
	local shirt, skin, hair, pants, style = table.unpack(wardrobe[seat])
	local model = rig.model
	model.Head.Color, model.Torso.Color = Color3.fromHex(skin), Color3.fromHex(shirt)
	for _, side in { "Left", "Right" } do
		model[side .. " Arm"].Color = Color3.fromHex(shirt)
		model[side .. " Leg"].Color = Color3.fromHex(pants)
	end
	for i = #rig.dress, 1, -1 do
		local piece = rig.dress[i]
		local part = piece.part
		if part.Name == "Short sleeve" then
			part.Name, part.Color = "Hand", Color3.fromHex(skin)
			part.Size = V(1.07, 0.55, 1.07)
			piece.offset = CF(0, -0.76, 0)
			part.CFrame = piece.bone.CFrame * piece.offset
		elseif part.Name == "Work boot" then
			part.Name, part.Color = "Sneaker", Color3.fromHex("DEDBCB")
		else
			part:Destroy()
			table.remove(rig.dress, i)
		end
	end
	local function lock(name, offset, size, color, rounded)
		local p = S.part(model, name, rig.head.CFrame * offset, size, color)
		if rounded then p.Shape = Enum.PartType.Ball end
		table.insert(rig.dress, { part = p, bone = rig.head, offset = offset })
	end
	lock("Hair", CF(0, 0.41, 0.05), V(1.52, 0.57, 1.2), hair, true)
	if style == "bun" then
		lock("Tied hair", CF(0, 0.49, 0.64), V(0.75, 0.69, 0.68), hair, true)
		lock("Hair tie", CF(0, 0.50, 0.45), V(0.66, 0.57, 0.17), shirt, true)
	elseif style == "curls" then
		for i = 0, 5 do
			local angle = i * math.pi / 3
			lock("Curl", CF(math.sin(angle) * 0.52, 0.4, math.cos(angle) * 0.41), V(0.57, 0.59, 0.53), hair, true)
		end
	else
		lock("Swept fringe", CF(-0.20, 0.39, -0.42) * A(0, 0, -0.16), V(0.99, 0.41, 0.40), hair, true)
	end
end

function Cast:viewer(world, seat, scale, warm)
	self.seated[seat] = true
	local source = self.templates[seat]
	local rig = Rig.new(world, "Viewer " .. seat, if warm then source else nil)
	if source then
		source:Destroy()
		self.templates[seat] = nil
	end
	if not warm or not source then
		casualClothes(rig, seat)
	end
	-- Scale the same anatomical pivots used by Rig:pose along with the model.
	rig.model:ScaleTo(rig.model:GetScale() * scale)
	for _, joint in rig.links do
		joint.c0 = joint.c0.Rotation + joint.c0.Position * scale
		joint.c1 = joint.c1.Rotation + joint.c1.Position * scale
	end
	for _, item in rig.dress do
		item.offset = item.offset.Rotation + item.offset.Position * scale
	end
	rig.height *= scale
	return rig
end

function Cast:Destroy()
	self.closed = true
	for model in self.loading do
		model:Destroy()
	end
	for _, model in self.templates do
		model:Destroy()
	end
	table.clear(self.loading)
	table.clear(self.templates)
end

return Cast
