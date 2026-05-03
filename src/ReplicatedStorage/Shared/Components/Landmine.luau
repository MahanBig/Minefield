local Landmine = {}
Landmine.Tag = script.Name
Landmine.__index = Landmine

local function getBasePart(instance)
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

function Landmine.new(instance)
	local self = setmetatable({}, Landmine)
	self.instance = instance
	self.part = getBasePart(instance)
	self:init()
	return self
end

function Landmine:init()
	if not self.part then
		warn("Landmine: missing part on", self.instance:GetFullName())
		return
	end
	self:beautify()
end

function Landmine:beautify()
	if self.part:FindFirstChild("MineVisual") then
		return
	end

	local visual = Instance.new("Model")
	visual.Name = "MineVisual"

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(1.5, 0.22, 1.5)
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Metal
	base.Color = Color3.fromRGB(56, 62, 56)
	base.CFrame = self.part.CFrame
	base.Parent = visual

	local top = Instance.new("Part")
	top.Name = "Top"
	top.Shape = Enum.PartType.Cylinder
	top.Size = Vector3.new(0.45, 1.05, 1.05)
	top.Anchored = true
	top.CanCollide = false
	top.Material = Enum.Material.Metal
	top.Color = Color3.fromRGB(82, 96, 76)
	top.CFrame = self.part.CFrame * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
	top.Parent = visual

	for index = 1, 3 do
		local peg = Instance.new("Part")
		peg.Name = "Peg" .. index
		peg.Shape = Enum.PartType.Cylinder
		peg.Size = Vector3.new(0.18, 0.35, 0.35)
		peg.Anchored = true
		peg.CanCollide = false
		peg.Material = Enum.Material.Metal
		peg.Color = Color3.fromRGB(36, 41, 36)
		local angle = math.rad((index - 1) * 120)
		local offset = Vector3.new(math.cos(angle) * 0.38, 0.28, math.sin(angle) * 0.38)
		peg.CFrame = self.part.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
		peg.Parent = visual
	end

	visual.Parent = self.part
end

function Landmine:destroy()
	print("Landmine component destroyed for", self.instance:GetFullName())
end

return Landmine
