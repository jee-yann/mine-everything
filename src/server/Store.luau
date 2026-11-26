-- Game passes, developer products and their rewards. The server decides everything:
--   * pass ownership is checked with MarketplaceService when a miner joins and when a purchase finishes;
--   * developer product receipts are granted once: each PurchaseId is stored in the profile, the profile
--     is saved, and only then is the receipt reported as granted (a retry after a failed save never
--     gives the reward twice in one session, and is granted again only if the earlier grant was lost);
--   * players whose region restricts paid random items can't open paid geodes or buy luck.
-- In an unpublished Studio test, items without an ID can be tried for free instead.
local Players = game:GetService("Players")
local Market = game:GetService("MarketplaceService")
local Policy = game:GetService("PolicyService")
local Run = game:GetService("RunService")
local Rep = game:GetService("ReplicatedStorage")
local Shared = Rep.Shared
local S, C = require(Shared.StoreConfig), require(Shared.Collectibles)
local Config, Ores, Upgrades = require(Shared.GameConfig), require(Shared.Ores), require(Shared.Upgrades)
local Skills, Purity, Rebirth = require(Shared.Skills), require(Shared.OrePurity), require(Shared.Rebirth)
local Collection = require(script.Parent.Collection)
local DSS = game:GetService("DataStoreService")
local Store = { owned = {}, sold = {} }
-- The player a receipt belongs to. Tests swap this for a stand-in.
function Store.playerFor(userId)
	return Players:GetPlayerByUserId(userId)
end
local receiptLimit = 500

local function practice(player)
	return Run:IsStudio() and (game.GameId == 0 or player.UserId <= 0)
end

-- The benefits a miner has, from the passes they own.
function Store.benefits(player)
	local out = {}
	for key in Store.owned[player] or {} do
		for _, benefit in S.passByKey[key].grants do
			out[benefit] = true
		end
	end
	return out
end

-- Publishes the Passes attribute and the older single-pass attributes other code reads.
local function publish(player)
	local benefits, list = Store.benefits(player), {}
	for key in benefits do
		table.insert(list, key)
	end
	table.sort(list)
	player:SetAttribute("Passes", table.concat(list, ","))
	local owned = {}
	for key in Store.owned[player] or {} do
		table.insert(owned, key)
	end
	table.sort(owned)
	player:SetAttribute("OwnedPasses", table.concat(owned, ","))
	player:SetAttribute("DoubleGold", benefits.DoubleGold == true)
	player:SetAttribute("PrismTrail", benefits.PrismTrail == true)
	player:SetAttribute("VIP", benefits.VIP == true)
	if Store.onChange then Store.onChange(player) end
end

local function own(player, key)
	if player.Parent ~= Players then return end
	Store.owned[player] = Store.owned[player] or {}
	Store.owned[player][key] = true
	publish(player)
end

function Store.join(player)
	Store.owned[player] = {}
	publish(player)
	task.spawn(function()
		-- Unknown means restricted: paid chance is only offered once Roblox says it's allowed.
		local restricted = true
		for attempt = 1, 3 do
			local ok, info = pcall(Policy.GetPolicyInfoForPlayerAsync, Policy, player)
			if ok and type(info) == "table" then
				restricted = info.ArePaidRandomItemsRestricted == true
				break
			end
			task.wait(attempt)
		end
		if practice(player) then restricted = Rep:GetAttribute("TestPaidRandomRestricted") == true end
		player:SetAttribute("PaidRandomRestricted", restricted)
	end)
	for _, pass in S.passes do
		if pass.id <= 0 then continue end
		task.spawn(function()
			for attempt = 1, 3 do
				if player.Parent ~= Players then return end
				local ok, owns = pcall(Market.UserOwnsGamePassAsync, Market, player.UserId, pass.id)
				if ok then
					if owns then own(player, pass.key) end
					return
				end
				task.wait(attempt * 2)
			end
		end)
	end
end

function Store.leave(player)
	Store.owned[player] = nil
end

-- Limited stock is counted across every server in one DataStore entry per item. An unpublished Studio
-- test counts in memory instead.
local function limitedStore()
	return DSS:GetDataStore("EndlessMining_v1_Limited", if Run:IsStudio() then "studio" else "live")
end
local function unpublished()
	return Run:IsStudio() and game.GameId == 0
end
-- How many of a limited item are left, as last read. Published on ReplicatedStorage as Limited<key>.
function Store.left(item)
	return math.max(0, item.limited - (Store.sold[item.key] or 0))
end
local function publishStock(item)
	Rep:SetAttribute("Limited" .. item.key, Store.left(item))
end
function Store.readStock(item)
	if not unpublished() then
		local ok, sold = pcall(function() return limitedStore():GetAsync(item.key) end)
		if ok and type(sold) == "number" then Store.sold[item.key] = sold end
	end
	publishStock(item)
end
-- Counts one more sold. A purchase that arrives after the last one sold is still given: it was paid.
local function countSale(item)
	Store.sold[item.key] = (Store.sold[item.key] or 0) + 1
	if not unpublished() then
		task.spawn(function()
			local ok, sold = pcall(function()
				return limitedStore():UpdateAsync(item.key, function(old) return (old or 0) + 1 end)
			end)
			if ok and type(sold) == "number" then Store.sold[item.key] = sold end
			publishStock(item)
		end)
	end
	publishStock(item)
end

-- Whether a player may buy this pass or product now, and why not.
function Store.allowed(player, item)
	if item.luck and player:GetAttribute("PaidRandomRestricted") ~= false then
		return false, "Sorry, luck boosts aren't available in your region"
	end
	return true
end

-- About an hour of this miner's own earnings, without passes, pets or boosts: their deepest region's
-- average sale value per block times the blocks an hour at their Speed, Power and skills, at a relaxed
-- pace (half the time is spent cutting, and each full pack costs a 30-second trip to sell), times their
-- rebirth bonus.
function Store.goldCrate(p)
	local depth = math.max(Config.DirtLayers + 1, math.floor(p.bestDepth / 5))
	local layer = Config.layer(depth * Config.Cell)
	local strength = Config.strength(-depth * Config.Cell)
	local stone, value, ore = 100, 0, 0
	for name, percent in layer.oreChances do
		local found = Ores.byName[name]
		if found and not found.secret then
			value += percent / 100 * Purity.unitPrice(found, nil, p.skills.Broker) * 1.25
			stone -= percent
			ore += percent
		end
	end
	value += math.max(0, stone) / 100 * Purity.unitPrice(Ores.byName.Stone, nil, p.skills.Broker)
	local base = Upgrades.items.Speed.values[p.levels.Speed] * Rebirth.cutMultiplier(p.rebirths or 0)
	local cut = Skills.cutTime(base, Ores.byName.Stone, strength, 0, p.skills, 0, 0, Upgrades.items.Power.values[p.levels.Power])
	local capacity = Skills.capacity(Upgrades.items.Capacity.values[p.levels.Capacity], p.skills)
	local blocks = 3600 / (cut + 0.6 + 30 / capacity) * 0.5
	return math.max(250, math.floor(blocks * value * Rebirth.goldMultiplier(p.rebirths or 0) + 0.5))
end

-- The reward of one product, given to the loaded profile. `context` holds the server hooks.
local function deliver(player, session, product, context)
	local p, now = session.profile, os.time()
	if product.gems then
		p.gems += product.gems
	end
	if product.key == "StarterPack" then
		if not p.store.starter then
			p.store.starter = true
			p.flares += 3
			Collection.boost(p.col, "gold2", 30, now)
		end
	elseif product.limited then
		p.store.limited = p.store.limited or {}
		if not p.store.limited[product.key] then
			p.store.limited[product.key] = true
			countSale(product)
		end
		if product.pet and not p.col.pets[product.pet] then
			p.col.pets[product.pet] = { l = 1, x = 0, s = 0 }
			p.col.eq = { product.pet }
		end
		context.feedback(player, "hint", product.name .. " is yours. Only " .. product.limited .. " will ever exist!")
	elseif product.boost then
		Collection.boost(p.col, product.boost, product.minutes, now)
	elseif product.key == "SellAnywhere" then
		context.sellAll(player)
	elseif product.key == "GoldCrate" then
		local gold = Store.goldCrate(p)
		p.gold += gold
		context.feedback(player, "hint", "Gold Crate: +" .. gold .. " gold")
	elseif product.key == "ServerLuck" then
		local from = math.max(Rep:GetAttribute("ServerLuckUntil") or 0, now)
		Rep:SetAttribute("ServerLuckUntil", from + product.minutes * 60)
		Rep:SetAttribute("ServerLuckBy", player.DisplayName)
		context.announce(player)
	end
	context.sync(player, p)
end

-- Runs a product's reward exactly once per PurchaseId. Returns the ProductPurchaseDecision.
function Store.receipt(info, sessions, context, save)
	local player = Store.playerFor(info.PlayerId)
	local session = player and sessions[player]
	if not session or session.resetting or not session.profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local p = session.profile
	local done = p.store.receipts
	if not done[info.PurchaseId] then
		local product
		for _, item in S.products do
			if item.id > 0 and item.id == info.ProductId then product = item end
		end
		if not product then
			warn("Unknown developer product", info.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		deliver(player, session, product, context)
		done[info.PurchaseId] = true
		table.insert(p.store.order, info.PurchaseId)
		while #p.store.order > receiptLimit do
			done[table.remove(p.store.order, 1)] = nil
		end
	end
	if not save(player, session) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- A client asks to buy a pass or product. In an unpublished Studio test an item without an ID is
-- given for free so the whole flow can be tried.
function Store.prompt(player, session, kind, key, context)
	local item = if kind == "pass" then S.passByKey[key] else S.productByKey[key]
	if not item then return end
	local ok, why = Store.allowed(player, item)
	if not ok then
		context.feedback(player, "hint", why)
		return
	end
	if kind == "pass" then
		if (Store.owned[player] or {})[key] or Store.benefits(player)[key] then
			context.feedback(player, "hint", "You already own " .. item.name)
			return
		end
	elseif item.once and (if item.limited then (session.profile.store.limited or {})[key] else session.profile.store.starter) then
		context.feedback(player, "hint", "You already have the " .. item.name)
		return
	elseif item.limited and Store.left(item) <= 0 then
		context.feedback(player, "hint", item.name .. " has sold out")
		return
	end
	if item.id > 0 then
		local sent = pcall(if kind == "pass" then Market.PromptGamePassPurchase else Market.PromptProductPurchase, Market, player, item.id)
		if not sent then context.feedback(player, "hint", "Checkout is unavailable") end
	elseif practice(player) then
		if kind == "pass" then
			own(player, key)
		else
			deliver(player, session, item, context)
		end
		context.feedback(player, "purchase", item.name, kind)
	else
		context.feedback(player, "hint", item.name .. " isn't on sale yet")
	end
end

-- VIP's free gem chest, once every 20 hours.
function Store.vipChest(player, session)
	local p, now = session.profile, os.time()
	if not Store.benefits(player).VIP then return nil, "VIP only" end
	local wait = (p.store.vipAt or 0) + S.vipChest.cooldown - now
	if wait > 0 then return nil, string.format("Next chest in %dh %02dm", wait // 3600, wait // 60 % 60) end
	p.store.vipAt = now
	p.gems += S.vipChest.gems
	return S.vipChest.gems
end

function Store.start(context)
	for _, item in S.products do
		if item.limited then
			task.spawn(function()
				while true do
					Store.readStock(item)
					task.wait(60)
				end
			end)
		end
	end
	Market.PromptGamePassPurchaseFinished:Connect(function(player, id, bought)
		if not bought then return end
		for _, pass in S.passes do
			if pass.id > 0 and pass.id == id then
				own(player, pass.key)
				context.feedback(player, "purchase", pass.name, "pass")
			end
		end
	end)
	Market.ProcessReceipt = function(info)
		return Store.receipt(info, context.sessions, context, context.saveNow)
	end
end

return Store
