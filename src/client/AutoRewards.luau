-- Opens the rewards card by itself at a calm moment: the daily card after the first sale that follows the
-- first expedition, or a few seconds into a later visit, and the playtime tab when the first gift of the day is ready.
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Field = require(game:GetService("ReplicatedStorage").Shared.FieldRewards)
local Auto = {}
Auto.settle, Auto.quiet, Auto.afterSale = 5, 1.6, 2

-- Which page to open now, if any. `quietFor` is how long the miner has had nothing going on.
function Auto.choose(state)
	if not state.onboarded then return nil end
	-- On a first visit the daily card waits for the next sale: two seconds, then as soon as its gold is in.
	local daily = state.dailyReady and not state.dailyShown and not state.underground
	if state.firstVisit and daily then
		if state.sinceSale and state.sinceSale >= Auto.afterSale and state.quietFor > 0 then return "Daily" end
		daily = false
	end
	if state.quietFor < Auto.quiet or state.sinceReady < Auto.settle then return nil end
	if daily then return "Daily" end
	if state.giftsReady > 0 and state.giftsClaimed == 0 and not state.giftShown then return "Playtime" end
	return nil
end

function Auto.start(player, hud, busy, underground)
	if game:GetService("ReplicatedStorage"):GetAttribute("MiningTestMode") then return end
	local since, calm, firstVisit, doneAt
	local shown = {}
	local day
	task.spawn(function()
		while hud.root.Parent do
			task.wait(0.25)
			local now = os.clock()
			local step = player:GetAttribute("ExpeditionStep")
			local onboarded = step == "Done" or step == "Skipped"
			if step and player:GetAttribute("ProfileReady") then
				if not onboarded then firstVisit, doneAt = true, nil else doneAt = doneAt or now end
			end
			if busy() or not player:GetAttribute("ProfileReady") or not onboarded then
				since = if onboarded then since else nil
				calm = nil
				if busy("opening") then since = nil end
				continue
			end
			since = since or now
			local occupied = hud.overlay.Visible or hud.unlocks.playing or GuiService.MenuIsOpen
				or Input:GetFocusedTextBox() ~= nil or (hud.chatInput and hud.chatInput.IsFocused)
				or os.clock() < (hud.untilTime or 0) or hud.goldFlow.running
			calm = if occupied then nil else calm or now
			-- A new day offers both again.
			if day ~= hud.net:GetAttribute("OrderDay") then
				day = hud.net:GetAttribute("OrderDay")
				shown = {}
			end
			local sold = hud.soldAt
			local page = Auto.choose({
				firstVisit = firstVisit, sinceSale = if sold and doneAt and sold > doneAt then now - sold else nil,
				onboarded = true, sinceReady = now - since, quietFor = if calm then now - calm else 0,
				dailyReady = hud.menu:attention("Daily"), dailyShown = shown.Daily, giftShown = shown.Playtime,
				giftsReady = Field.giftState(player, workspace:GetServerTimeNow()),
				giftsClaimed = player:GetAttribute("GiftClaims") or 0, underground = underground(),
			})
			if page then
				shown[page], calm = true, nil
				hud.menu.arrival = true
				hud:openPage(page)
			end
		end
	end)
end

return Auto
