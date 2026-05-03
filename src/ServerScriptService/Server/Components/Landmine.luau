local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")

local RagdollService = require(ServerScriptService.Server.Services.RagdollService)

local Landmine = {}
Landmine.Tag = script.Name
Landmine.__index = Landmine

local ARM_TIME = 0.12
local DAMAGE = 45
local HORIZONTAL_FORCE = 85
local UPWARD_FORCE = 72
local RAGDOLL_DURATION = 2.75

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
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self:arm(humanoid)
		end
	end)
end

function Landmine:arm(humanoid)
	if self.armed or self.detonated then
		return
	end
	self.armed = true
	self.lastHumanoid = humanoid
	self.part.BrickColor = BrickColor.new("Really red")
	self.part.Material = Enum.Material.Neon

	task.delay(ARM_TIME, function()
		self:detonate()
	end)
end

function Landmine:playExplosionEffect()
	local blast = Instance.new("Part")
	blast.Name = "LandmineBlast"
	blast.Shape = Enum.PartType.Ball
	blast.Size = Vector3.new(1, 1, 1)
	blast.Anchored = true
	blast.CanCollide = false
	blast.Material = Enum.Material.Neon
	blast.Color = Color3.fromRGB(255, 170, 0)
	blast.Transparency = 0.15
	blast.CFrame = self.part.CFrame
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

function Landmine:detonate()
	if self.detonated then
		return
	end
	self.detonated = true
	self:playExplosionEffect()

	local humanoid = self.lastHumanoid
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(DAMAGE)

		local rootPart = humanoid.RootPart
		if rootPart then
			local flingDirection = rootPart.CFrame.LookVector
			if flingDirection.Magnitude < 0.001 then
				flingDirection = Vector3.new(0, 0, -1)
			end
			rootPart.AssemblyLinearVelocity = (flingDirection.Unit * HORIZONTAL_FORCE) + Vector3.new(0, UPWARD_FORCE, 0)
		end

		RagdollService:RagdollCharacter(humanoid.Parent, RAGDOLL_DURATION, "blast")
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
