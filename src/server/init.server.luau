print("Hello world, from server!")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if sharedFolder then
	local modulesFolder = sharedFolder:WaitForChild("Modules", 10)
	if modulesFolder then
		local exampleModule = modulesFolder:FindFirstChild("Example")
		if exampleModule then
			local Example = require(exampleModule)
		end
	end
end