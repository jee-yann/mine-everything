-- Run in Studio edit mode. The clone simulates the published client's permission
-- failure after image allocation while exercising the real pixels and GUI renderer.
local source = game.StarterPlayer.StarterPlayerScripts.Client.FieldKit
local tiles = {
	Inventory = Vector2.new(0, 0), Skills = Vector2.new(1, 0), Achievements = Vector2.new(2, 0), Daily = Vector2.new(3, 0),
	Book = Vector2.new(0, 1), Settings = Vector2.new(1, 1), Playtime = Vector2.new(2, 1), Rebirth = Vector2.new(3, 1),
	Power = Vector2.new(0, 2), Speed = Vector2.new(1, 2), Profile = Vector2.new(2, 2), Friends = Vector2.new(3, 2),
	Shop = Vector2.new(0, 3), Pets = Vector2.new(1, 3), Geode = Vector2.new(2, 3), Gems = Vector2.new(3, 3),
	Forge = Vector2.new(0, 4), Boosts = Vector2.new(1, 4), Passes = Vector2.new(2, 4), Trail = Vector2.new(3, 4),
	GoldPouch = Vector2.new(0, 5), GoldBag = Vector2.new(1, 5), GoldChest = Vector2.new(2, 5), GoldVault = Vector2.new(3, 5),
}
local imageId = source:GetAttribute("ImageId")
if imageId then
	-- Only set once the current atlas is uploaded.
	local remote = Instance.new("Frame")
	local uploaded = require(source)
	for key, tile in tiles do
		uploaded.draw(remote, key)
		local label = remote["Field Kit"]
		assert(label:IsA("ImageLabel") and label.Image == "rbxassetid://" .. imageId)
		assert(label.ImageRectSize == Vector2.one * 256 and label.ImageRectOffset == tile * 256, key)
		label:Destroy()
	end
	remote:Destroy()
end
local probe = source:Clone()
probe:SetAttribute("ImageId", nil)
local replacement = [[
local Assets = { CreateEditableImage = function()
	assert(not script:GetAttribute("Allocated"), "Retried the denied image for another icon")
	script:SetAttribute("Allocated", true)
	return {
		WritePixelsBuffer = function() error("EditableImage is not accessible") end,
		Destroy = function() script:SetAttribute("Released", true) end,
	}
end }
]]
local instrumented, edits = source.Source:gsub('local Assets = game:GetService%("AssetService"%)', replacement, 1)
assert(edits == 1)
probe.Source = instrumented
local renderer = require(probe)
local container = Instance.new("Frame")
for _, key in { "Inventory", "Skills", "Achievements", "Book", "Settings", "Daily", "Playtime", "Rebirth", "Power", "Speed", "Profile", "Friends", "Pack", "Capacity", "Titles", "Gear", "Crew" } do
	assert(renderer.draw(container, key))
	local icon = container["Field Kit"]
	assert(icon:IsA("Frame") and #icon:GetChildren() > 25 and icon:FindFirstChildWhichIsA("UIGradient", true), key)
	local rows = {}
	for _, strip in icon:GetChildren() do
		rows[strip.Position.Y.Scale] = true
	end
	local count = 0
	for _ in rows do
		count += 1
	end
	assert(count >= 80, key .. " lost its full-detail artwork")
	icon:Destroy()
end
assert(probe:GetAttribute("Allocated") and probe:GetAttribute("Released"))
assert(not renderer.draw(container, "Hook"))
container:Destroy()
probe:Destroy()
print("PASS published Field Kit write denial, all twenty-four icons and five aliases")
