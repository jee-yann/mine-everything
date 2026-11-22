-- Show the world as soon as Roblox can render it.
game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()

-- The native orientation setting applies on mobile and permits either landscape edge.
local gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
gui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
