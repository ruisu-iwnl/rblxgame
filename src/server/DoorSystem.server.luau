local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DoorRemoteEvents = require(ReplicatedStorage.Shared.Modules.DoorRemoteEvents)
local LOCKED_DOORS = require(ReplicatedStorage.Shared.Modules.LockedDoors)

DoorRemoteEvents.DoorOpen.OnServerEvent:Connect(function(player, doorPart)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not rootPart then return end
	
	local isLocked = LOCKED_DOORS[doorPart.Name] == true
	
	if isLocked then
		local doorLockedSound = doorPart:FindFirstChild("DoorLocked")
		if doorLockedSound and doorLockedSound:IsA("Sound") then
			doorLockedSound:Play()
		end
		DoorRemoteEvents.DoorProximity:FireClient(player)
		return
	end
	
	local doorSound = doorPart:FindFirstChild("DoorSound")
	if doorSound and doorSound:IsA("Sound") then
		doorSound:Play()
	end
	
	local frontPart = doorPart:FindFirstChild("Front")
	local backPart = doorPart:FindFirstChild("Back")
	
	if not frontPart or not backPart then
		return
	end
	
	local currentPosition = rootPart.Position
	local frontDistance = (currentPosition - frontPart.Position).Magnitude
	local backDistance = (currentPosition - backPart.Position).Magnitude
	
	local targetPosition
	if frontDistance < backDistance then
		targetPosition = backPart.Position
	else
		targetPosition = frontPart.Position
	end
	
	local lookVector = rootPart.CFrame.LookVector
	local newCFrame = CFrame.new(targetPosition, targetPosition + lookVector)
	
	rootPart.CFrame = newCFrame
	
	DoorRemoteEvents.DoorProximity:FireClient(player)
end)

