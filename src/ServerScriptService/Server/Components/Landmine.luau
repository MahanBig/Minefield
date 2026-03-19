local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

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
	self.armed = false
	self.detonated = false
	self.part = getBasePart(instance)

	self:init()
	return self
end

function Landmine:init()
	if not self.part then
		warn("Landmine: missing part on", self.instance:GetFullName())
		return
	end

	self.part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self.lastHumanoid = humanoid
			self:arm()
		end
	end)
end

function Landmine:arm()
	if self.armed or self.detonated then
		return
	end
	self.armed = true
	self.part.BrickColor = BrickColor.new("Really red")
	self.part.Material = Enum.Material.Neon

	task.delay(0.15, function()
		self:detonate()
	end)
end

function Landmine:detonate()
	if self.detonated then
		return
	end
	self.detonated = true

	local humanoid = self.lastHumanoid
	if humanoid and humanoid.Health > 0 then
		local damage = math.max(1, math.floor(humanoid.Health * 0.5))
		humanoid:TakeDamage(damage)

		local rootPart = humanoid.RootPart
		if rootPart then
			rootPart.Velocity = (rootPart.CFrame.LookVector * 70) + Vector3.new(0, 90, 0)
		end

		humanoid.PlatformStand = true
		task.delay(1.5, function()
			if humanoid and humanoid.Parent and humanoid.Health > 0 then
				humanoid.PlatformStand = false
			end
		end)
	end

	self.part.Transparency = 0.6
	self.part.CanCollide = false
	self.part.BrickColor = BrickColor.new("Really black")

	CollectionService:RemoveTag(self.instance, Landmine.Tag)

	Debris:AddItem(self.part, 2)
	if self.instance ~= self.part and self.instance.Parent then
		Debris:AddItem(self.instance, 2)
	end

	self:destroy()
end

function Landmine:destroy()
	print("Landmine component destroyed for", self.instance:GetFullName())
	if self.instance and self.instance.Parent and not self.detonated then
		self.instance:Destroy()
	end
end

return Landmine
