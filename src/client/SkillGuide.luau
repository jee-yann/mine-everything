-- Shows a miner who has never spent a skill point how to do it: first the way into the skill tree, then
-- the button that spends the point. Lantern Wick I is picked to begin with, and any other skill works too.
local Gui = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Skills = require(game:GetService("ReplicatedStorage").Shared.Skills)
local Spotlight, GuideButton = require(script.Parent.SurfaceSpotlight), require(script.Parent.GuideButton)
local Guide = { level = 3, calm = 1.5, shows = 25, rest = 150, limit = 3, skill = "Lamp" }

function Guide.wanted(state)
	return state.onboarded and state.level >= Guide.level and state.points > 0 and state.owned == 0
end

-- `busy` is true while the miner mines, travels or watches the opening.
function Guide.start(player, hud, busy)
	if game:GetService("ReplicatedStorage"):GetAttribute("MiningTestMode") then return end
	local outside, inside = Spotlight.new(hud.root), Spotlight.new(hud.root)
	outside.layer.Name, inside.layer.Name = "Skill spotlight", "Skill point spotlight"
	inside.layer.ZIndex = 20
	local ring = GuideButton.new()
	local calm, showing
	local tries, restUntil, picked = 0, 0, false
	local function clear()
		outside:show(nil)
		inside:show(nil)
		ring:point(nil)
		showing, hud.guidingSkills = nil, false
	end
	game:GetService("RunService").RenderStepped:Connect(function()
		local step = player:GetAttribute("ExpeditionStep")
		local wanted = player:GetAttribute("ProfileReady") == true and not hud.inOpening and not Gui.MenuIsOpen and Guide.wanted({
			onboarded = step == "Done" or step == "Skipped", level = player:GetAttribute("Level") or 1,
			points = player:GetAttribute("SkillPoints") or 0,
			owned = if next(Skills.read(player)) then 1 else 0,
		})
		local map = hud.menu.map
		local mapOpen = map ~= nil and map.screen.Visible and hud.overlay.Visible
		if not mapOpen then picked = false end
		if not wanted then
			clear()
			calm = nil
			return
		end
		local motion = player:GetAttribute("MenuMotion") ~= false and not Gui.ReducedMotionEnabled
		if mapOpen then
			outside:show(nil)
			showing, calm = nil, nil
			hud.guidingSkills = true
			if not picked then
				picked = true
				map:select(Guide.skill)
			end
			local node = map.selected and Skills.byId[map.selected]
			if node and map.learn.Visible and map.learn.Interactable and not hud.unlocks.playing then
				inside:show(map.footer, "Spend a point on " .. node.name .. "!", "Press the button, or tap another\nskill you like better.", motion,
					map.header.AbsolutePosition.Y + map.header.AbsoluteSize.Y, 0.55)
				ring:point(map.learn, motion, "Left")
			else
				inside:show(nil)
				ring:point(nil)
			end
			return
		end
		inside:show(nil)
		local now = os.clock()
		if hud.overlay.Visible or busy() then
			-- Carrying on puts it away for a while. Opening a menu does not count against it.
			if showing and not hud.overlay.Visible and now - showing > 4 then
				tries += 1
				restUntil = now + Guide.rest
			end
			clear()
			calm = nil
			return
		end
		if hud.unlocks.playing or hud.goldFlow.running or tries >= Guide.limit or now < restUntil or now < (hud.untilTime or 0)
			or Input:GetFocusedTextBox() ~= nil or (hud.chatInput and hud.chatInput.IsFocused) then
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
		hud.guidingSkills = true
		local tile = hud.skillsTile
		local button = if not hud.edgeMode then tile else hud.levelRing.button
		local points = player:GetAttribute("SkillPoints") or 0
		local how = if button ~= tile then "Tap your level"
			elseif Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then "Click Skills or press K" else "Open Skills"
		outside:show(button, "You have " .. points .. " skill point" .. (if points == 1 then "!" else "s!"), how .. ".\nSpend them to get stronger for good.", motion)
		ring:point(button, motion, "Spotlight")
	end)
end

return Guide
