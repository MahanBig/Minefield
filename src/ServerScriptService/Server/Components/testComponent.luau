local testComponent = {}
testComponent.Tag = "Test"
testComponent.__index = testComponent

function testComponent.new(instance)
	local self = setmetatable({}, testComponent)
	self.instance = instance

	print("Test component created for", instance:GetFullName())

	return self
end

function testComponent:destroy()
	print("Test component destroyed for", self.instance:GetFullName())
end
return testComponent
