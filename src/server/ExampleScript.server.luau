-- Script example
-- This runs on the server side

print("Script running on server!")

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	print("Player joined:", player.Name)
end)

