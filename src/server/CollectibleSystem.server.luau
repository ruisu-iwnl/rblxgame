local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CollectibleRemoteEvents = require(ReplicatedStorage.Shared.Modules.CollectibleRemoteEvents)

local function addBillboardGui(itemPart)
	if itemPart:FindFirstChild("ItemLabel") then
		return
	end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ItemLabel"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 0.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 15
	billboard.Parent = itemPart
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = itemPart.Name
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextSize = 10
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = false
	textLabel.Parent = billboard
	
	itemPart:GetPropertyChangedSignal("Name"):Connect(function()
		textLabel.Text = itemPart.Name
	end)
end

local function setupCollectibles()
	local collectibles = workspace:FindFirstChild("Collectibles")
	if not collectibles then
		return
	end
	
	for _, item in ipairs(collectibles:GetChildren()) do
		if item:IsA("BasePart") then
			addBillboardGui(item)
		end
	end
	
	collectibles.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			addBillboardGui(child)
		end
	end)
end

setupCollectibles()
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Collectibles" then
		setupCollectibles()
	end
end)

local function getOrCreateCollectionFolder(player)
	local collectionFolder = player:FindFirstChild("CollectedItems")
	if not collectionFolder then
		collectionFolder = Instance.new("Folder")
		collectionFolder.Name = "CollectedItems"
		collectionFolder.Parent = player
	end
	return collectionFolder
end

local KeySystem = require(ReplicatedStorage.Shared.Modules.KeySystem)

local function hasCollectedItem(player, itemName)
	local collectionFolder = getOrCreateCollectionFolder(player)
	return collectionFolder:FindFirstChild(itemName) ~= nil
end

local function markItemAsCollected(player, itemPart)
	local itemName = itemPart.Name
	
	if hasCollectedItem(player, itemName) then
		return false
	end
	
	local collectionFolder = getOrCreateCollectionFolder(player)
	local itemValue = Instance.new("StringValue")
	itemValue.Name = itemName
	itemValue.Value = itemName
	itemValue.Parent = collectionFolder
	
	local sourceKeyId = itemPart:FindFirstChild(KeySystem.KEY_ID_NAME)
	if sourceKeyId and sourceKeyId:IsA("StringValue") then
		local keyIdValue = Instance.new("StringValue")
		keyIdValue.Name = KeySystem.KEY_ID_NAME
		keyIdValue.Value = sourceKeyId.Value
		keyIdValue.Parent = itemValue
	end
	
	return true
end

local function syncCollectedItemsToClient(player)
	local collectionFolder = getOrCreateCollectionFolder(player)
	for _, itemValue in ipairs(collectionFolder:GetChildren()) do
		if itemValue:IsA("StringValue") then
			CollectibleRemoteEvents.ItemCollected:FireClient(player, itemValue.Name)
		end
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		syncCollectedItemsToClient(player)
	end)
	
	if player.Character then
		task.wait(0.5)
		syncCollectedItemsToClient(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

CollectibleRemoteEvents.CollectItem.OnServerEvent:Connect(function(player, itemPart)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	if not itemPart or not itemPart.Parent then
		return
	end
	
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local collectibles = workspace:FindFirstChild("Collectibles")
	if not collectibles then return end
	
	if itemPart.Parent ~= collectibles then
		return
	end
	
	local distance = (rootPart.Position - itemPart.Position).Magnitude
	if distance > 5 then
		return
	end
	
	if hasCollectedItem(player, itemPart.Name) then
		return
	end
	
	if markItemAsCollected(player, itemPart) then
		itemPart:Destroy()
		CollectibleRemoteEvents.ItemCollected:FireClient(player, itemPart.Name)
	end
end)

