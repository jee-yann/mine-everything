-- Daily rewards and playtime gifts. Each waits 18 hours: a daily reward after the last one was claimed,
-- and the playtime gifts after their round began, so playing earlier the next day still counts.
-- Rewards are crates, tonics and gold that grows with the miner: change an entry here and the menu,
-- the claim and the notice all follow. An entry can hold:
--   gold         a fixed amount of gold
--   goldMinutes  that many minutes of the miner's own earnings (Shared.Earnings)
--   goldPower    half the price of the miner's next pickaxe (Power) upgrade
--   items        { itemId = count } into the inventory (crates, tonics)
--   welcome      the Welcome Crate the first time; a Starfall Crate after that
local Collectibles = require(script.Parent.Collectibles)
local Upgrades = require(script.Parent.Upgrades)
local Field = {}

-- Seven days, then it starts again at day 1. Missing a day keeps the place on the card.
Field.daily = {
	{ name = "Welcome Crate", welcome = true, icon = "Geode" },
	{ name = "Gold Tonics", items = { GoldTonic = 2 }, icon = "Boosts" },
	{ name = "Haste Tonics", items = { HasteTonic = 2 }, icon = "Speed" },
	{ name = "Starfall Crate", items = { StarfallGeode = 1 }, icon = "Geode" },
	{ name = "Lucky Brews", items = { LuckyBrew = 2 }, icon = "Boosts" },
	{ name = "Pickaxe Bounty", goldPower = true, icon = "Power" },
	{ name = "Starfall Haul", items = { StarfallGeode = 3 }, icon = "Geode" },
}

-- Gifts for time played today: at 5 and 10 minutes, then every 10 minutes up to an hour.
local minutes = { 5, 10, 20, 30, 40, 50, 60 }
local prizes = {
	{ name = "Pocket change", goldMinutes = 3, icon = "Coins" },
	{ name = "Haste Tonic", items = { HasteTonic = 1 }, icon = "Speed" },
	{ name = "Coin stack", goldMinutes = 6, icon = "Coins" },
	{ name = "Gold Tonic", items = { GoldTonic = 1 }, icon = "Boosts" },
	{ name = "Coin pouch", goldMinutes = 10, icon = "Coins" },
	{ name = "Lucky Brew", items = { LuckyBrew = 1 }, icon = "Boosts" },
	{ name = "Gift crate", items = { StarfallGeode = 1 }, icon = "Geode" },
}
Field.gifts = {}
for i, reward in prizes do
	Field.gifts[i] = { minutes = minutes[i], seconds = minutes[i] * 60, reward = reward }
end
Field.maxGiftTime = Field.gifts[#Field.gifts].seconds
Field.hasteCuts, Field.stoneChips = 12, 6
Field.cooldown = 18 * 3600

-- Half the price of the next pickaxe upgrade (or of the last one, at the top).
function Field.powerGold(level)
	local price = Upgrades.price("Power", level) or Upgrades.price("Power", math.max(1, level - 1)) or 1000
	return math.max(100, math.floor(price / 2 / 10 + 0.5) * 10)
end

-- What a reward pays this miner. `ctx` is { perHour, power, intro }: their hourly earnings, pickaxe
-- level and whether they had their Welcome Crate. Returns gold and { itemId = count }.
function Field.amounts(reward, ctx)
	local gold = reward.gold or 0
	if reward.goldMinutes then
		gold += math.max(5, math.floor((ctx.perHour or 250) * reward.goldMinutes / 60 / 5 + 0.5) * 5)
	end
	if reward.goldPower then
		gold += Field.powerGold(ctx.power or 1)
	end
	local items = table.clone(reward.items or {})
	if reward.welcome then
		local id = if ctx.intro then "StarfallGeode" else "WelcomeGeode"
		items[id] = (items[id] or 0) + 1
	end
	return gold, items
end

-- The reward in words, each part starting with "+": "+1,240 gold", "+2 Gold Tonics".
function Field.describe(reward, ctx)
	local gold, items = Field.amounts(reward, ctx or {})
	local parts = {}
	if gold > 0 then
		local grouped = tostring(gold):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		table.insert(parts, "+" .. grouped .. " gold")
	end
	for _, item in Collectibles.items do
		local n = items[item.id]
		if n then
			table.insert(parts, "+" .. (if n > 1 then n .. " " .. item.name .. "s" else item.name))
		end
	end
	return table.concat(parts, "  ")
end

-- The context from a player's replicated attributes, for the client.
function Field.context(player)
	local col = require(script.Parent.Bonuses).decode(player:GetAttribute("Collection")) or {}
	return { perHour = player:GetAttribute("GoldBundle"), power = player:GetAttribute("Power"), intro = col.intro == true }
end

-- Gives a reward to a profile. `perHour` is the miner's hourly earnings.
function Field.grant(p, reward, perHour, daily)
	local gold, items = Field.amounts(reward, { perHour = perHour, power = p.levels and p.levels.Power, intro = p.col and p.col.intro })
	-- Early Bird: gold from the daily card is 25% bigger.
	if daily and p.skills and p.skills.EarlyBird then gold = math.floor(gold * 1.25) end
	p.gold += gold
	if p.col then
		for id, n in items do
			p.col.items[id] = (p.col.items[id] or 0) + n
		end
		if items.WelcomeGeode then p.col.intro = true end
	end
end

-- The place on the daily card: the day that can be claimed, or nil, how many are done, and the seconds
-- until the next one. `last` is when the last one was claimed.
function Field.dailyState(count, last, now)
	local wait = (last or 0) + Field.cooldown - (now or 0)
	local ready = now ~= nil and wait <= 0
	local done = count or 0
	if ready then
		done %= #Field.daily
	end
	return if ready then done + 1 else nil, done, math.max(0, wait)
end
function Field.claim(p, now, perHour)
	local day = Field.dailyState(p.stampCount, p.stampAt, now)
	if not day then return nil end
	-- The day number is kept for older servers that read the same save.
	p.stampCount, p.stampAt, p.stampDay = day, now, math.floor(now / 86400)
	Field.grant(p, Field.daily[day], perHour, true)
	return day, Field.daily[day]
end

-- Only the anchor lives in the session. Reconnecting starts a new measured
-- interval, while the save holds the elapsed time from earlier visits today.
function Field.trackGifts(session, now)
	local p = session.profile
	local last = session.giftAt or now
	if now < last then return end
	session.giftAt = now
	if now < p.giftStart then return end
	-- A round lasts 18 hours from its first moment of play. The next begins with the next play.
	if now - p.giftStart >= Field.cooldown then
		p.giftStart, p.giftDay, p.giftSeconds, p.giftClaims = now, math.floor(now / 86400), 0, 0
	end
	local elapsed = now - math.max(last, p.giftStart)
	p.giftSeconds = math.min(Field.maxGiftTime, p.giftSeconds + elapsed)
end

-- Claims gift `requested` and any earlier one still waiting. Returns the rewards given, or nil.
function Field.claimGift(session, now, requested, perHour)
	Field.trackGifts(session, now)
	local p = session.profile
	local gift = type(requested) == "number" and Field.gifts[requested]
	if not gift or requested <= p.giftClaims or p.giftSeconds < gift.seconds then
		return nil
	end
	local given = {}
	for i = p.giftClaims + 1, requested do
		Field.grant(p, Field.gifts[i].reward, perHour)
		table.insert(given, Field.gifts[i].reward)
	end
	p.giftClaims = requested
	return given
end

-- For the client: seconds played today, gifts waiting, and seconds to the next one (nil if none is left).
function Field.played(player, now)
	local clock = player:GetAttribute("GiftClock")
	return if clock then math.clamp(now - clock, 0, Field.maxGiftTime) else 0
end
function Field.giftState(player, now)
	if not player:GetAttribute("GiftClock") then return 0, nil end
	local played, claimed = Field.played(player, now), player:GetAttribute("GiftClaims") or 0
	local ready, left = 0, nil
	for i, gift in Field.gifts do
		if i > claimed then
			if played >= gift.seconds then
				ready += 1
			else
				left = gift.seconds - played
				break
			end
		end
	end
	return ready, left
end

function Field.cutTime(seconds, ore, haste, chips)
	if ore.name == "Stone" and (chips or 0) > 0 then return math.min(seconds, 0.12) end
	return if (haste or 0) > 0 then seconds * 0.5 else seconds
end

return Field
