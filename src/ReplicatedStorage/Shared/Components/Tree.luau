local RunService = game:GetService("RunService")
local Tree = {}
Tree.Tag = script.Name
Tree.__index = Tree

function Tree.new(instance)
	local self = setmetatable({}, Tree)
	self.instance = instance

	print("Test component created for", instance:GetFullName())

	self:init()
	return self
end

function Tree:init()
	self.instance.Anchored = true
	RunService.Heartbeat:Connect(function(deltaTime: number)
		self.instance.CFrame = self.instance.CFrame * CFrame.Angles(0, math.rad(30) * deltaTime, 0)
	end)
end

function Tree:destroy()
	print("Test component destroyed for", self.instance:GetFullName())
	self.instance:Destroy()
end
return Tree
