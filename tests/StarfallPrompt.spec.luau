-- Run with Studio --task RunScript against the built place.
local source = game.StarterPlayer.StarterPlayerScripts.Client.Starfall
local frames = require(source.ExposureSheet).frames
local screen = Instance.new("ScreenGui")
screen.Parent = game:GetService("CoreGui")
local button, draw = require(source.BeaconPrompt)(screen)
local root = screen["Strike prompt"]
local face, skirt, seat = root["Strike face"], root["Strike skirt"], root["Strike socket"]
local press = frames.autoStrike
local function expose(frame, motion, contact)
	draw(frame, motion, contact, 25, 625)
end
local function y(item) return item.Position.Y.Offset end
local function outlines()
	local n = 0
	for i = 1, 4 do
		local echo = screen["Strike outline " .. i]
		assert(not echo.Active and not echo.Selectable)
		if echo.Visible then n += 1 end
	end
	return n
end
local function gone()
	assert(not button.Visible and not button.Interactable and not root.Visible and outlines() == 0 and not screen["Strike ring"].Visible)
	for _, item in screen:GetChildren() do
		assert(item.Name ~= "Strike splinter" or not item.Visible)
	end
end

expose(frames.prompt - 1, true)
gone()
expose(frames.prompt + 4, true)
assert(button.Visible and button.Interactable and root.Visible and outlines() > 0, "the cap rises ahead of its afterimages")
expose(frames.prompt + 4, false)
assert(root.Visible and outlines() == 0, "reduced motion has no afterimages")
expose(frames.prompt + 40, true)
assert(outlines() == 0 and face.BackgroundTransparency < 0.02, "a clean cap waits")
assert(root.Action.Text == "Break it open" and root["Input key"].Text ~= "")
assert(button.AbsoluteSize.Y >= 88 and button.AbsoluteSize.X > 88, "a thumb can find it")
local rest, gap = y(face), skirt.Size.Y.Offset - face.Size.Y.Offset
assert(gap > 6 and y(seat) > rest, "the cap has depth to sink through")

-- The very draw that takes the press is already down.
expose(press, true, press)
assert(root.Visible and not button.Interactable and not button.Visible, "one press")
assert(y(face) - rest > gap * 0.45, "input lag on the cap")
assert(root["Strike flash"].BackgroundTransparency < 0.5, "no confirmation")
assert(y(screen["Strike outline 4"]) < y(face), "the afterimages are the late part")
expose(press + 2.4, true, press)
assert(y(face) - rest > gap * 0.9 and skirt.Size.Y.Offset - face.Size.Y.Offset < gap * 0.2, "the cap bottoms out")
assert(outlines() == 4)
local last, fade = y(face), -1
for i = 1, 4 do
	local echo = screen["Strike outline " .. i]
	assert(y(echo) < last and echo.UIStroke.Transparency > fade, "afterimages part and fade in order")
	last, fade = y(echo), echo.UIStroke.Transparency
end
-- It moves between the film's own exposures.
expose(press + 2.5, true, press)
local a = y(screen["Strike outline 4"])
expose(press + 2.9, true, press)
assert(y(screen["Strike outline 4"]) ~= a, "held to the film's frame rate")
expose(press + 9, true, press)
assert(face.BackgroundTransparency > 0.6, "leaving before the steel lands")
expose(frames.contact2 + 1, true, press)
gone()
expose(press + 2, false, press)
assert(y(face) > rest and outlines() == 0 and not screen["Strike ring"].Visible, "reduced motion is a plain press")
-- Left alone, it steps aside for the automatic swing.
expose(frames.autoStrike - 1, true)
assert(button.Interactable)
expose(frames.autoStrike, true)
assert(not button.Interactable and not button.Visible)
expose(frames.autoStrike + 7, true)
gone()
screen:Destroy()
print("STARFALL_PROMPT_PASSED")
