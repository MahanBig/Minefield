local Tree = {}
Tree.Tag = "Tree"
Tree.__index = Tree

function Tree.new(instance)
	local self = setmetatable({}, Tree)
	self.instance = instance

	print("Test component created for", instance:GetFullName())

	self:init()
	return self
end

function Tree:init()
	self.instance.Touched:Connect(function(hit)
		print("Touched by", hit:GetFullName())
	end)
end

function Tree:destroy()
	print("Test component destroyed for", self.instance:GetFullName())
	self.instance:Destroy()
end
return Tree
