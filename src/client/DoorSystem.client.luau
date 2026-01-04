local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DoorRemoteEvents = require(ReplicatedStorage.Shared.Modules.DoorRemoteEvents)

local GuiService = game:GetService("GuiService")

local LOCKED_DOORS = {
	["Door1"] = true,
	["Door2"] = false,
}

local promptGui = Instance.new("ScreenGui")
promptGui.Name = "DoorPrompt"
promptGui.ResetOnSpawn = false
promptGui.IgnoreGuiInset = true
promptGui.Parent = playerGui

local promptText = Instance.new("TextLabel")
promptText.Name = "PromptText"
promptText.Size = UDim2.new(0, 0, 0, 0)
promptText.Position = UDim2.new(0.5, 0, 0.8, 0)
promptText.AnchorPoint = Vector2.new(0.5, 0.5)
promptText.BackgroundTransparency = 1
promptText.Text = "Click to Open Door"
promptText.TextColor3 = Color3.new(1, 1, 1)
promptText.TextSize = 36
promptText.Font = Enum.Font.GothamBold
promptText.Visible = false
promptText.Parent = promptGui

local blackScreen = Instance.new("Frame")
blackScreen.Name = "BlackScreen"
blackScreen.Size = UDim2.new(1, 0, 1, 0)
blackScreen.Position = UDim2.new(0, 0, 0, 0)
blackScreen.AnchorPoint = Vector2.new(0, 0)
blackScreen.BackgroundColor3 = Color3.new(0, 0, 0)
blackScreen.BackgroundTransparency = 1
blackScreen.BorderSizePixel = 0
blackScreen.ZIndex = 999
blackScreen.Parent = promptGui

local currentDoor = nil
local proximityCheck = nil
local canInteract = true

local function showPrompt()
	promptText.Visible = true
	promptText.Text = "Click to Open Door"
	promptText.TextColor3 = Color3.new(1, 1, 1)
end

local function showLockedMessage()
	promptText.Text = "Door won't budge"
	promptText.TextColor3 = Color3.new(1, 0.3, 0.3)
	
	task.wait(2)
	
	if promptText.Visible and currentDoor then
		promptText.Text = "Click to Open Door"
		promptText.TextColor3 = Color3.new(1, 1, 1)
	end
end

local function hidePrompt()
	promptText.Visible = false
	currentDoor = nil
end

local function fadeToBlack()
	local tween = TweenService:Create(
		blackScreen,
		TweenInfo.new(0.05, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 0}
	)
	tween:Play()
	return tween.Completed
end

local function fadeFromBlack()
	local tween = TweenService:Create(
		blackScreen,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 1}
	)
	tween:Play()
end

local function isPathClear(playerPosition, doorPart)
	local rayOrigin = playerPosition
	local rayDirection = doorPart.Position - playerPosition
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {player.Character, doorPart}
	
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		local hitPart = raycastResult.Instance
		if hitPart ~= doorPart and not hitPart:IsDescendantOf(doorPart.Parent) then
			return false
		end
	end
	
	return true
end

local function checkProximity()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local position = rootPart.Position
	local lookVector = rootPart.CFrame.LookVector
	
	local doors = workspace:FindFirstChild("Doors")
	if not doors then return end
	
	local range = 3
	
	for _, doorPart in ipairs(doors:GetChildren()) do
		if doorPart:IsA("BasePart") then
			local distance = (position - doorPart.Position).Magnitude
			
			if distance <= range then
				local toDoor = (doorPart.Position - position).Unit
				local facingDot = lookVector:Dot(toDoor)
				
				if facingDot > 0.5 and isPathClear(position, doorPart) then
					if currentDoor ~= doorPart then
						currentDoor = doorPart
						showPrompt()
					end
					return
				else
					if currentDoor == doorPart then
						hidePrompt()
					end
				end
			end
		end
	end
	
	if currentDoor then
		hidePrompt()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not canInteract then return end
	
	if input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if currentDoor and promptText.Visible then
			local isLocked = LOCKED_DOORS[currentDoor.Name] == true
			
			if isLocked then
				task.spawn(showLockedMessage)
				DoorRemoteEvents.DoorOpen:FireServer(currentDoor)
			else
				canInteract = false
				fadeToBlack():Wait()
				DoorRemoteEvents.DoorOpen:FireServer(currentDoor)
				
				task.wait(1)
				canInteract = true
			end
		end
	end
end)

DoorRemoteEvents.DoorProximity.OnClientEvent:Connect(function()
	fadeFromBlack()
end)

proximityCheck = RunService.Heartbeat:Connect(checkProximity)

player.CharacterAdded:Connect(function()
	currentDoor = nil
	hidePrompt()
	blackScreen.BackgroundTransparency = 1
	canInteract = true
end)

