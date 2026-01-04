local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local spotlight = nil
local attachment = nil
local humanoidRootPart = nil
local bobOffsetY = 0
local bobOffsetX = 0
local targetOffsetY = 0
local targetOffsetX = 0
local bobTime = 0
local currentLookVector = Vector3.new(0, 0, -1)
local lastUpdateTime = tick()

local function setupFlashlight()
	if not player.Character then return end
	
	local character = player.Character
	humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoidRootPart then return end
	
	local existingAttachment = humanoidRootPart:WaitForChild("FlashlightAttachment", 5)
	if existingAttachment then
		spotlight = existingAttachment:FindFirstChild("Flashlight")
		attachment = existingAttachment
	end
end

local function updateFlashlight()
	if not spotlight or not spotlight.Parent then return end
	if not camera then return end
	if not attachment or not attachment.Parent then return end
	
	local currentTime = tick()
	local deltaTime = currentTime - lastUpdateTime
	lastUpdateTime = currentTime
	
	local cameraCFrame = camera.CFrame
	local lookVector = cameraCFrame.LookVector
	
	if humanoidRootPart and humanoidRootPart.Parent then
		local velocity = humanoidRootPart.Velocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		
		if horizontalSpeed > 2 then
			bobTime = bobTime + (deltaTime * 8)
			targetOffsetY = math.sin(bobTime) * 0.8
			targetOffsetX = math.cos(bobTime * 0.5) * 0.5
		else
			targetOffsetY = 0
			targetOffsetX = 0
		end
		
		local lerpSpeed = deltaTime * 12
		bobOffsetY = bobOffsetY + (targetOffsetY - bobOffsetY) * lerpSpeed
		bobOffsetX = bobOffsetX + (targetOffsetX - bobOffsetX) * lerpSpeed
	end
	
	local targetLookVector = lookVector
	local lerpSpeed = math.min(1, deltaTime * 8)
	currentLookVector = currentLookVector:Lerp(targetLookVector, lerpSpeed)
	
	local head = player.Character and player.Character:FindFirstChild("Head")
	local headPosition = head and head.Position or (humanoidRootPart.Position + Vector3.new(0, 1.5, 0))
	local rightVector = cameraCFrame.RightVector
	local forwardVector = cameraCFrame.LookVector
	local downVector = -cameraCFrame.UpVector
	
	local baseOffset = (rightVector * 0.8) + (downVector * 0.6) + (forwardVector * 0.3)
	local bobOffset = Vector3.new(0, bobOffsetY, 0) + (rightVector * bobOffsetX)
	local flashlightPosition = headPosition + baseOffset + bobOffset
	
	attachment.WorldCFrame = CFrame.lookAt(flashlightPosition, flashlightPosition + currentLookVector)
end

if player.Character then
	setupFlashlight()
	if camera then
		currentLookVector = camera.CFrame.LookVector
	end
end

player.CharacterAdded:Connect(function()
	setupFlashlight()
	bobTime = 0
	bobOffsetY = 0
	bobOffsetX = 0
	targetOffsetY = 0
	targetOffsetX = 0
	lastUpdateTime = tick()
	if camera then
		currentLookVector = camera.CFrame.LookVector
	else
		currentLookVector = Vector3.new(0, 0, -1)
	end
end)

RunService.RenderStepped:Connect(function()
	if spotlight and spotlight.Parent then
		updateFlashlight()
	end
end)

