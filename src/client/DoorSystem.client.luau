local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DoorRemoteEvents = require(ReplicatedStorage.Shared.Modules.DoorRemoteEvents)
local LOCKED_DOORS = require(ReplicatedStorage.Shared.Modules.LockedDoors)
local KeySystem = require(ReplicatedStorage.Shared.Modules.KeySystem)


local GuiService = game:GetService("GuiService")

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
		local isLocked = LOCKED_DOORS[currentDoor.Name] == true
		if isLocked then
			promptText.Text = "Door Locked"
			promptText.TextColor3 = Color3.new(1, 0.3, 0.3)
		else
			promptText.Text = "Click to Open Door"
			promptText.TextColor3 = Color3.new(1, 1, 1)
		end
	end
end

local function hidePrompt()
	promptText.Visible = false
	currentDoor = nil
end

local function fadeToBlack()
	blackScreen.BackgroundTransparency = 0
end

local function fadeFromBlack()
	local tween = TweenService:Create(
		blackScreen,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 1}
	)
	tween:Play()
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
				
				if facingDot > 0.5 then
					if currentDoor ~= doorPart then
						currentDoor = doorPart

						local isLocked = false
						
						local unlockedValue = doorPart:FindFirstChild("Unlocked")
						if unlockedValue and unlockedValue:IsA("BoolValue") and unlockedValue.Value == true then
							isLocked = false
						else
							local doorKeyId = KeySystem.getKeyId(doorPart)
							
							if doorKeyId then
								isLocked = not KeySystem.hasKeyWithId(player, doorKeyId)
							else
								isLocked = LOCKED_DOORS[doorPart.Name] == true
							end
						end
						
						if isLocked then
							promptText.Text = "Door Locked"
							promptText.TextColor3 = Color3.new(1, 0.3, 0.3)
						else
							promptText.Text = "Click to Open Door"
							promptText.TextColor3 = Color3.new(1, 1, 1)
						end
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
	
	if input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if currentDoor and promptText.Visible then
			local isLocked = false
			
			local unlockedValue = currentDoor:FindFirstChild("Unlocked")
			if unlockedValue and unlockedValue:IsA("BoolValue") and unlockedValue.Value == true then
				isLocked = false
			else
				local doorKeyId = KeySystem.getKeyId(currentDoor)
				
				if doorKeyId then
					isLocked = not KeySystem.hasKeyWithId(player, doorKeyId)
				else
					isLocked = LOCKED_DOORS[currentDoor.Name] == true
				end
			end
			
			if isLocked then
				task.spawn(showLockedMessage)
				DoorRemoteEvents.DoorOpen:FireServer(currentDoor)
			else
				canInteract = false
				fadeToBlack()
				DoorRemoteEvents.DoorOpen:FireServer(currentDoor)
			end
		end
	end
end)

DoorRemoteEvents.DoorProximity.OnClientEvent:Connect(function()
	fadeFromBlack()
	canInteract = true
end)

DoorRemoteEvents.DoorUnlocked.OnClientEvent:Connect(function(doorPath)
	local pathParts = string.split(doorPath, ".")
	local current = game
	for i = 2, #pathParts do
		current = current:FindFirstChild(pathParts[i])
		if not current then return end
	end
	if current and current:IsA("BasePart") then
		local unlockedValue = current:FindFirstChild("Unlocked")
		if not unlockedValue then
			unlockedValue = Instance.new("BoolValue")
			unlockedValue.Name = "Unlocked"
			unlockedValue.Parent = current
		end
		unlockedValue.Value = true
	end
end)

proximityCheck = RunService.Heartbeat:Connect(checkProximity)

player.CharacterAdded:Connect(function()
	currentDoor = nil
	hidePrompt()
	blackScreen.BackgroundTransparency = 1
	canInteract = true
end)

if UserInputService.TouchEnabled then
	local playerGui = player:WaitForChild("PlayerGui")
	local mobileGui = playerGui:FindFirstChild("MobileControlsGui") or Instance.new("ScreenGui")
	if not mobileGui.Parent then
		mobileGui.Name = "MobileControlsGui"
		mobileGui.ResetOnSpawn = false
		mobileGui.IgnoreGuiInset = true
		mobileGui.Parent = playerGui
	end
	local interactBtn = Instance.new("ImageButton")
	interactBtn.Name = "InteractButton"
	interactBtn.Size = UDim2.new(0, 48, 0, 48)
	interactBtn.Position = UDim2.new(1, -56, 0.72, 0)
	interactBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	interactBtn.BackgroundColor3 = Color3.new(0,0,0)
	interactBtn.BackgroundTransparency = 0.3
	interactBtn.Parent = mobileGui

	local circle = Instance.new("UICorner")
	circle.CornerRadius = UDim.new(0.5,0)
	circle.Parent = interactBtn

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Text = "INTERACT"
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1,0,1,0)
	label.Position = UDim2.new(0,0,0,0)
	label.Parent = interactBtn

	interactBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			if not canInteract then return end
			if currentDoor and promptText.Visible then
				local isLocked = false
				
				local unlockedValue = currentDoor:FindFirstChild("Unlocked")
				if unlockedValue and unlockedValue:IsA("BoolValue") and unlockedValue.Value == true then
					isLocked = false
				else
					local doorKeyId = KeySystem.getKeyId(currentDoor)
					
					if doorKeyId then
						isLocked = not KeySystem.hasKeyWithId(player, doorKeyId)
					else
						isLocked = LOCKED_DOORS[currentDoor.Name] == true
					end
				end
				
				if isLocked then
					task.spawn(showLockedMessage)
					DoorRemoteEvents.DoorOpen:FireServer(currentDoor)
				else
					canInteract = false
					fadeToBlack()
					DoorRemoteEvents.DoorOpen:FireServer(currentDoor)
				end
			end
		end
	end)
end

