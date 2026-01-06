local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SprintSystem = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("SprintSystem"))

local player = Players.LocalPlayer
local character = nil
local humanoid = nil

local SprintEvent = ReplicatedStorage:WaitForChild(SprintSystem.REMOTE_EVENT_NAME)

local isSprinting = false
local stamina = 6
local maxStamina = 6
local staminaDrain = 1
local staminaRegen = 1.2
local staminaRegenDelay = 0.5
local canSprint = true
local timeSinceLastSprint = 0

local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")

local sprintGui = Instance.new("ScreenGui")
sprintGui.Name = "SprintBarGui"
sprintGui.ResetOnSpawn = false
sprintGui.IgnoreGuiInset = true
sprintGui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Name = "SprintBar"
bar.Size = UDim2.new(0, 120, 0, 12)
bar.Position = UDim2.new(0.5, -60, 1, -42)
bar.AnchorPoint = Vector2.new(0, 0.5)
bar.BackgroundColor3 = Color3.new(0,0,0)
bar.BackgroundTransparency = 0.5
bar.BorderSizePixel = 0
bar.Visible = false
bar.Parent = sprintGui

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.new(0.95,0,0.6,0)
fill.Position = UDim2.new(0.025,0,0.2,0)
fill.BackgroundColor3 = Color3.new(1,1,1)
fill.BackgroundTransparency = 0
fill.BorderSizePixel = 0
fill.ClipsDescendants = true
fill.Parent = bar

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1,8)
corner.Parent = bar
local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(1,8)
corner2.Parent = fill

local barTween = nil
local function showBar()
	bar.Visible = true
	if barTween then barTween:Cancel() end
	bar.BackgroundTransparency = 0.5
	fill.BackgroundTransparency = 0
	barTween = TweenService:Create(bar,TweenInfo.new(0.2),{BackgroundTransparency=0.15})
	barTween:Play()
	TweenService:Create(fill,TweenInfo.new(0.2),{BackgroundTransparency=0}):Play()
end

local function hideBar()
	if barTween then barTween:Cancel() end
	barTween = TweenService:Create(bar,TweenInfo.new(0.25),{BackgroundTransparency=1})
	barTween:Play()
	TweenService:Create(fill,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
	barTween.Completed:Once(function()
		bar.Visible = false
	end)
end

local lockIcon = nil
local sprintBtn = nil

local function updateLockIcon()
	if lockIcon then
		if isSprinting and canSprint then
			lockIcon.Text = "🔓"
			lockIcon.TextColor3 = Color3.new(0.2, 1, 0.2)
		else
			lockIcon.Text = "🔒"
			lockIcon.TextColor3 = Color3.new(1, 1, 1)
		end
	end
	
	if sprintBtn then
		if isSprinting and canSprint then
			sprintBtn.BackgroundTransparency = 0.1
		else
			sprintBtn.BackgroundTransparency = 0.3
		end
	end
end

function setSprinting(enable)
	enable = enable and canSprint
	if isSprinting ~= enable then
		isSprinting = enable
		if not isSprinting then
			timeSinceLastSprint = 0
		end
		SprintEvent:FireServer(isSprinting)
		if isSprinting then
			showBar()
		elseif stamina < maxStamina then
			showBar()
		else
			hideBar()
		end
		updateLockIcon()
	end
end

local function resetStamina()
	stamina = maxStamina
	canSprint = true
	isSprinting = false
	timeSinceLastSprint = 0
	hideBar()
	updateLockIcon()
end

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	resetStamina()
	setSprinting(false)
end)

player.CharacterRemoving:Connect(function()
	character = nil
	humanoid = nil
	resetStamina()
end)

if not UserInputService.TouchEnabled then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not humanoid then return end
		if input.KeyCode == SprintSystem.SPRINT_KEY then
			setSprinting(true)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed or not humanoid then return end
		if input.KeyCode == SprintSystem.SPRINT_KEY then
			setSprinting(false)
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	if isSprinting and not canSprint then
		setSprinting(false)
	end
	
	if isSprinting and canSprint then
		local isMoving = false
		if humanoid and character and character:FindFirstChild("HumanoidRootPart") then
			local moveDirection = humanoid.MoveDirection
			local horizontalSpeed = Vector3.new(moveDirection.X, 0, moveDirection.Z).Magnitude
			isMoving = horizontalSpeed > 0.1
		end
		
		if isMoving then
			stamina = math.max(0, stamina - staminaDrain * dt)
			if stamina == 0 then
				canSprint = false
				setSprinting(false)
			end
		end
		timeSinceLastSprint = 0
	else
		if not isSprinting or not canSprint then
			timeSinceLastSprint = timeSinceLastSprint + dt
		end
		
		if timeSinceLastSprint >= staminaRegenDelay then
			local prevStamina = stamina
			stamina = math.min(maxStamina, stamina + staminaRegen * dt)
			if stamina > 0.2 then
				canSprint = true
			end
			if not isSprinting and prevStamina < maxStamina and stamina == maxStamina then
				hideBar()
			end
		end
	end
	
	local targetSize = 0.95 * (stamina / maxStamina)
	local currentSize = fill.Size.X.Scale
	local sizeDiff = math.abs(targetSize - currentSize)
	
	if sizeDiff > 0.01 then
		local newSize = currentSize + (targetSize - currentSize) * (dt * 8)
		fill.Size = UDim2.new(newSize, 0, 0.6, 0)
	else
		fill.Size = UDim2.new(targetSize, 0, 0.6, 0)
	end
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
	sprintBtn = Instance.new("ImageButton")
	sprintBtn.Name = "SprintButton"
	sprintBtn.Size = UDim2.new(0, 48, 0, 48)
	sprintBtn.Position = UDim2.new(1, -56, 0.88, 0)
	sprintBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	sprintBtn.BackgroundColor3 = Color3.new(0,0,0)
	sprintBtn.BackgroundTransparency = 0.3
	sprintBtn.Image = ""
	sprintBtn.Parent = mobileGui
	local circle = Instance.new("UICorner")
	circle.CornerRadius = UDim.new(0.5,0)
	circle.Parent = sprintBtn
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Text = "SPRINT"
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1,0,0.6,0)
	label.Position = UDim2.new(0,0,0,0)
	label.Parent = sprintBtn
	lockIcon = Instance.new("TextLabel")
	lockIcon.Name = "LockIcon"
	lockIcon.Size = UDim2.new(0, 20, 0, 20)
	lockIcon.Position = UDim2.new(0.5, 0, 0.7, 0)
	lockIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Text = "🔒"
	lockIcon.TextColor3 = Color3.new(1, 1, 1)
	lockIcon.TextSize = 16
	lockIcon.Font = Enum.Font.Gotham
	lockIcon.Parent = sprintBtn
	updateLockIcon()
	sprintBtn.Activated:Connect(function()
		if humanoid then
			setSprinting(not isSprinting)
		end
	end)
end

