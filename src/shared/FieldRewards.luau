-- Daily rewards and playtime gifts. Days are UTC days counted on the server.
-- The rewards below are placeholders: change an entry's amounts, name or icon here and the menu,
-- the claim and the notice all follow. An entry can hold any of gold, gems, flares and pulses.
local Field = {}

-- Seven days, then it starts again at day 1. Missing a day keeps the place on the card.
Field.daily = {
	{ name = "Pocket change", gold = 50, icon = "Coins" },
	{ name = "Gem chips", gems = 2, icon = "Crystal" },
	{ name = "Survey flare", flares = 1, icon = "Beacon" },
	{ name = "Coin pouch", gold = 200, icon = "Coins" },
	{ name = "Gem cluster", gems = 5, icon = "Crystal" },
	{ name = "Cave pulse", pulses = 1, icon = "Power" },
	{ name = "Citrine cache", gold = 500, gems = 15, flares = 2, icon = "Playtime" },
}

-- Gifts for time played today: at 5 and 10 minutes, then every 10 minutes up to an hour.
local minutes = { 5, 10, 20, 30, 40, 50, 60 }
local prizes = {
	{ name = "Pocket change", gold = 25, icon = "Coins" },
	{ name = "Gem chip", gems = 1, icon = "Crystal" },
	{ name = "Coin stack", gold = 50, icon = "Coins" },
	{ name = "Survey flare", flares = 1, icon = "Beacon" },
	{ name = "Coin pouch", gold = 100, icon = "Coins" },
	{ name = "Gem pair", gems = 2, icon = "Crystal" },
	{ name = "Gift chest", gold = 250, gems = 5, icon = "Playtime" },
}
Field.gifts = {}
for i, reward in prizes do
	Field.gifts[i] = { minutes = minutes[i], seconds = minutes[i] * 60, reward = reward }
end
Field.maxGiftTime = Field.gifts[#Field.gifts].seconds
Field.hasteCuts, Field.stoneChips = 12, 6

local kinds = {
	{ key = "gold", one = "gold", many = "gold" },
	{ key = "gems", one = "gem", many = "gems" },
	{ key = "flares", one = "flare", many = "flares" },
	{ key = "pulses", one = "cave pulse", many = "cave pulses" },
}
function Field.describe(reward)
	local parts = {}
	for _, kind in kinds do
		local amount = reward[kind.key]
		if amount then
			table.insert(parts, "+" .. amount .. " " .. (if amount == 1 then kind.one else kind.many))
		end
	end
	return table.concat(parts, "  ")
end
function Field.grant(p, reward)
	for _, kind in kinds do
		if reward[kind.key] then
			p[kind.key] = (p[kind.key] or 0) + reward[kind.key]
		end
	end
end

-- Today's place on the daily card. The day that can be claimed, or nil, and how many are done.
function Field.dailyState(count, last, today)
	local ready = today ~= nil and (last or 0) < today
	local done = count or 0
	if ready then
		done %= #Field.daily
	end
	return if ready then done + 1 else nil, done
end
function Field.claim(p, today)
	local day = Field.dailyState(p.stampCount, p.stampDay, today)
	if not day then return nil end
	p.stampCount, p.stampDay = day, today
	Field.grant(p, Field.daily[day])
	return day, Field.daily[day]
end

-- Only the anchor lives in the session. Reconnecting starts a new measured
-- interval, while the save holds the elapsed time from earlier visits today.
function Field.trackGifts(session, now)
	local p = session.profile
	local last = session.giftAt or now
	if now < last then return end
	local day = math.floor(now / 86400)
	session.giftAt = now
	if day < p.giftDay then return end
	if day > p.giftDay then
		p.giftDay, p.giftSeconds, p.giftClaims = day, 0, 0
	end
	local elapsed = now - math.max(last, day * 86400)
	p.giftSeconds = math.min(Field.maxGiftTime, p.giftSeconds + elapsed)
end

-- Claims gift `requested` and any earlier one still waiting. Returns the rewards given, or nil.
function Field.claimGift(session, now, requested)
	Field.trackGifts(session, now)
	local p = session.profile
	local gift = type(requested) == "number" and Field.gifts[requested]
	if p.giftDay ~= math.floor(now / 86400) or not gift or requested <= p.giftClaims or p.giftSeconds < gift.seconds then
		return nil
	end
	local given = {}
	for i = p.giftClaims + 1, requested do
		Field.grant(p, Field.gifts[i].reward)
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
