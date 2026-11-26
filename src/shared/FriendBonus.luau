--!strict
-- Mining with a friend in the same server gives more mining XP. The server counts the friends and keeps
-- the count in the player's FriendsHere attribute.
local FriendBonus = {}
FriendBonus.xp = 0.25

function FriendBonus.multiplier(friends: number?): number
	return if (friends or 0) > 0 then 1 + FriendBonus.xp else 1
end

FriendBonus.text = string.format("+%d%% XP", math.round(FriendBonus.xp * 100))

return FriendBonus
