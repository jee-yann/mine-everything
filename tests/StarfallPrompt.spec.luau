-- Run with Studio --task RunScript against the built place.
local source = game.StarterPlayer.StarterPlayerScripts.Client.Starfall
local frames = require(source.ExposureSheet).frames
local screen = Instance.new("ScreenGui")
screen.Parent = game:GetService("CoreGui")
local button, draw = require(source.BeaconPrompt)(screen)
local press = frames.prompt + 18
local function expose(frame, motion, contact, release)
	draw(frame, motion, contact, 25, 625, release)
end

expose(frames.prompt + 4, true, nil)
assert(button.Visible and button.Interactable and screen["Strike outline 3"].Visible)
expose(frames.prompt + 4, false, nil)
for i = 1, 3 do assert(not screen["Strike outline " .. i].Visible) end
expose(press, true, nil)
local restingY = button.Position.Y.Offset
local restSize = button.Size
local socket = screen["Strike socket"]
local baseY = socket.Position.Y.Offset
assert(button.Visible and button.Interactable)
assert(socket.Visible and baseY > restingY and not socket.Active)
for i = 1, 3 do assert(not screen["Strike outline " .. i].Visible) end
expose(press, true, press + 8)
assert(button.Visible and not button.Interactable and button.Position.Y.Offset > restingY)
assert(button.Size.Y.Offset < restSize.Y.Offset and socket.Position.Y.Offset == baseY)
expose(press + 2, true, press + 8)
assert(math.abs(button.Position.Y.Offset - baseY) < 3, "the compressed cap should bottom out in its socket")
expose(press + 6, true, press + 8, math.huge)
assert(math.abs(button.Position.Y.Offset - baseY) < 3, "holding the control keeps the cap down for the windup")
expose(press + 7, true, press + 8, press + 2)
assert(button.Position.Y.Offset < restingY and button.Size.Y.Offset > restSize.Y.Offset)
local above, transparency = button.Position.Y.Offset, 0
for i = 1, 3 do
	local echo = screen["Strike outline " .. i]
	assert(echo.Visible and not echo.Active and not echo.Selectable)
	assert(echo.Position.Y.Offset > above and echo.UIStroke.Transparency > transparency)
	above, transparency = echo.Position.Y.Offset, echo.UIStroke.Transparency
end
expose(press + 12, true, press + 8)
assert(button.Position.Y.Offset > restingY, "spring return lands on the socket")
expose(press + 16, true, press + 8)
assert(button.Visible and button.Position.Y.Offset == restingY and button.Size == restSize)
expose(press + 8, false, press + 8)
assert(button.Visible and button.Action.Text == "Path lit!" and button.Position.Y.Offset == restingY and button.Size == restSize)
for i = 1, 3 do assert(not screen["Strike outline " .. i].Visible) end
expose(press + 19, true, press + 8)
assert(not button.Visible and not button.Interactable and not socket.Visible)
expose(frames.autoStrike - 1, true, nil)
assert(button.Visible and button.Interactable)
expose(frames.autoStrike, true, frames.autoStrike + 8)
assert(not button.Visible and not button.Interactable)
for i = 1, 3 do assert(not screen["Strike outline " .. i].Visible) end
screen:Destroy()
print("STARFALL_PROMPT_PASSED")
