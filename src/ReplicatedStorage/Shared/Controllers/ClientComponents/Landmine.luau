local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BasicNetwork = require(ReplicatedStorage.Shared.Utilities.BasicNetwork)
local Trove = require(ReplicatedStorage.Packages.trove)

local Landmine = {}
Landmine.Tag = script.Name
Landmine.__index = Landmine

local LandmineExploded = BasicNetwork.new("LandmineExploded",false,false)
local MineModel = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("MineModel")

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
	self.trove = Trove.new()

	self:init()
	return self
end

function Landmine:init()
	if not self.part then
		warn("Client Landmine: missing part on", self.instance:GetFullName())
		return
	end

	self.visual = self:createVisual()
	self.trove:Add(self.visual)

	self.trove:Add(self.part:GetPropertyChangedSignal("CFrame"):Connect(function()
		self.visual:PivotTo(self.part.CFrame)
	end))

	self.trove:Add(LandmineExploded:Connect(function(explodedInstance, cframe)
		if explodedInstance ~= self.instance then
			return
		end

		self:playExplosionEffect(cframe)
		self:destroy()
	end))
end

function Landmine:createVisual()
	local model = MineModel:Clone()
	model.Name = "LandmineVisual"

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	if model:IsA("BasePart") then
		model.Anchored = true
		model.CanCollide = false
		model.CanTouch = false
		model.CanQuery = false
	end

	model.Parent = workspace
	model:PivotTo(self.part.CFrame)

	return model
end

function Landmine:playExplosionEffect(cframe)
	local blast = Instance.new("Part")
	blast.Name = "LandmineBlast"
	blast.Shape = Enum.PartType.Ball
	blast.Size = Vector3.new(1, 1, 1)
	blast.Anchored = true
	blast.CanCollide = false
	blast.CanTouch = false
	blast.CanQuery = false
	blast.Material = Enum.Material.Neon
	blast.Color = Color3.fromRGB(255, 170, 0)
	blast.Transparency = 0.15
	blast.CFrame = cframe
	blast.Parent = workspace

	task.spawn(function()
		local growthSteps = 8
		for step = 1, growthSteps do
			if not blast.Parent then
				return
			end

			local alpha = step / growthSteps
			blast.Size = Vector3.new(1, 1, 1):Lerp(Vector3.new(12, 12, 12), alpha)
			blast.Transparency = 0.15 + (alpha * 0.8)
			task.wait(0.03)
		end
	end)

	Debris:AddItem(blast, 0.35)
end

function Landmine:destroy()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

return Landmine
