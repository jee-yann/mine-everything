-- A sign floating over the Outfitters stall that advertises the featured offers (the same ones as the
-- HUD tiles, FeaturedOffers): a card for each, with a live preview or its art, its name and a pill
-- (how many are left, or the discount). Tapping a card opens that offer; with every offer bought it
-- points to the Shop instead. It shrinks with distance so it reads from across the plaza without
-- filling the screen up close.
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
		local counter = store and (store:FindFirstChild("Counter", true) or store:FindFirstChildWhichIsA("BasePart", true))
		if not counter or not hud.offers then return end
		local sign = Instance.new("BillboardGui")
		sign.Name, sign.Adornee, sign.ResetOnSpawn = "Outfitters featured", counter, false
		sign.Size, sign.StudsOffsetWorldSpace = UDim2.fromOffset(420, 200), Vector3.new(0, 19, 0)
		sign.MaxDistance, sign.LightInfluence, sign.Active = 170, 0, true
		sign.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sign.Parent = player:WaitForChild("PlayerGui")
		local root = W.frame(sign, "Sign", 0, 0, 420, 200, W.ink)
		root.BackgroundTransparency = 1
		local fit = W.scale(root)
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
		-- Smaller far away, a gentle bob.
		table.insert(links, Run.RenderStepped:Connect(function()
			local camera = workspace.CurrentCamera
			local distance = (camera.CFrame.Position - counter.Position).Magnitude
			local screen = math.min(1, camera.ViewportSize.Y / 720) ^ 1.6
			local s = math.clamp(60 / math.max(distance, 1), 0.3, 1) * screen
			fit.Scale, sign.Size = s, UDim2.fromOffset(420 * s, 200 * s)
			sign.StudsOffsetWorldSpace = Vector3.new(0, 19 + 0.3 * math.sin(os.clock() * 1.6), 0)
		end))
		return sign
	end
	-- Keep a sign over the stall: build it once the island is there, and again if the stall is ever
	-- replaced (the map streaming out and back in).
	task.spawn(function()
		local sign
		while true do
			if not (sign and sign.Parent and sign.Adornee and sign.Adornee:IsDescendantOf(workspace)) then
				if sign then sign:Destroy() end
				sign = build()
			end
			task.wait(2)
		end
	end)
end
