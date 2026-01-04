local AtomicBinding = {}
AtomicBinding.__index = AtomicBinding

function AtomicBinding.new(requirements, callback)
	local self = setmetatable({}, AtomicBinding)
	self.requirements = requirements
	self.callback = callback
	self.bound = {}
	return self
end

function AtomicBinding:bindRoot(root)
	if self.bound[root] then
		return
	end
	
	local instances = {}
	local allFound = true
	
	for key, name in pairs(self.requirements) do
		local instance = root:WaitForChild(name, 10)
		if instance then
			instances[key] = instance
		else
			allFound = false
			break
		end
	end
	
	if allFound then
		self.bound[root] = self.callback(instances)
	end
end

function AtomicBinding:unbindRoot(root)
	if self.bound[root] then
		if type(self.bound[root]) == "function" then
			self.bound[root]()
		end
		self.bound[root] = nil
	end
end

return AtomicBinding

