-- Now and then, while somebody mines alone, a reminder that mining with a friend gives more XP. It comes
-- right after a level when it can, never more than three times a visit, and stops once they invite.
local FriendBonus = require(game:GetService("ReplicatedStorage").Shared.FriendBonus)
local W = require(script.Parent.Widgets)
local Input = game:GetService("UserInputService")
local Hint = { first = 240, gap = 600, patience = 150, limit = 3 }

-- Whether to show it now. `mined` is the seconds spent mining since the last one.
function Hint.due(state)
	if state.friends > 0 or state.invited or not state.onboarded or state.busy or state.shown >= Hint.limit then return false end
	local wait = if state.shown == 0 then Hint.first else Hint.gap
	if state.mined < wait then return false end
	return state.sinceLevel < 10 or state.mined >= wait + Hint.patience
end

function Hint.start(player, hud, mining)
	if game:GetService("ReplicatedStorage"):GetAttribute("MiningTestMode") then return end
	local mined, shown, levelAt = 0, 0, -math.huge
	local last = 0
	player:GetAttributeChangedSignal("Level"):Connect(function()
		levelAt = os.clock()
	end)
	local function announce()
		local now = player:GetAttribute("FriendsHere") or 0
		if now > 0 and last == 0 then
			task.spawn(function()
				-- Not over the opening or a menu.
				while hud.root.Parent and (hud.inOpening or hud.overlay.Visible or not hud.root.Visible) do
					task.wait(0.5)
				end
				if (player:GetAttribute("FriendsHere") or 0) > 0 then
					hud:milestone("FRIEND BONUS", FriendBonus.text .. " while a friend is here!", W.green)
				end
			end)
		end
		last = now
	end
	player:GetAttributeChangedSignal("FriendsHere"):Connect(announce)
	task.delay(8, announce)
	local lastWorked = -math.huge
	task.spawn(function()
		while hud.root.Parent do
			task.wait(1)
			local working = mining()
			if working then
				mined += 1
				lastWorked = os.clock()
			end
			local step = player:GetAttribute("ExpeditionStep")
			if Hint.due({
				friends = last, invited = hud.menu.invited, onboarded = step == "Done" or step == "Skipped", shown = shown,
				mined = mined, sinceLevel = os.clock() - levelAt,
				-- A pause between two blocks still counts as mining.
				busy = os.clock() - lastWorked > 5 or hud.overlay.Visible or hud.unlocks.playing or hud.ribbon.Visible
					or hud.guidingSkills or hud.guidingRebirth or os.clock() < (hud.untilTime or 0),
			}) then
				shown += 1
				mined = 0
				local keyboard = Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
				hud:milestone("MINE WITH FRIENDS", FriendBonus.text .. (if keyboard then "  ·  Press F to invite" else "  ·  Invite in Friends"), W.green)
			end
		end
	end)
end

return Hint
