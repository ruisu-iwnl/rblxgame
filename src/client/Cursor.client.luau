local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local cursorGui = Instance.new("ScreenGui")
cursorGui.Name = "CustomCursor"
cursorGui.ResetOnSpawn = false
cursorGui.DisplayOrder = 1000
cursorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
cursorGui.IgnoreGuiInset = true
cursorGui.Parent = playerGui

local cursorDot = Instance.new("Frame")
cursorDot.Name = "CursorDot"
cursorDot.Size = UDim2.new(0, 4, 0, 4)
cursorDot.Position = UDim2.new(0.5, 0, 0.5, 0)
cursorDot.AnchorPoint = Vector2.new(0.5, 0.5)
cursorDot.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
cursorDot.BorderSizePixel = 0
cursorDot.ZIndex = 1000
cursorDot.Parent = cursorGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = cursorDot

UserInputService.MouseIconEnabled = false

RunService.RenderStepped:Connect(function()
	local mouseLocation = UserInputService:GetMouseLocation()
	cursorDot.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y)
end)

player.CharacterAdded:Connect(function()
	UserInputService.MouseIconEnabled = false
end)

