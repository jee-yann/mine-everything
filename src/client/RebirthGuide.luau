-- After a Starfall, shows the way to Rebirth and what it does, without pushing: the Rebirth button first,
-- then the button inside the card. Mining on, or closing the card, puts it away for a while.
local Gui = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Rebirth = require(game:GetService("ReplicatedStorage").Shared.Rebirth)
local Spotlight, GuideButton = require(script.Parent.SurfaceSpotlight), require(script.Parent.GuideButton)
local Guide = { calm = 2, shows = 25, rest = 180, limit = 3 }

function Guide.wanted(state)
	return state.ready and not state.busy and state.tries < Guide.limit
end

-- `busy` is true while the miner mines, travels or watches a scene.
function Guide.start(player, hud, busy)
	if game:GetService("ReplicatedStorage"):GetAttribute("MiningTestMode") then return end
	local outside, inside = Spotlight.new(hud.root), Spotlight.new(hud.root)
	outside.layer.Name, inside.layer.Name = "Rebirth spotlight", "Rebirth button spotlight"
	inside.layer.ZIndex = 20
	local ring = GuideButton.new()
	local calm, showing, tries, restUntil = nil, nil, 0, 0
	local wasOpen = false
	local function clear()
		outside:show(nil)
		inside:show(nil)
		ring:point(nil)
		showing, hud.guidingRebirth = nil, false
	end
	game:GetService("RunService").RenderStepped:Connect(function()
		local ready = player:GetAttribute("ProfileReady") == true and Rebirth.ready(player:GetAttribute("RunStarfalls") or 0, player:GetAttribute("Rebirths") or 0)
		local now = os.clock()
		local panel = hud.menu.rebirth
		local cardOpen = panel ~= nil and panel.card.modal.Visible and hud.overlay.Visible
		if not ready or hud.inOpening or Gui.MenuIsOpen or hud.guidingSkills then
			clear()
			calm = nil
			return
		end
		local motion = player:GetAttribute("MenuMotion") ~= false and not Gui.ReducedMotionEnabled
		if cardOpen then
			wasOpen = true
			outside:show(nil)
			showing, calm = nil, nil
			if panel.live and not hud.unlocks.playing then
				hud.guidingRebirth = true
				local confirming = panel.confirming
				inside:show(panel.button, if confirming then "Press again to rebirth" else "You can rebirth now!",
					if confirming then "Your bonuses are for good.\nClose the card to keep this run."
						else "Bigger sales, more XP and faster cuts.\nOr close this and keep mining. It waits.", motion)
				ring:point(panel.button, motion, "Right")
			else
				inside:show(nil)
				ring:point(nil)
			end
			return
		end
		inside:show(nil)
		if wasOpen then
			-- They looked and chose to keep going. Ask again much later.
			wasOpen = false
			tries += 1
			restUntil = now + Guide.rest
		end
		if hud.overlay.Visible or busy() then
			if showing and not hud.overlay.Visible and now - showing > 4 then
				tries += 1
				restUntil = now + Guide.rest
			end
			clear()
			calm = nil
			return
		end
		if not Guide.wanted({ ready = ready, busy = hud.unlocks.playing or hud.goldFlow.running or now < restUntil
			or now < (hud.untilTime or 0) or Input:GetFocusedTextBox() ~= nil or (hud.chatInput and hud.chatInput.IsFocused), tries = tries }) then
			clear()
			calm = nil
			return
		end
		calm = calm or now
		if now - calm < Guide.calm then return end
		showing = showing or now
		if now - showing > Guide.shows then
			tries += 1
			restUntil = now + Guide.rest
			clear()
			calm = nil
			return
		end
		hud.guidingRebirth = true
		local tile = hud.rebirthTile.button
		local button = if hud.edgeMode and not hud.railsOnEdge then hud.menuShortcut else tile
		local how = if button ~= tile then "Open Menu, then Rebirth"
			elseif Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then "Click Rebirth or press U" else "Tap Rebirth"
		outside:show(button, "You found Starfall!", how .. " to start a new run\nwith bonuses that last. Only if you want to.", motion)
		ring:point(button, motion, "Spotlight")
	end)
end

return Guide
