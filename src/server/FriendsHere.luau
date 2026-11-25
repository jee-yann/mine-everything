--!strict
-- Keeps each player's FriendsHere attribute: how many of their Roblox friends are in this server. Also
-- takes a player to a friend who is in another server of this experience.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Teleports = game:GetService("TeleportService")
local FriendsHere = {}

local here: { [Player]: { [Player]: boolean } } = {}
-- An unpublished Studio test has no friends, so every other miner counts as one there.
local function practice(): boolean
	return Run:IsStudio() and game.GameId == 0 and not game:GetService("ReplicatedStorage"):GetAttribute("MiningTestMode")
end

local function publish(player: Player)
	local count = 0
	for _ in here[player] or {} do
		count += 1
	end
	if player:GetAttribute("FriendsHere") ~= count then
		player:SetAttribute("FriendsHere", count)
	end
end

local function areFriends(a: Player, b: Player): boolean
	if practice() then return true end
	if a.UserId <= 0 or b.UserId <= 0 then return false end
	for attempt = 1, 3 do
		local ok, result = pcall(a.IsFriendsWith, a, b.UserId)
		if ok then return result end
		task.wait(attempt * 2)
	end
	return false
end

local function check(a: Player, b: Player)
	if areFriends(a, b) and here[a] and here[b] then
		here[a][b], here[b][a] = true, true
		publish(a)
		publish(b)
	end
end

local function add(player: Player)
	if here[player] then return end
	here[player] = {}
	publish(player)
	for _, other in Players:GetPlayers() do
		if other ~= player and here[other] then
			task.spawn(check, player, other)
		end
	end
end

function FriendsHere.start()
	Players.PlayerAdded:Connect(add)
	Players.PlayerRemoving:Connect(function(player)
		local friends = here[player]
		here[player] = nil
		for friend in friends or {} do
			if here[friend] then
				here[friend][player] = nil
				publish(friend)
			end
		end
	end)
	for _, player in Players:GetPlayers() do
		add(player)
	end
end

-- Returns why it did not work, or nil when the player is on the way. The friend's server is looked up
-- here, so a client only names the friend.
function FriendsHere.join(player: Player, userId: any): string?
	if type(userId) ~= "number" or userId % 1 ~= 0 or userId <= 0 or userId == player.UserId then
		return "That friend could not be found."
	end
	if Players:GetPlayerByUserId(userId) then return "Your friend is already here!" end
	if Run:IsStudio() then return "Joining a friend works in the published game." end
	local known, friend = pcall(player.IsFriendsWith, player, userId)
	if not known or not friend then return "You can only join friends." end
	local found, _, problem, placeId, jobId = pcall(function()
		return Teleports:GetPlayerPlaceInstanceAsync(userId)
	end)
	if not found or problem or not placeId or not jobId or jobId == "" then
		return "Your friend's server could not be reached."
	end
	local sent = pcall(function()
		local options = Instance.new("TeleportOptions")
		options.ServerInstanceId = jobId
		Teleports:TeleportAsync(placeId, { player }, options)
	end)
	return if sent then nil else "Your friend's server could not be reached."
end

return FriendsHere
