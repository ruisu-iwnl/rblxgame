local flickerLight = workspace:FindFirstChild("FlickerLight")
if not flickerLight then return end

local lightPart = flickerLight:FindFirstChild("Light_part")
if not lightPart then return end

local light = lightPart:FindFirstChild("Light")
if not light or not light:IsA("Light") then return end

local originalBrightness = light.Brightness
local originalRange = light.Range

local function flicker()
	while light.Parent do
		local burstCount = math.random(2, 5)
		
		for i = 1, burstCount do
			light.Brightness = math.random(0, originalBrightness * 0.3)
			light.Range = math.random(0, originalRange * 0.4)
			
			task.wait(math.random(5, 20) / 1000)
			
			light.Brightness = originalBrightness
			light.Range = originalRange
			
			task.wait(math.random(10, 50) / 1000)
		end
		
		task.wait(math.random(100, 500) / 1000)
	end
end

flicker()

