local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "LoadingScreen"
loadingGui.ResetOnSpawn = false
loadingGui.IgnoreGuiInset = true
loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loadingGui.Parent = playerGui

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundColor3 = Color3.new(0, 0, 0)
background.BackgroundTransparency = 0
background.BorderSizePixel = 0
background.Parent = loadingGui

local loadingText = Instance.new("TextLabel")
loadingText.Name = "LoadingText"
loadingText.Size = UDim2.new(0, 200, 0, 30)
loadingText.Position = UDim2.new(0.5, 0, 0.5, -40)
loadingText.AnchorPoint = Vector2.new(0.5, 0.5)
loadingText.BackgroundTransparency = 1
loadingText.Text = "Loading..."
loadingText.TextColor3 = Color3.new(1, 1, 1)
loadingText.TextSize = 24
loadingText.Font = Enum.Font.GothamBold
loadingText.Parent = loadingGui

local progressBarContainer = Instance.new("Frame")
progressBarContainer.Name = "ProgressBarContainer"
progressBarContainer.Size = UDim2.new(0, 400, 0, 20)
progressBarContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
progressBarContainer.AnchorPoint = Vector2.new(0.5, 0.5)
progressBarContainer.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
progressBarContainer.BackgroundTransparency = 0
progressBarContainer.BorderSizePixel = 3
progressBarContainer.BorderColor3 = Color3.new(1, 1, 1)
progressBarContainer.Parent = loadingGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 8)
containerCorner.Parent = progressBarContainer

local progressBarFill = Instance.new("Frame")
progressBarFill.Name = "ProgressBarFill"
progressBarFill.Size = UDim2.new(0, 0, 1, -6)
progressBarFill.Position = UDim2.new(0, 3, 0, 3)
progressBarFill.AnchorPoint = Vector2.new(0, 0)
progressBarFill.BackgroundColor3 = Color3.new(1, 1, 1)
progressBarFill.BackgroundTransparency = 0
progressBarFill.BorderSizePixel = 0
progressBarFill.Parent = progressBarContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = progressBarFill

local loadedItems = {}
local humanoid = nil
local originalWalkSpeed = nil
local movementDisabled = false
local totalLoadingSteps = 0
local currentStep = 0
local currentProgress = 0
local targetProgress = 0

local function updateProgressBar(progress)
	progress = math.clamp(progress, 0, 1)
	targetProgress = progress
end

RunService.RenderStepped:Connect(function(dt)
	if targetProgress > currentProgress then
		currentProgress = math.min(targetProgress, currentProgress + (dt * 2))
		local containerWidth = progressBarContainer.AbsoluteSize.X - 6
		local targetWidth = containerWidth * currentProgress
		progressBarFill.Size = UDim2.new(0, targetWidth, 1, -6)
	end
end)

local function disableMovement()
	if not player.Character then return end
	humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid and not movementDisabled then
		originalWalkSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
		humanoid.PlatformStand = true
		movementDisabled = true
	end
end

local function enableMovement()
	if humanoid and movementDisabled then
		if originalWalkSpeed then
			humanoid.WalkSpeed = originalWalkSpeed
		else
			humanoid.WalkSpeed = 8
		end
		humanoid.PlatformStand = false
		movementDisabled = false
	end
end

local function waitForRendering(frames)
	frames = frames or 60
	local framesPassed = 0
	local connection
	connection = RunService.RenderStepped:Connect(function()
		framesPassed = framesPassed + 1
		if framesPassed >= frames then
			connection:Disconnect()
		end
	end)
	
	while framesPassed < frames do
		RunService.Heartbeat:Wait()
	end
end

local function checkFlashlightReady()
	if not player.Character then return false end
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	local attachment = rootPart:FindFirstChild("FlashlightAttachment")
	if not attachment then return false end
	local flashlight = attachment:FindFirstChild("Flashlight")
	if not flashlight then return false end
	
	if flashlight:IsA("SpotLight") then
		return flashlight.Enabled == true and flashlight.Brightness > 0
	end
	return false
end

local loadingItems = {
	{name = "Sprint Module", check = function()
		local success, module = pcall(function()
			return ReplicatedStorage:FindFirstChild("Shared") and 
			       ReplicatedStorage.Shared:FindFirstChild("Modules") and
			       ReplicatedStorage.Shared.Modules:FindFirstChild("SprintSystem")
		end)
		return success and module ~= nil
	end},
	{name = "Door Module", check = function()
		local success, module = pcall(function()
			return ReplicatedStorage:FindFirstChild("Shared") and 
			       ReplicatedStorage.Shared:FindFirstChild("Modules") and
			       ReplicatedStorage.Shared.Modules:FindFirstChild("DoorRemoteEvents")
		end)
		return success and module ~= nil
	end},
	{name = "Character", check = function()
		return player.Character ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil
	end},
	{name = "Flashlight", check = function()
		return checkFlashlightReady()
	end},
	{name = "Shadows", check = function()
		return Lighting.GlobalShadows == true
	end},
	{name = "Camera", check = function()
		local camera = workspace.CurrentCamera
		if not camera then return false end
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and camera.CameraSubject ~= humanoid then
				return false
			end
		end
		return true
	end}
}

local function waitForItem(item, timeout)
	timeout = timeout or 15
	local startTime = tick()
	
	while not item.check() do
		if tick() - startTime > timeout then
			return false
		end
		RunService.Heartbeat:Wait()
	end
	
	return true
end

local function fadeOut()
	local tween = TweenService:Create(
		background,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 1}
	)
	local textTween = TweenService:Create(
		loadingText,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{TextTransparency = 1}
	)
	local barTween = TweenService:Create(
		progressBarContainer,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 1, BorderColor3 = Color3.new(0, 0, 0)}
	)
	local fillTween = TweenService:Create(
		progressBarFill,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 1}
	)
	
	tween:Play()
	textTween:Play()
	barTween:Play()
	fillTween:Play()
	
	tween.Completed:Wait()
	loadingGui:Destroy()
end

local function loadAll()
	task.wait(0.5)
	disableMovement()
	
	totalLoadingSteps = #loadingItems + 4
	currentStep = 0
	currentProgress = 0
	targetProgress = 0
	progressBarFill.Size = UDim2.new(0, 0, 1, -6)
	
	for i, item in ipairs(loadingItems) do
		loadingText.Text = "Loading... " .. item.name
		local loaded = waitForItem(item, 20)
		if loaded then
			table.insert(loadedItems, item.name)
		end
		currentStep = i
		updateProgressBar(currentStep / totalLoadingSteps)
		if player.Character and not movementDisabled then
			disableMovement()
		end
	end
	
	if player.Character then
		local startTime = tick()
		
		loadingText.Text = "Loading... Rendering Shadows & Shaders"
		currentStep = currentStep + 1
		updateProgressBar(currentStep / totalLoadingSteps)
		
		local minWaitTime = 20
		local elapsedTime = 0
		
		while elapsedTime < minWaitTime do
			task.wait(0.1)
			elapsedTime = tick() - startTime
			local progress = currentStep / totalLoadingSteps + (elapsedTime / minWaitTime) * (1 / totalLoadingSteps)
			updateProgressBar(math.min(progress, (currentStep + 1) / totalLoadingSteps))
		end
		
		currentStep = currentStep + 1
		updateProgressBar(currentStep / totalLoadingSteps)
		
		loadingText.Text = "Loading... Finalizing Flashlight"
		local flashlightReady = false
		local attempts = 0
		while not flashlightReady and attempts < 50 do
			flashlightReady = checkFlashlightReady()
			if not flashlightReady then
				task.wait(0.5)
				attempts = attempts + 1
			end
		end
		
		currentStep = currentStep + 1
		updateProgressBar(currentStep / totalLoadingSteps)
		
		if not flashlightReady then
			loadingText.Text = "Loading... Waiting for Graphics"
			task.wait(5)
		end
		
		currentStep = currentStep + 1
		updateProgressBar(currentStep / totalLoadingSteps)
		
		loadingText.Text = "Loading... Finalizing"
		task.wait(2)
	end
	
	updateProgressBar(1)
	task.wait(0.5)
	loadingText.Text = "Loading... Complete!"
	task.wait(0.5)
	enableMovement()
	fadeOut()
end

player.CharacterAdded:Connect(function()
	if movementDisabled then
		task.wait(0.1)
		disableMovement()
	end
end)

task.spawn(loadAll)

