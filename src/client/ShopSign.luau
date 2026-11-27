-- A painted signboard standing on the Outfitters roof that advertises the featured offers (the same
-- ones as the HUD tiles, FeaturedOffers): a card for each, with a live preview or its art, its name and
-- a pill (how many are left, or the discount). Tapping a card opens that offer; with every offer bought
-- it points to the Shop instead. It's a real board in a wooden frame (it takes the hat emblem's place)
-- and it's put away while a film plays.
local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Burst = require(script.Parent.Burst)
local FxPreview = require(script.Parent.FxPreview)
local rgb = Color3.fromRGB

local function card(parent, name, x, tint)
	local b = W.clearButton(parent, name, x, 46, 196, 150, "Open")
	W.round(b, 18)
	local paint = W.enamelPanel(b, tint[1], tint[2], 18)
	local _ = paint
	local rays = W.frame(b, "Glow", 6, 6, 184, 138, W.white, 14)
	rays.BackgroundTransparency, rays.ClipsDescendants = 1, true
	Burst.rays(rays, 92, 50, 160, 8, W.white, 0.82)
	return b
end

return function(hud)
	local player = Players.LocalPlayer
	-- Builds the sign over the real island's stall (not the opening film's copy of the plaza), or
	-- returns nil while the stall isn't there yet.
	local function build()
		local island = workspace:FindFirstChild("CitrineCove")
		local plaza = island and island:FindFirstChild("Harbor Plaza")
		local store = plaza and plaza:FindFirstChild("Store")
		local ridge = store and store:FindFirstChild("Roof ridge", true)
		local name = store and store:FindFirstChild("Shop sign", true)
		if not ridge or not name or not hud.offers then return end
		-- The board faces the way the stall's name board does, out over the counter.
		local out = (name.Position - ridge.Position) * Vector3.new(1, 0, 1)
		out = if out.Magnitude > 0.01 then out.Unit else Vector3.zAxis
		local up = ridge.Position + Vector3.yAxis * (ridge.Size.Y / 2)
		local board = Instance.new("Model")
		board.Name = "Outfitters featured board"
		local function plank(label, size, at, color)
			local p = Instance.new("Part")
			p.Name, p.Size, p.Color, p.Material = label, size, color, Enum.Material.SmoothPlastic
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.CFrame = CFrame.lookAt(at, at + out)
			p.Parent = board
			return p
		end
		local center = up + Vector3.yAxis * 3.3 + out * 1.2
		plank("Board frame", Vector3.new(12.8, 6.8, 0.5), center - out * 0.12, rgb(120, 78, 46))
		local face = plank("Board face", Vector3.new(12, 6, 0.3), center + out * 0.06, rgb(46, 40, 82))
		for _, side in { -1, 1 } do
			local right = CFrame.lookAt(center, center + out).RightVector
			plank("Board post", Vector3.new(0.6, 3.6, 0.6), up + Vector3.yAxis * 1.2 + right * side * 5 + out * 0.9, rgb(120, 78, 46))
		end
		-- The hat emblem sat where the board stands now.
		for _, part in store:GetDescendants() do
			if part:IsA("BasePart") and (part.Name == "Hat emblem" or part.Name == "Hat band") then part.LocalTransparencyModifier = 1 end
		end
		local sign = Instance.new("SurfaceGui")
		sign.Name, sign.Adornee, sign.ResetOnSpawn, sign.Face = "Outfitters featured", face, false, Enum.NormalId.Front
		sign.CanvasSize, sign.LightInfluence, sign.Brightness, sign.Active = Vector2.new(600, 300), 0, 1.4, true
		sign.MaxDistance, sign.ZIndexBehavior = 220, Enum.ZIndexBehavior.Sibling
		sign.Parent = player:WaitForChild("PlayerGui")
		board.Parent = workspace
		sign.Destroying:Once(function() board:Destroy() end)
		local root = W.frame(sign, "Sign", 6, 12, 420, 200, W.ink)
		root.BackgroundTransparency = 1
		W.scale(root).Scale = 1.4
		local header = W.frame(root, "Header", 120, 0, 180, 38, W.white, 19)
		W.enamelPanel(header, rgb(255, 159, 200), rgb(227, 69, 138), 19)
		local title = W.title(header, "FEATURED", 0, 0, 180, 36, 24, W.white)
		W.navyText(title, 2.6)
		local offers = hud.offers
		local halo = card(root, "Founder's Halo", 8, { rgb(255, 200, 120), rgb(214, 96, 40) })
		FxPreview.new(halo, "aura", "FounderHalo", 53, 6, 90)
		local haloName = W.title(halo, "Founder's Halo", 4, 94, 188, 26, 20, W.white)
		W.navyText(haloName, 2.4)
		local haloPill = W.frame(halo, "Pill", 48, 120, 100, 22, rgb(255, 70, 90), 11)
		W.stroke(haloPill, W.navy, 2)
		local haloLeft = W.title(haloPill, "", 0, 0, 100, 21, 14, W.white)
		W.navyText(haloLeft, 1.6)
		local pack = card(root, "Starter Pack", 216, { rgb(255, 159, 200), rgb(227, 69, 138) })
		Icons.draw(pack, "Geode", 58, 8, 80)
		local packName = W.title(pack, "Starter Pack", 4, 94, 188, 26, 20, W.white)
		W.navyText(packName, 2.4)
		local packPill = W.frame(pack, "Pill", 48, 120, 100, 22, rgb(60, 190, 90), 11)
		W.stroke(packPill, W.navy, 2)
		W.navyText(W.title(packPill, "-62%", 0, 0, 100, 21, 14, W.white), 1.6)
		local shop = card(root, "Shop", 112, { rgb(255, 159, 200), rgb(227, 69, 138) })
		Icons.draw(shop, "Shop", 58, 8, 80)
		W.navyText(W.title(shop, "Open the Shop", 4, 100, 188, 30, 22, W.white), 2.4)
		local function offer(key) return offers.tiles[key] and offers.tiles[key].offer end
		halo.Activated:Connect(function() offers:open(offer("FounderHalo")) end)
		pack.Activated:Connect(function() offers:open(offer("StarterPack")) end)
		shop.Activated:Connect(function() hud:openPage("Shop") end)
		local function refresh()
			local showHalo = offer("FounderHalo") and offers:available(offer("FounderHalo"))
			local showPack = offer("StarterPack") and offers:available(offer("StarterPack"))
			halo.Visible, pack.Visible = showHalo == true, showPack == true
			shop.Visible = not showHalo and not showPack
			-- One offer left: it moves to the middle.
			halo.Position = UDim2.fromOffset(if showPack then 8 else 112, 46)
			pack.Position = UDim2.fromOffset(if showHalo then 216 else 112, 46)
			local item = offer("FounderHalo") and offer("FounderHalo").item
			if item then haloLeft.Text = W.goldAmount(Rep:GetAttribute("Limited" .. item.key) or item.limited) .. " LEFT" end
		end
		refresh()
		local links = {
			player:GetAttributeChangedSignal("StarterBought"):Connect(refresh),
			player:GetAttributeChangedSignal("Collection"):Connect(refresh),
			Rep:GetAttributeChangedSignal("LimitedFounderHalo"):Connect(refresh),
		}
		sign.Destroying:Once(function()
			for _, link in links do link:Disconnect() end
		end)
		-- Off the island while a film (the opening or a rebirth) is playing.
		table.insert(links, Run.Heartbeat:Connect(function()
			local away = hud.inOpening == true
			if (board.Parent == nil) ~= away then
				board.Parent = if away then nil else workspace
				sign.Enabled = not away
			end
		end))
		return sign
	end
	-- Keep a sign over the stall: build it once the island is there, and again if the stall is ever
	-- replaced (the map streaming out and back in).
	task.spawn(function()
		local sign
		while true do
			if not (sign and sign.Parent and sign.Adornee and (sign.Adornee:IsDescendantOf(workspace) or hud.inOpening)) then
				if sign then sign:Destroy() end
				sign = build()
			end
			task.wait(2)
		end
	end)
end
