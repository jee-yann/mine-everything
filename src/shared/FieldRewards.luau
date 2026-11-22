-- Attendance is counted in UTC days on the server. Missing a day keeps the stamp card.
local Field = {}
Field.stamps = { 1, 2, 3, 4, 5, 6, 15 }
Field.hasteCuts, Field.stoneChips = 12, 6
Field.shiftRewards = {
	{ seconds = 10 * 60, gems = 1 },
	{ seconds = 20 * 60, gems = 2 },
	{ seconds = 60 * 60, gems = 4 },
}
Field.maxShiftTime = Field.shiftRewards[#Field.shiftRewards].seconds

-- Only the anchor lives in the session. Reconnecting starts a new measured
-- interval, while the save holds the elapsed time from earlier visits today.
function Field.trackShift(session, now)
	local p = session.profile
	local last = session.shiftAt or now
	if now < last then return end
	local day = math.floor(now / 86400)
	session.shiftAt = now
	if day < p.shiftDay then return end
	if day > p.shiftDay then
		p.shiftDay, p.shiftSeconds, p.shiftClaims = day, 0, 0
	end
	local elapsed = now - math.max(last, day * 86400)
	p.shiftSeconds = math.min(Field.maxShiftTime, p.shiftSeconds + elapsed)
end

function Field.claimShift(session, now, requested)
	Field.trackShift(session, now)
	local p = session.profile
	local nextIndex = p.shiftClaims + 1
	local prize = Field.shiftRewards[nextIndex]
	if p.shiftDay ~= math.floor(now / 86400) or requested ~= nextIndex or not prize or p.shiftSeconds < prize.seconds then return nil end
	p.shiftClaims = nextIndex
	p.gems += prize.gems
	return prize.gems
end

function Field.claim(p, today)
	if today <= (p.stampDay or 0) then return nil end
	local day = (p.stampCount or 0) % #Field.stamps + 1
	local gems = Field.stamps[day]
	p.stampCount, p.stampDay = day, today
	p.gems = (p.gems or 0) + gems
	return day, gems
end

function Field.cutTime(seconds, ore, haste, chips)
	if ore.name == "Stone" and (chips or 0) > 0 then return math.min(seconds, 0.12) end
	return if (haste or 0) > 0 then seconds * 0.5 else seconds
end

return Field
