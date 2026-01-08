local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CollectibleRemoteEvents = require(ReplicatedStorage.Shared.Modules.CollectibleRemoteEvents)
local KeySystem = require(ReplicatedStorage.Shared.Modules.KeySystem)

local promptGui = Instance.new("ScreenGui")
promptGui.Name = "CollectiblePrompt"
promptGui.ResetOnSpawn = false
promptGui.IgnoreGuiInset = true
promptGui.Parent = playerGui

local promptText = Instance.new("TextLabel")
promptText.Name = "PromptText"
promptText.Size = UDim2.new(0, 0, 0, 0)
promptText.Position = UDim2.new(0.5, 0, 0.8, 0)
promptText.AnchorPoint = Vector2.new(0.5, 0.5)
promptText.BackgroundTransparency = 1
promptText.Text = "Click to Collect"
promptText.TextColor3 = Color3.new(1, 1, 1)
promptText.TextSize = 36
promptText.Font = Enum.Font.GothamBold
promptText.Visible = false
promptText.Parent = promptGui

local collectionGui = Instance.new("ScreenGui")
collectionGui.Name = "CollectionIndicator"
collectionGui.ResetOnSpawn = false
collectionGui.IgnoreGuiInset = true
collectionGui.Parent = playerGui

local collectionContainer = Instance.new("Frame")
collectionContainer.Name = "CollectionContainer"
collectionContainer.Size = UDim2.new(0, 0, 0, 0)
collectionContainer.Position = UDim2.new(0, 10, 0.5, 0)
collectionContainer.AnchorPoint = Vector2.new(0, 0.5)
collectionContainer.BackgroundTransparency = 1
collectionContainer.BorderSizePixel = 0
collectionContainer.Parent = collectionGui

local collectionLayout = Instance.new("UIListLayout")
collectionLayout.FillDirection = Enum.FillDirection.Vertical
collectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
collectionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
collectionLayout.Padding = UDim.new(0, 10)
collectionLayout.SortOrder = Enum.SortOrder.Name
collectionLayout.Parent = collectionContainer

collectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	collectionContainer.Size = UDim2.new(0, collectionLayout.AbsoluteContentSize.X, 0, collectionLayout.AbsoluteContentSize.Y)
end)

local currentItem = nil
local proximityCheck = nil
local canInteract = true
local collectedItems = {}
local usedKeys = {}

local function showPrompt(itemName)
	promptText.Visible = true
	promptText.Text = "Click to Collect"
	promptText.TextColor3 = Color3.new(1, 1, 1)
end

local function hidePrompt()
	promptText.Visible = false
	currentItem = nil
end

local function createItemIcon(itemName, itemKeyId)
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = itemName
	iconFrame.Size = UDim2.new(0, 50, 0, 50)
	iconFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	iconFrame.BackgroundTransparency = 0.3
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = collectionContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = iconFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 1, -10)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = itemName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = iconFrame

	if itemKeyId and usedKeys[itemKeyId] then
		local usedOverlay = Instance.new("Frame")
		usedOverlay.Name = "UsedOverlay"
		usedOverlay.Size = UDim2.new(1, 0, 1, 0)
		usedOverlay.Position = UDim2.new(0, 0, 0, 0)
		usedOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		usedOverlay.BackgroundTransparency = 0.5
		usedOverlay.BorderSizePixel = 0
		usedOverlay.Parent = iconFrame
		
		local usedCorner = Instance.new("UICorner")
		usedCorner.CornerRadius = UDim.new(0.5, 0)
		usedCorner.Parent = usedOverlay
		
		local usedText = Instance.new("TextLabel")
		usedText.Name = "UsedText"
		usedText.Size = UDim2.new(1, 0, 1, 0)
		usedText.Position = UDim2.new(0, 0, 0, 0)
		usedText.BackgroundTransparency = 1
		usedText.Text = "USED"
		usedText.TextColor3 = Color3.new(1, 1, 1)
		usedText.TextSize = 14
		usedText.Font = Enum.Font.GothamBold
		usedText.TextScaled = true
		usedText.Parent = usedOverlay
	end
	
	return iconFrame
end

local function getItemKeyId(itemName)
	local collectionFolder = player:FindFirstChild("CollectedItems")
	if collectionFolder then
		local itemValue = collectionFolder:FindFirstChild(itemName)
		if itemValue and itemValue:IsA("StringValue") then
			local keyIdValue = itemValue:FindFirstChild(KeySystem.KEY_ID_NAME)
			if keyIdValue and keyIdValue:IsA("StringValue") then
				return keyIdValue.Value
			end
		end
	end
	return nil
end

local function updateCollectionGui()
	for _, child in ipairs(collectionContainer:GetChildren()) do
		if child:IsA("Frame") and child ~= collectionContainer then
			child:Destroy()
		end
	end

	for itemName, _ in pairs(collectedItems) do
		local itemKeyId = getItemKeyId(itemName)
		createItemIcon(itemName, itemKeyId)
	end
end

local function addCollectedItem(itemName)
	collectedItems[itemName] = true
	updateCollectionGui()
end

local function checkProximity()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local position = rootPart.Position
	local lookVector = rootPart.CFrame.LookVector
	
	local collectibles = workspace:FindFirstChild("Collectibles")
	if not collectibles then return end
	
	local range = 3
	
	for _, itemPart in ipairs(collectibles:GetChildren()) do
		if itemPart:IsA("BasePart") then
			local distance = (position - itemPart.Position).Magnitude
			
			if distance <= range then
				local toItem = (itemPart.Position - position).Unit
				local facingDot = lookVector:Dot(toItem)
				
				if facingDot > 0.5 then
					if currentItem ~= itemPart then
						currentItem = itemPart
						showPrompt(itemPart.Name)
					end
					return
				else
					if currentItem == itemPart then
						hidePrompt()
					end
				end
			end
		end
	end
	
	if currentItem then
		hidePrompt()
	end
end

local function attemptCollect()
	if not canInteract then return end
	if not currentItem or not promptText.Visible then return end
	
	canInteract = false
	CollectibleRemoteEvents.CollectItem:FireServer(currentItem)
	hidePrompt()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not canInteract then return end
	
	if input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1 then
		attemptCollect()
	end
end)

CollectibleRemoteEvents.ItemCollected.OnClientEvent:Connect(function(itemName)
	addCollectedItem(itemName)
	canInteract = true
end)

CollectibleRemoteEvents.KeyUsed.OnClientEvent:Connect(function(keyId)
	if keyId then
		usedKeys[keyId] = true
		updateCollectionGui()
	end
end)

proximityCheck = RunService.Heartbeat:Connect(checkProximity)

player.CharacterAdded:Connect(function()
	currentItem = nil
	hidePrompt()
	canInteract = true
end)

if UserInputService.TouchEnabled then
	local function setupMobileButton()
		local playerGui = player:WaitForChild("PlayerGui")
		local mobileGui = playerGui:FindFirstChild("MobileControlsGui")
		if mobileGui then
			local interactBtn = mobileGui:FindFirstChild("InteractButton")
			if interactBtn then
				interactBtn.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Touch then
						attemptCollect()
					end
				end)
			end
		else
			task.wait(1)
			setupMobileButton()
		end
	end
	
	task.spawn(setupMobileButton)
end

