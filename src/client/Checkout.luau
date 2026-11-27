-- Buying something with Robux, from the player's side: a waiting screen while Roblox's checkout is
-- open and while the server delivers, then a thank-you that says what arrived and takes the player
-- straight to it (the Inventory tab to wear a trail or aura, the skill tree after a reset).
--
-- The server still decides everything. This only asks (Action BuyPass/BuyProduct) and listens:
--   * Roblox's own "checkout closed" events: closed without buying hides the waiting screen;
--   * Feedback "purchase" (name, kind, key) once the server has granted it;
--   * Feedback "hint" right after asking: the server said no (owned, sold out, region, too soon).
-- It can never get stuck: a Close button appears after a few seconds, a free (playtest) purchase that
-- gets no answer gives up after 8 seconds, and any purchase after two minutes. Closing only hides the
-- screen; if the purchase still goes through, the thank-you shows when it arrives.
-- Crates go to the inventory unopened: the thank-you offers to open one now.
local Players = game:GetService("Players")
local Market = game:GetService("MarketplaceService")
local Run = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local S, C = require(Shared.StoreConfig), require(Shared.Collectibles)
local W, Icons = require(script.Parent.Widgets), require(script.Parent.Icons)
local Burst = require(script.Parent.Burst)
local Checkout = {}
Checkout.__index = Checkout
local rgb = Color3.fromRGB
local green = ColorSequence.new(rgb(170, 255, 130), rgb(88, 216, 92))
local violet = ColorSequence.new(rgb(207, 174, 255), rgb(129, 80, 230))
-- Dismiss buttons (Done, Close, Skip) in a friendly blue rather than grey.
local slate = ColorSequence.new(rgb(130, 205, 255), rgb(48, 118, 222))
local practice = Run:IsStudio() and game.GameId == 0
local Config = require(Shared.GameConfig)

local function button(parent, name, x, y, w, h, paint, text)
	local b = W.clearButton(parent, name, x, y, w, h, "Select")
	W.round(b, 14)
	local fill = W.enamelPanel(b, rgb(1, 1, 1), rgb(1, 1, 1), 14)
	fill.Color = paint
	local label = W.title(b, text, 0, 0, w, h - 2, 22, W.white)
	label.ZIndex = 3
	W.navyText(label, 2.4)
	W.largest(label, 22, 12)
	return b, label
end

function Checkout.new(hud, net, reveal)
	local self = setmetatable({ hud = hud, net = net, reveal = reveal, player = Players.LocalPlayer }, Checkout)
	Checkout.current = self
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset = "Checkout", false, 40, true
	gui.ZIndexBehavior, gui.Enabled = Enum.ZIndexBehavior.Sibling, false
	gui.Parent = self.player:WaitForChild("PlayerGui")
	self.gui = gui
	local shade = Instance.new("TextButton")
	shade.Name, shade.Text, shade.AutoButtonColor = "Shade", "", false
	shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency = UDim2.fromScale(1, 1), W.ink, 0.35
	shade.Parent = gui
	-- The waiting screen: a turning ring and what's happening.
	local wait = W.frame(gui, "Waiting", 0, 0, 380, 190, W.white, 22)
	W.anchor(wait, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	W.enamelPanel(wait, rgb(72, 68, 124), rgb(38, 36, 74), 22)
	self.waitScale = W.scale(wait)
	local ring = W.frame(wait, "Spinner", 160, 18, 60, 60, W.ink, 30)
	ring.BackgroundTransparency = 1
	local stroke = W.stroke(ring, W.white, 7)
	local sweep = Instance.new("UIGradient")
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.15), NumberSequenceKeypoint.new(1, 1),
	})
	sweep.Color = ColorSequence.new(rgb(170, 255, 130), rgb(90, 200, 255))
	sweep.Parent = stroke
	self.spinner = sweep
	local robux = Instance.new("ImageLabel")
	robux.Name, robux.BackgroundTransparency, robux.Image = "Robux", 1, W.robuxImage
	robux.Size, robux.Position, robux.ImageColor3 = UDim2.fromOffset(28, 28), UDim2.fromOffset(16, 16), rgb(170, 255, 130)
	robux.Parent = ring
	self.waitTitle = W.title(wait, "", 10, 86, 360, 36, 26, W.white)
	W.navyText(self.waitTitle, 2.8)
	self.waitText = W.title(wait, "", 18, 120, 344, 40, 16, rgb(220, 220, 240))
	self.waitText.TextWrapped = true
	W.navyText(self.waitText, 1.8)
	self.wait = wait
	self.giveUp = button(wait, "Close", 130, 160, 120, 40, slate, "Close")
	self.giveUp.Activated:Connect(function()
		self.pending = nil
		self:close()
	end)
	-- The thank-you: rays, the item, what arrived and where to find it.
	local thanks = W.frame(gui, "Thanks", 0, 0, 460, 360, W.white, 24)
	W.anchor(thanks, 0.5, 0.5, UDim2.fromScale(0.5, 0.5))
	self.thanksPaint = W.enamelPanel(thanks, rgb(120, 220, 140), rgb(30, 110, 70), 24)
	self.thanksScale = W.scale(thanks)
	local rays = W.frame(thanks, "Rays holder", 0, 0, 460, 360, W.ink)
	rays.BackgroundTransparency, rays.ClipsDescendants = 1, true
	Burst.rays(rays, 230, 120, 340, 12, W.white, 0.82)
	self.rays = rays
	local heading = W.title(thanks, "THANK YOU!", 0, 12, 460, 40, 34, rgb(255, 244, 170))
	self.thanksHeading = heading
	W.navyText(heading, 3.4)
	self.art = W.frame(thanks, "Art", 170, 56, 120, 120, W.ink)
	self.art.BackgroundTransparency = 1
	self.thanksName = W.title(thanks, "", 12, 182, 436, 40, 32, W.white)
	W.navyText(self.thanksName, 3.2)
	self.thanksName.RichText = true
	W.largest(self.thanksName, 32, 16)
	self.thanksText = W.title(thanks, "", 20, 222, 420, 52, 18, rgb(255, 250, 215))
	self.thanksText.TextWrapped, self.thanksText.RichText = true, true
	W.navyText(self.thanksText, 2)
	W.largest(self.thanksText, 18, 11)
	self.go, self.goLabel = button(thanks, "Go", 20, 286, 250, 56, green, "")
	self.done = button(thanks, "Done", 286, 286, 154, 56, slate, "Awesome!")
	self.go.Activated:Connect(function()
		local page = self.goPage
		self:close()
		if page == "crate" then
			-- A Welcome Crate waiting opens first; otherwise a Starfall Crate.
			local col = require(Shared.Bonuses).decode(self.player:GetAttribute("Collection")) or {}
			local items = col.items or {}
			self.net.Action:FireServer("OpenGeode", if (items.WelcomeGeode or 0) > 0 then "Welcome" else "Starfall")
		elseif page then
			self.hud:openPage(page)
		end
	end)
	self.done.Activated:Connect(function() self:close() end)
	self.thanks = thanks
	-- Roblox's checkout closing.
	Market.PromptGamePassPurchaseFinished:Connect(function(who, _, bought)
		if who == self.player then self:closed(bought) end
	end)
	Market.PromptProductPurchaseFinished:Connect(function(userId, _, bought)
		if userId == self.player.UserId then self:closed(bought) end
	end)
	Run.RenderStepped:Connect(function(dt)
		if gui.Enabled and wait.Visible then sweep.Rotation = (sweep.Rotation + dt * 300) % 360 end
	end)
	return self
end

function Checkout:layout()
	local area = workspace.CurrentCamera.ViewportSize
	local s = math.clamp(math.min(area.X / 560, area.Y / 460), 0.55, 1.3)
	self.waitScale.Scale, self.thanksScale.Scale = s, s
end

function Checkout:show(which)
	self:layout()
	self.gui.Enabled = true
	self.wait.Visible = which == "wait"
	self.thanks.Visible = which == "thanks"
end

-- A crate won from a daily or playtime reward (or VIP): the same card as after buying one, with the
-- choice to open it now or later from the Inventory.
function Checkout:crateWon(title, text)
	if self.pending or self.gui.Enabled then return end
	self.thanksHeading.Text = "A CRATE FOR YOU!"
	self.thanksName.Text = W.rich(title)
	self.thanksText.Text = W.rich(text .. ". It's in your Inventory, or open it now.")
	self.art:ClearAllChildren()
	Icons.draw(self.art, "Geode", 0, 0, 120)
	self.goPage = "crate"
	self.go.Visible, self.goLabel.Text = true, "Open it now"
	self.done.Position = UDim2.fromOffset(286, 286)
	self.thanksPaint.Color = ColorSequence.new(rgb(196, 160, 255), rgb(110, 70, 200))
	self:show("thanks")
end

-- Is a purchase on its way?
function Checkout:expecting()
	return self.pending ~= nil
end

-- Asks to buy `item` (a pass or product from StoreConfig) and waits for it.
function Checkout:buy(kind, item)
	if self.pending and self.wait.Visible and self.gui.Enabled then return end
	local pending = { kind = kind, item = item, at = os.clock() }
	self.pending = pending
	-- An unpublished Studio test gives everything free (Store.prompt), as does an item with no ID yet
	-- while FreeUnconfiguredItems is on.
	local free = practice or (item.id <= 0 and Config.FreeUnconfiguredItems)
	self.waitTitle.Text = if free then "Getting it ready…" else "Waiting for checkout…"
	self.waitText.Text = if free then item.name .. " (free while playtesting)"
		else "Finish buying " .. item.name .. " in the Roblox window."
	self.giveUp.Visible = false
	self:show("wait")
	self.net.Action:FireServer(if kind == "pass" then "BuyPass" else "BuyProduct", item.key)
	-- Never stuck: a Close button after a few seconds, and give up waiting when nothing comes back
	-- (the item still arrives, with its thank-you, if it was bought).
	task.delay(4, function()
		if self.pending == pending then self.giveUp.Visible = true end
	end)
	task.delay(if free then 8 else 120, function()
		if self.pending == pending then self:clear() end
	end)
end

-- Roblox's checkout window closed.
function Checkout:closed(bought)
	if not self.pending then return end
	if not bought then
		self:clear()
		return
	end
	self.waitTitle.Text = "Delivering…"
	self.waitText.Text = "Thanks! Adding " .. self.pending.item.name .. " to your account."
end

-- The server refused (already owned, sold out, not in this region): the hint explains why.
function Checkout:refused()
	if self.pending and os.clock() - self.pending.at < 3 then self:clear() end
end

-- Gold from a gold pack, which arrives just before the "purchase" feedback.
function Checkout:gold(amount)
	self.goldGiven = amount
end

function Checkout:clear()
	self.pending = nil
	if not self.thanks.Visible then self.gui.Enabled = false end
end

function Checkout:close()
	self.gui.Enabled, self.thanks.Visible = false, false
end

-- What a purchase gave, where it is, and the button that goes there.
local function describe(kind, item, goldGiven)
	if kind == "pass" then
		if item.key == "Everything" then
			return "Every pass is yours for good, plus the Celestial title, the Celestial Mining FX ("
				.. W.colored("+10% mining speed", rgb(255, 180, 90)) .. ") and the Prism Trail ("
				.. W.colored("+16% movement speed", rgb(150, 255, 120)) .. "). They're on now.", "See your effects", "MiningTrails"
		end
		return (item.detail or "") .. ". Yours for good.", nil, nil
	end
	if item.cosmetic then
		local fast = C.speedText(item.cosmetic.kind, item.cosmetic.id)
		return "You're wearing it now" .. (if fast then " (" .. fast .. ")" else "") .. ". Only a few will ever have one.",
			"Open in Inventory", if item.cosmetic.kind == "trail" then "MiningTrails" else "PlayerFX"
	end
	if item.key == "StarterPack" then
		return W.rich("2 Starfall Crates, 30 min of 2× Gold (on now) and a Haste Tonic. Your crates are in your Inventory."), "Open a crate", "crate"
	end
	if item.minutes and item.group == "Gold" then
		return "+" .. W.goldAmount(goldGiven or 0) .. " gold, " .. S.duration(item.minutes) .. " of your earnings.", nil, nil
	end
	if item.key == "ResetSkills" then
		return "Every skill point is back to spend again.", "Open Skills", "Skills"
	end
	if item.crates then
		return W.rich(item.crates .. " Starfall Crate" .. (if item.crates == 1 then " is" else "s are") .. " waiting in your Inventory."), "Open a crate", "crate"
	end
	return (item.detail or "") .. ". It's on now.", nil, nil
end

-- The server granted `key`. Show the thank-you (after any crate reel the purchase opened).
function Checkout:purchased(name, kind, key)
	local item = if kind == "pass" then S.passByKey[key] else S.productByKey[key]
	local expected = self.pending and self.pending.item.key == key
	self.pending = nil
	if not item or not expected then
		self:clear()
		self.hud:notice("Thank you!", name .. " is yours", W.green)
		return
	end
	local goldGiven = self.goldGiven
	self.goldGiven = nil
	self.gui.Enabled = false
	task.spawn(function()
		while self.reveal and self.reveal:busy() do task.wait(0.25) end
		local text, go, page = describe(kind, item, goldGiven)
		self.thanksHeading.Text = "THANK YOU!"
		self.thanksName.Text = W.rich(item.name)
		self.thanksText.Text = W.rich(text)
		self.art:ClearAllChildren()
		local icon = if item.cosmetic then "Gems" elseif item.crates or item.key == "StarterPack" then "Geode"
			elseif item.group == "Gold" then ({ pouch = "GoldPouch", bag = "GoldBag", chest = "GoldChest", vault = "GoldVault" })[item.art] or "Coins"
			else item.icon or "Shop"
		Icons.draw(self.art, icon, 0, 0, 120)
		self.goPage = page
		self.go.Visible = go ~= nil
		self.goLabel.Text = go or ""
		self.done.Position = if go then UDim2.fromOffset(286, 286) else UDim2.fromOffset(153, 286)
		local tint = if item.cosmetic then { rgb(255, 200, 120), rgb(200, 90, 40) }
			elseif kind == "pass" then { rgb(255, 230, 128), rgb(214, 140, 30) }
			else { rgb(120, 220, 140), rgb(30, 110, 70) }
		self.thanksPaint.Color = ColorSequence.new(tint[1], tint[2])
		self:show("thanks")
		if Burst.allowed(self.player) then
			self.thanksScale.Scale *= 0.6
			W.tween(self.thanksScale, 0.25, { Scale = self.thanksScale.Scale / 0.6 })
			task.delay(0.15, function()
				local at = self.thanks.AbsolutePosition + self.thanks.AbsoluteSize / 2
				Burst.confetti(self.gui, at.X, at.Y - 60, 36, { W.gold, W.white, rgb(150, 255, 120) }, 1)
			end)
		end
	end)
end

return Checkout
