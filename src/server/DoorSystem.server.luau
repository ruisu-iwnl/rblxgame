local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DoorRemoteEvents = require(ReplicatedStorage.Shared.Modules.DoorRemoteEvents)
local LOCKED_DOORS = require(ReplicatedStorage.Shared.Modules.LockedDoors)
local KeySystem = require(ReplicatedStorage.Shared.Modules.KeySystem)
local CollectibleRemoteEvents = require(ReplicatedStorage.Shared.Modules.CollectibleRemoteEvents)

local function isDoorUnlocked(doorPart)
	local unlockedValue = doorPart:FindFirstChild("Unlocked")
	return unlockedValue and unlockedValue:IsA("BoolValue") and unlockedValue.Value == true
end

local function unlockDoor(doorPart)
	local unlockedValue = doorPart:FindFirstChild("Unlocked")
	if not unlockedValue then
		unlockedValue = Instance.new("BoolValue")
		unlockedValue.Name = "Unlocked"
		unlockedValue.Parent = doorPart
	end
	unlockedValue.Value = true
end

DoorRemoteEvents.DoorOpen.OnServerEvent:Connect(function(player, doorPart)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not rootPart then return end
	
	local isLocked = false
	
	if isDoorUnlocked(doorPart) then
		isLocked = false
	else
		local doorKeyId = KeySystem.getKeyId(doorPart)
		
		if doorKeyId then
			local hasKey = KeySystem.hasKeyWithId(player, doorKeyId)
			
			if hasKey then
				unlockDoor(doorPart)
				isLocked = false
				
				CollectibleRemoteEvents.KeyUsed:FireClient(player, doorKeyId)
				
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					DoorRemoteEvents.DoorUnlocked:FireClient(otherPlayer, doorPart:GetFullName())
				end
			else
				isLocked = true
			end
		else
			isLocked = LOCKED_DOORS[doorPart.Name] == true
		end
	end
	
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

