-- StarterGui script
-- Runs on the client for GUI initialization
-- Use for ScreenGuis, initial UI setup, etc.

print("StarterGui: Initializing GUI...")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Example: Create a simple GUI
-- local screenGui = Instance.new("ScreenGui")
-- screenGui.Name = "MainGUI"
-- screenGui.Parent = playerGui

print("StarterGui: GUI initialized!")

