print("LocalScript running on client!")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

if player then
	print("Player:", player.Name)
end
