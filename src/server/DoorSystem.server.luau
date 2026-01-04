local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DoorRemoteEvents = require(ReplicatedStorage.Shared.Modules.DoorRemoteEvents)

local LOCKED_DOORS = {
	["Door1"] = true,
	["Door2"] = false,
}

local function isPathClear(playerPosition, doorPart, character)
	local rayOrigin = playerPosition
	local rayDirection = doorPart.Position - playerPosition
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {character, doorPart}
	
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		local hitPart = raycastResult.Instance
		if hitPart ~= doorPart and not hitPart:IsDescendantOf(doorPart.Parent) then
			return false
		end
	end
	
	return true
end

DoorRemoteEvents.DoorOpen.OnServerEvent:Connect(function(player, doorPart)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	
	if not rootPart then return end
	
	if not isPathClear(rootPart.Position, doorPart, character) then
		return
	end
	
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
	
	local currentCFrame = rootPart.CFrame
	local lookVector = currentCFrame.LookVector
	local teleportDistance = 3.5
	
	local originalPosition = currentCFrame.Position
	local doorPosition = doorPart.Position
	local doorLookVector = doorPart.CFrame.LookVector
	local toOriginalPlayer = originalPosition - doorPosition
	local originalSide = toOriginalPlayer:Dot(doorLookVector)
	
	local newPosition = originalPosition + (lookVector * teleportDistance)
	local newCFrame = CFrame.new(newPosition, newPosition + lookVector)
	rootPart.CFrame = newCFrame
	
	local toNewPlayer = newPosition - doorPosition
	local newSide = toNewPlayer:Dot(doorLookVector)
	
	local needsSecondTeleport = false
	if math.abs(originalSide) < 0.5 then
		needsSecondTeleport = true
	elseif (originalSide > 0 and newSide > 0) or (originalSide < 0 and newSide < 0) then
		needsSecondTeleport = true
	end
	
	if needsSecondTeleport then
		newPosition = newPosition + (lookVector * teleportDistance)
		newCFrame = CFrame.new(newPosition, newPosition + lookVector)
		rootPart.CFrame = newCFrame
	end
	
	DoorRemoteEvents.DoorProximity:FireClient(player)
end)

