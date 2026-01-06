local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = nil
local humanoid = nil
local humanoidRootPart = nil

local bobTime = 0
local lastLookVector = Vector3.new(0, 0, -1)
local swayAmount = 0
local targetSway = 0

local function setupCharacter()
	if not player.Character then return end
	character = player.Character
	humanoid = character:WaitForChild("Humanoid", 10)
	humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
	
	if camera then
		lastLookVector = camera.CFrame.LookVector
	end
	
	bobTime = 0
	swayAmount = 0
	targetSway = 0
end

local SprintSystem = nil
local function getSprintSystem()
	if not SprintSystem then
		local success, module = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("SprintSystem"))
		end)
		if success then
			SprintSystem = module
		end
	end
	return SprintSystem
end

RunService.RenderStepped:Connect(function(dt)
	if not camera or not humanoidRootPart or not humanoid then return end
	
	local sprintModule = getSprintSystem()
	local isSprinting = false
	if sprintModule then
		isSprinting = humanoid.WalkSpeed >= sprintModule.SPRINT_SPEED - 0.5
	end
	
	local velocity = humanoidRootPart.Velocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local isMoving = horizontalSpeed > 1
	
	local currentLookVector = camera.CFrame.LookVector
	local lookChange = currentLookVector - lastLookVector
	local turnAmount = Vector3.new(lookChange.X, 0, lookChange.Z).Magnitude
	
	if turnAmount > 0.01 then
		local turnDirection = math.sign((currentLookVector - lastLookVector):Cross(lastLookVector).Y)
		targetSway = math.clamp(turnAmount * 0.3, -0.15, 0.15) * turnDirection
	else
		targetSway = targetSway * 0.9
	end
	
	swayAmount = swayAmount + (targetSway - swayAmount) * (dt * 8)
	lastLookVector = currentLookVector
	
	if isMoving then
		local bobSpeed = isSprinting and 12 or 8
		local bobAmplitude = isSprinting and 0.15 or 0.08
		
		bobTime = bobTime + (dt * bobSpeed)
		local verticalBob = math.sin(bobTime) * bobAmplitude
		
		local cameraCFrame = camera.CFrame
		local rightVector = cameraCFrame.RightVector
		local upVector = cameraCFrame.UpVector
		
		local bobOffset = (upVector * verticalBob) + (rightVector * swayAmount)
		local newCFrame = cameraCFrame * CFrame.new(bobOffset)
		camera.CFrame = newCFrame
	else
		bobTime = bobTime * 0.95
		swayAmount = swayAmount * 0.9
		
		if math.abs(swayAmount) > 0.001 then
			local cameraCFrame = camera.CFrame
			local rightVector = cameraCFrame.RightVector
			local bobOffset = rightVector * swayAmount
			camera.CFrame = cameraCFrame * CFrame.new(bobOffset)
		end
	end
end)

if player.Character then
	setupCharacter()
end

player.CharacterAdded:Connect(function()
	setupCharacter()
end)

player.CharacterRemoving:Connect(function()
	character = nil
	humanoid = nil
	humanoidRootPart = nil
end)

