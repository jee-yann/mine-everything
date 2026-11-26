-- A miner's profile and records (their own, or anyone in the server found with the search box), and a
-- tab of friends who are online: join one who is playing, or invite one who is not. Mining with a friend here gives more XP (Shared.FriendBonus).
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Social = game:GetService("SocialService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Ores, Expeditions, Skills = require(Shared.Ores), require(Shared.Expeditions), require(Shared.Skills)
local Guide, FriendBonus, Rebirth = require(Shared.FieldGuide), require(Shared.FriendBonus), require(Shared.Rebirth)
local W, Icons, Card = require(script.Parent.Widgets), require(script.Parent.Icons), require(script.Parent.WideCard)
local Burst = require(script.Parent.Burst)
local Panel = {}
Panel.__index = Panel
local rgb = Color3.fromRGB
local aqua = { rgb(134, 214, 255), rgb(47, 130, 230) }
local mint = { rgb(140, 240, 220), rgb(24, 160, 150) }
local tints = {
	aqua, { rgb(255, 226, 120), rgb(240, 150, 30) }, { rgb(207, 174, 255), rgb(129, 80, 230) }, { rgb(255, 159, 200), rgb(227, 69, 138) },
	mint, { rgb(255, 208, 138), rgb(240, 138, 58) }, { rgb(166, 245, 154), rgb(52, 178, 74) }, { rgb(255, 150, 150), rgb(214, 52, 78) },
}
local green = ColorSequence.new(rgb(166, 245, 110), rgb(62, 178, 52))
local blue = ColorSequence.new(aqua[1], aqua[2])
local grey = ColorSequence.new(rgb(150, 154, 176), rgb(98, 102, 128))
local practice = Run:IsStudio() and game.GameId == 0

local function box(parent, name, x, y, w, h, tint)
	local frame = W.frame(parent, name, x, y, w, h, W.white, 16)
	return frame, W.enamelPanel(frame, tint[1], tint[2], 16)
end
local function words(parent, value, x, y, w, h, size, color, left)
	local label = W.title(parent, value, x, y, w, h, size, color or W.white, left)
	label.ZIndex = 3
	W.navyText(label, math.max(2, size / 9))
	return label
end
local function press(parent, name, x, y, w, h, size)
	local button = W.clearButton(parent, name, x, y, w, h, "Select")
	W.round(button, 12)
	local paint = W.enamelPanel(button, rgb(150, 154, 176), rgb(98, 102, 128), 12)
	return button, paint, words(button, "", 0, 0, w, h - 2, size)
end
local function headshot(parent, userId, x, y, size)
	local face = Instance.new("ImageLabel")
	face.Name, face.BackgroundColor3, face.BorderSizePixel = "Headshot", rgb(52, 48, 96), 0
	face.Position, face.Size, face.ZIndex = UDim2.fromOffset(x, y), UDim2.fromOffset(size, size), 2
	W.round(face, size // 2)
	W.stroke(face, W.navy, 4)
	face.Parent = parent
	if userId > 0 then
		face.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
	else
		Icons.draw(face, "Crew", size * 0.2, size * 0.2, size * 0.6)
	end
	return face
end

function Panel.new(menu)
	local self = setmetatable({ menu = menu, friendRows = {}, friends = {}, asked = 0 }, Panel)
	local card = Card.new(menu, "Profile", "Profile", "Profile", aqua)
	self.card = card
	card:useTabs()
	card:tab("Profile", "Profile", "Profile", function() menu:open("Profile") end)
	card:tab("Friends", "Friends", "Friends", function() menu:open("Friends") end)
	self:buildProfile()
	self:buildFriends()
	self:buildSearch()
	menu.player:GetAttributeChangedSignal("FriendsHere"):Connect(function()
		if card.modal.Visible then
			self:refresh()
			if self.page == "Friends" then self:load() end
		end
	end)
	return self
end

function Panel:buildProfile()
	local page = W.frame(self.card.body, "Profile", 7, 7, 764, 358, W.panel)
	page.BackgroundTransparency = 1
	self.profilePage = page
	local player = self.menu.player
	local hero = box(page, "Miner", 0, 0, 236, 352, aqua)
	Card.rays(hero, 118, 92, 230, 8)
	self.face = headshot(hero, player.UserId, 53, 16, 130)
	local name = words(hero, player.DisplayName, 8, 152, 220, 36, 30)
	name.RichText = true
	W.largest(name, 30, 16)
	self.nameLabel = name
	-- Back to their own profile after looking at someone else's.
	local back, backPaint, backLabel = press(hero, "Back to you", 8, 8, 104, 32, 17)
	backPaint.Color, backLabel.Text, back.Visible = ColorSequence.new(rgb(255, 226, 120), rgb(240, 150, 30)), "◀ You", false
	back.ZIndex = 6
	back.Activated:Connect(function() self:view(nil) end)
	self.back = back
	self.title = words(hero, "", 8, 188, 220, 26, 19, rgb(255, 244, 170))
	self.level = words(hero, "", 8, 222, 220, 40, 34)
	local track = W.frame(hero, "XP", 20, 268, 196, 24, W.navy, 12)
	W.stroke(track, W.navy, 4)
	self.xpFill = W.frame(track, "Fill", 0, 0, 0, 24, W.white, 12)
	W.gradient(self.xpFill, rgb(190, 255, 150), rgb(62, 178, 52), 90)
	self.xp = words(track, "", 0, 0, 196, 24, 17)
	self.bonus = words(hero, "", 8, 302, 220, 40, 18, rgb(190, 255, 150))
	self.stats = {}
	for i, stat in {
		{ "Deepest", "Deepest mined", "Power" }, { "Mined", "Blocks mined", "Crystal" },
		{ "Favorite", "Most mined ore", "Crystal" }, { "Rarest", "Rarest find", "Skills" },
		{ "Found", "Ores found", "Book" }, { "Awards", "Achievements", "Achievements" },
		{ "Skills", "Skills learned", "Skills" }, { "Rebirths", "Rebirths", "Rebirth" },
	} do
		local x, y = 248 + (i - 1) % 2 * 261, math.floor((i - 1) / 2) * 89
		local tile = box(page, stat[2], x, y, 251, 79, tints[i])
		local well = W.frame(tile, "Icon well", 11, 11, 56, 56, W.white, 13)
		well.BackgroundTransparency = 0.72
		Icons.draw(well, stat[3], 5, 5, 46, if stat[1] == "Favorite" then W.gold else nil)
		words(tile, stat[2], 78, 8, 166, 24, 18, rgb(255, 250, 215), true)
		local value = words(tile, "", 78, 32, 166, 38, 28, nil, true)
		W.largest(value, 28, 15)
		self.stats[stat[1]] = value
	end
end

function Panel:buildFriends()
	local page = W.frame(self.card.body, "Friends", 7, 7, 764, 358, W.panel)
	page.BackgroundTransparency = 1
	self.friendsPage = page
	local banner, paint = box(page, "Friend bonus", 0, 0, 764, 84, mint)
	self.bannerPaint = paint
	Burst.rays(banner, 52, 42, 560, 9, W.white, 0.86)
	Icons.draw(banner, "Friends", 18, 13, 56)
	self.bannerTitle = words(banner, "", 92, 8, 440, 38, 31, nil, true)
	self.bannerText = words(banner, "", 92, 46, 440, 28, 19, rgb(255, 250, 200), true)
	W.largest(self.bannerText, 19, 13)
	local invite, invitePaint, inviteLabel = press(banner, "Invite friends", 556, 15, 190, 52, 25)
	invitePaint.Color, inviteLabel.Text = green, "Invite friends"
	W.largest(inviteLabel, 25, 15)
	invite.Activated:Connect(function() self:invite() end)
	self.status = words(page, "", 0, 150, 764, 60, 22)
	self.status.TextWrapped = true
	self.list = Card.scroller(page, "Online friends", 0, 96, 764, 256)
end

-- A box in the header: type a miner's name and press Enter to see their profile.
function Panel:buildSearch()
	local header = self.card.header
	local field = W.frame(header, "Search", self.card.size.X - 66 - 280, 16, 266, 44, W.navy, 22)
	field.BackgroundTransparency = 0.25
	W.stroke(field, W.white, 2).Transparency = 0.5
	local lens = W.frame(field, "Lens", 13, 11, 16, 16, W.white, 8)
	lens.BackgroundTransparency = 1
	W.stroke(lens, W.white, 3)
	local handle = W.frame(field, "Handle", 26, 26, 9, 4, W.white, 2)
	handle.Rotation = 45
	local box = Instance.new("TextBox")
	box.Name, box.BackgroundTransparency, box.ClearTextOnFocus = "Name", 1, false
	box.Position, box.Size = UDim2.fromOffset(44, 0), UDim2.fromOffset(212, 44)
	box.Font, box.TextSize, box.TextColor3, box.Text = Enum.Font.FredokaOne, 21, W.white, ""
	box.PlaceholderText, box.PlaceholderColor3 = "Find a miner", rgb(205, 200, 235)
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = field
	box.FocusLost:Connect(function(enter)
		if enter then self:search(box.Text) end
	end)
	self.searchField, self.searchBox = field, box
end

-- Finds a miner in this server by user name or display name: an exact match first, then the start of one.
function Panel:search(text)
	text = string.lower((text or ""):match("^%s*(.-)%s*$"))
	if text == "" then
		self:view(nil)
		return
	end
	local found
	for _, exact in { true, false } do
		for _, other in Players:GetPlayers() do
			for _, label in { other.Name, other.DisplayName } do
				local lower = string.lower(label)
				if (exact and lower == text) or (not exact and lower:sub(1, #text) == text) then
					found = found or other
				end
			end
		end
		if found then break end
	end
	if found then
		self:view(if found == self.menu.player then nil else found)
	else
		self:say("No miner called \"" .. text .. "\" in this server.")
	end
end

-- Shows `miner`'s profile, or the player's own with nil.
function Panel:view(miner)
	self.target = miner
	local shown = miner or self.menu.player
	self.face.Image = if shown.UserId > 0 then string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", shown.UserId) else ""
	self.back.Visible = miner ~= nil
	self.said = nil
	if not miner then self.searchBox.Text = "" end
	self:refresh()
end

-- Opens Roblox's own invite window, for everyone or for one friend.
function Panel:invite(friendId)
	local player = self.menu.player
	self.menu.invited = true
	if Run:IsStudio() then
		self:say("Invites open in the published game.")
		return
	end
	task.spawn(function()
		local ok, can
		if friendId then
			ok, can = pcall(Social.CanSendGameInviteAsync, Social, player, friendId)
		else
			ok, can = pcall(Social.CanSendGameInviteAsync, Social, player)
		end
		if not ok or not can then
			self:say(if friendId then "This friend can't be invited right now." else "Invites aren't available right now.")
			return
		end
		pcall(function()
			if friendId then
				local options = Instance.new("ExperienceInviteOptions")
				options.InviteUser = friendId
				Social:PromptGameInvite(player, options)
			else
				Social:PromptGameInvite(player)
			end
		end)
	end)
end

-- A short answer in the card's header.
function Panel:say(text)
	self.said = text
	self.card.sub.Text = text
	task.delay(4, function()
		if self.said == text then
			self.said = nil
			self:refresh()
		end
	end)
end

-- Friends who are online, those here first, then those in another server of this game.
function Panel:load()
	if self.loading or os.clock() - self.asked < 5 then
		self:drawFriends()
		return
	end
	self.loading, self.asked = true, os.clock()
	if #self.friends == 0 then self.status.Text = "Looking for friends…" end
	task.spawn(function()
		local player = self.menu.player
		local seen, list = {}, {}
		local ok, online = pcall(function()
			return player:GetFriendsOnlineAsync(100)
		end)
		for _, friend in if ok then online else {} do
			local id = friend.VisitorId
			if not seen[id] then
				seen[id] = true
				table.insert(list, {
					id = id, name = friend.DisplayName or friend.UserName, here = Players:GetPlayerByUserId(id) ~= nil,
					playing = friend.PlaceId == game.PlaceId and game.PlaceId ~= 0 and friend.GameId ~= nil, where = friend.LastLocation,
				})
			end
		end
		if practice then
			-- Nobody has friends in an unpublished test, so the other miners stand in for them.
			for _, other in Players:GetPlayers() do
				if other ~= player and not seen[other.UserId] then
					table.insert(list, { id = other.UserId, name = other.DisplayName, here = true })
				end
			end
		end
		table.sort(list, function(a, b)
			local ar, br = if a.here then 1 elseif a.playing then 2 else 3, if b.here then 1 elseif b.playing then 2 else 3
			if ar ~= br then return ar < br end
			return string.lower(a.name) < string.lower(b.name)
		end)
		self.friends, self.loading = list, false
		self.failed = not ok and #list == 0
		self:drawFriends()
	end)
end

function Panel:drawFriends()
	for _, row in self.friendRows do
		row:Destroy()
	end
	table.clear(self.friendRows)
	self.status.Text = if #self.friends > 0 then "" elseif self.failed then "Your friends could not be loaded."
		else "No friends are online right now.\nInvite some and mine together!"
	for i, friend in self.friends do
		local tint = if friend.here then { rgb(166, 245, 154), rgb(52, 178, 74) } elseif friend.playing then aqua else { rgb(116, 110, 168), rgb(72, 66, 122) }
		local row = box(self.list, tostring(friend.id), 4 + (i - 1) % 2 * 374, 4 + math.floor((i - 1) / 2) * 82, 364, 72, tint)
		headshot(row, friend.id, 10, 9, 54)
		local name = words(row, friend.name, 76, 9, 166, 30, 23, nil, true)
		W.largest(name, 23, 13)
		local state = words(row, if friend.here then "In your server" elseif friend.playing then "Mining right now" else "Online", 76, 39, 166, 24, 17, rgb(255, 250, 200), true)
		state.Name = "State"
		local button, paint, label = press(row, "Action", 250, 15, 102, 42, 20)
		label.Text = if friend.here then "Here!" elseif friend.playing then "Join" else "Invite"
		paint.Color = if friend.here then grey elseif friend.playing then green else blue
		button.Interactable = not friend.here
		button.Activated:Connect(function()
			if friend.playing then
				self:say("Joining " .. friend.name .. "…")
				self.menu.net.Action:FireServer("JoinFriend", friend.id)
			else
				self:invite(friend.id)
			end
		end)
		table.insert(self.friendRows, row)
	end
	self.list.CanvasSize = UDim2.fromOffset(0, math.ceil(#self.friends / 2) * 82 + 6)
end

function Panel:open(key)
	if not self.card.modal.Visible and self.target then self:view(nil) end
	self.page = key
	self.said = nil
	self.searchField.Visible = key == "Profile"
	self.profilePage.Visible, self.friendsPage.Visible = key == "Profile", key == "Friends"
	local card = self.card
	card:select(key)
	card:setIcon(key)
	local tint = if key == "Profile" then aqua else mint
	card.headerPaint.Color = ColorSequence.new(tint[1], tint[2])
	card.heading.Text = key
	self:refresh()
	if key == "Friends" then self:load() end
end

function Panel:refresh()
	if self.target and not self.target.Parent then
		-- They left the server.
		self.target = nil
		self.back.Visible = false
		self.face.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", math.max(1, self.menu.player.UserId))
	end
	local me = self.menu.player
	local player = self.target or me
	local here = me:GetAttribute("FriendsHere") or 0
	if not self.said then
		self.card.sub.Text = if self.page == "Friends" then "Mine together for " .. FriendBonus.text .. "."
			elseif self.target then player.DisplayName .. "'s records in the Citrine Mine."
			else "Your records in the Citrine Mine."
	end
	self.nameLabel.Text = player.DisplayName .. Rebirth.richBadge(player:GetAttribute("Rebirths") or 0)
	if self.page == "Friends" then
		self.bannerTitle.Text = if here > 0 then FriendBonus.text .. " is active!" else "Play with friends for " .. FriendBonus.text
		self.bannerText.Text = if here > 0 then (if here == 1 then "A friend is" else here .. " friends are") .. " in your server."
			else "You both earn more while you share a server."
		self.bannerPaint.Color = if here > 0 then green else ColorSequence.new(mint[1], mint[2])
		return
	end
	local xp = player:GetAttribute("MiningXP") or 0
	local level = Expeditions.level(xp)
	local start = Expeditions.levelXP(level)
	local need = Expeditions.levelXP(level + 1) - start
	local rank = Expeditions.ranks[player:GetAttribute("EquippedTitle") or 1] or Expeditions.ranks[1]
	self.title.Text, self.level.Text = rank.name, "Level " .. level
	self.xpFill.Size = UDim2.fromScale(math.clamp((xp - start) / need, 0, 1), 1)
	self.xpFill.Visible = xp > start
	self.xp.Text = W.number(xp - start) .. " / " .. W.number(need) .. " XP"
	self.bonus.Text = if here > 0 and not self.target then "Friend bonus: " .. FriendBonus.text else ""
	local favorite, most, rarest, found = nil, 0, nil, 0
	for _, ore in Ores.list do
		if player:GetAttribute("Found" .. ore.name) then
			found += 1
			local count = player:GetAttribute("Lifetime" .. ore.name) or 0
			if not ore.host then
				if count > most then favorite, most = ore, count end
				if not rarest or Ores.rarityRank[ore.rarity] >= Ores.rarityRank[rarest.rarity] then rarest = ore end
			end
		end
	end
	local earned, learned = 0, 0
	for _, award in Guide.achievements do
		if (player:GetAttribute("Award" .. award.id) or 0) >= award.goal then earned += 1 end
	end
	for _ in Skills.read(player) do
		learned += 1
	end
	local board = player:FindFirstChild("leaderstats")
	local depth = board and board:FindFirstChild("Depth")
	local stats = self.stats
	stats.Deepest.Text = W.goldAmount(if depth then depth.Value else 0) .. " blocks"
	stats.Mined.Text = W.goldAmount(player:GetAttribute("Mined") or 0)
	stats.Favorite.Text = if favorite then favorite.name .. " ×" .. W.number(most) else "None yet"
	stats.Rarest.Text = if rarest then rarest.name else "None yet"
	stats.Found.Text = found .. " / " .. #Ores.list
	stats.Awards.Text = earned .. " / " .. #Guide.achievements
	stats.Skills.Text = learned .. " / " .. #Skills.nodes
	stats.Rebirths.Text = tostring(player:GetAttribute("Rebirths") or 0)
end

return Panel
