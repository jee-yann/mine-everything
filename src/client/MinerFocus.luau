local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local Gui = game:GetService("GuiService")
local Focus = {}
Focus.__index = Focus
local range = 180
Focus.range = range

function Focus.new()
	local self = setmetatable({ tags = {} }, Focus)
	local function watch(character)
		local function capture(item)
			if item.Name ~= "Miner title" or not item:IsA("BillboardGui") then return end
			self.tags[character] = { gui = item, size = item.Size, range = item.MaxDistance, enabled = item.Enabled }
			if self.underground then item.Enabled = false end
		end
		character.DescendantAdded:Connect(capture)
		local tag = character:FindFirstChild("Miner title", true)
		if tag then capture(tag) end
	end
	local function add(player)
		if player == Players.LocalPlayer then return end
		player.CharacterAdded:Connect(watch)
		player.CharacterRemoving:Connect(function(character) self.tags[character] = nil end)
		if player.Character then watch(player.Character) end
	end
	Players.PlayerAdded:Connect(add)
	for _, player in Players:GetPlayers() do add(player) end
	return self
end

function Focus:characterOf(part)
	local ancestor = part
	while ancestor and ancestor ~= workspace do
		if self.tags[ancestor] then return ancestor end
		ancestor = ancestor.Parent
	end
end

function Focus:tap(part)
	local character = self:characterOf(part)
	if character then self.tapTarget, self.tapUntil = character, os.clock() + 1.3 end
end

function Focus:update(underground, hit, origin, params)
	local target = if underground and hit then self:characterOf(hit.Instance) else nil
	if not underground or (self.tapTarget and os.clock() >= self.tapUntil) then
		self.tapTarget = nil
	elseif self.tapTarget and self.tapTarget ~= target then
		local tag = self.tags[self.tapTarget]
		local head = tag and tag.gui.Adornee
		local visible = false
		if head and head.Parent then
			local delta = head.Position - origin
			if delta.Magnitude <= range then
				local sight = workspace:Raycast(origin, delta, params)
				visible = sight ~= nil and sight.Instance:IsDescendantOf(self.tapTarget)
			end
		end
		if visible then target = self.tapTarget else self.tapTarget = nil end
	end
	if underground == self.underground and target == self.target then return end
	self.underground, self.target = underground, target
	for character, tag in self.tags do
		if not tag.gui.Parent then self.tags[character] = nil continue end
		local focused = underground and character == target
		tag.gui.Enabled = if underground then focused else tag.enabled
		tag.gui.MaxDistance = if focused then range else tag.range
		tag.gui.Size = if focused then UDim2.fromOffset(145, 38) else tag.size
		if tag.lift then
			tag.lift:Cancel()
			tag.gui.StudsOffset = tag.restingOffset
			tag.lift = nil
		end
		if focused and Players.LocalPlayer:GetAttribute("MenuMotion") ~= false and not Gui.ReducedMotionEnabled then
			tag.restingOffset = tag.gui.StudsOffset
			tag.gui.StudsOffset = tag.restingOffset - Vector3.yAxis * 0.2
			tag.lift = Tween:Create(tag.gui, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ StudsOffset = tag.restingOffset })
			tag.lift:Play()
		end
	end
end

return Focus
