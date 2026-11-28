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
	Hook = Vector2.new(0, 6), Tempo = Vector2.new(1, 6), Lamp = Vector2.new(2, 6), Beacon = Vector2.new(3, 6),
	Boot = Vector2.new(0, 7), Spring = Vector2.new(1, 7), Jobs = Vector2.new(2, 7), Coins = Vector2.new(3, 7),
	Flame = Vector2.new(0, 8), Clover = Vector2.new(1, 8), Assay = Vector2.new(2, 8), Showoff = Vector2.new(3, 8),
	Compass = Vector2.new(0, 9),
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
-- The bundled pixels must fit one EditableImage (at most 1024 by 1024): eight 128px tiles per row.
local Encoding = game:GetService("EncodingService")
local pixels = Encoding:DecompressBuffer(
	Encoding:Base64Decode(buffer.fromstring(source.Pixels.Value)),
	Enum.CompressionAlgorithm.Zstd
)
assert(buffer.len(pixels) == 1024 * 640 * 4, "bundled Field Kit atlas is not 1024 by 640")
local function packed(tile)
	local index = tile.Y * 4 + tile.X
	return Vector2.new(index % 8, index // 8) * 128
end
-- The real path: one EditableImage, every icon cut from its own tile.
local real = source:Clone()
real:SetAttribute("ImageId", nil)
real.Parent = source.Parent
local bundled = require(real)
local shelf = Instance.new("Frame")
for key, tile in tiles do
	assert(bundled.draw(shelf, key))
	local label = shelf["Field Kit"]
	assert(label:IsA("ImageLabel"), key .. " fell back to GUI strips; the EditableImage did not load")
	assert(label.ImageRectOffset == packed(tile) and label.ImageRectSize == Vector2.one * 128, key)
	label:Destroy()
end
shelf:Destroy()
real:Destroy()
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
for _, key in { "Inventory", "Skills", "Achievements", "Book", "Settings", "Daily", "Playtime", "Rebirth", "Power", "Speed", "Profile", "Friends", "Pack", "Capacity", "Titles", "Gear", "Crew",
	"Hook", "Tempo", "Lamp", "Beacon", "Boot", "Spring", "Jobs", "Coins", "Flame", "Clover", "Assay", "Showoff", "Compass", "Crystal" } do
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
assert(not renderer.draw(container, "No such icon"))
container:Destroy()
probe:Destroy()
print("PASS bundled 1024x640 Field Kit atlas loads, published write denial, all thirty-seven icons and six aliases")
