-- Attendance is counted in UTC days on the server. Missing a day keeps the stamp card.
local Field = {}
Field.stamps = { 1, 2, 3, 4, 5, 6, 15 }
Field.hasteCuts, Field.stoneChips = 12, 6

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
