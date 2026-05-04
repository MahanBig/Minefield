local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BasicNetwork = require(ReplicatedStorage.Shared.Utilities.BasicNetwork)
local RagdollService = require(ServerScriptService.Server.Services.RagdollService)

local Landmine = {}
Landmine.Tag = script.Name
Landmine.__index = Landmine

local LandmineExploded = BasicNetwork.new("LandmineExploded",false,false)

local ARM_TIME = 0.12
local DAMAGE = 0
local HORIZONTAL_FORCE = 150
local UPWARD_FORCE = 200
local RAGDOLL_DURATION = 1

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

	self.part.Transparency = 1
	self.part.CanCollide = false
	self.part.CanTouch = true

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

	task.delay(ARM_TIME, function()
		self:detonate()
	end)
end

function Landmine:detonate()
	if self.detonated then
		return
	end
	self.detonated = true

	LandmineExploded:FireAllClients(self.instance, self.part.CFrame)

	local humanoid = self.lastHumanoid
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(DAMAGE)
		RagdollService:RagdollCharacter(humanoid.Parent, RAGDOLL_DURATION)

		local rootPart = humanoid.RootPart
		if rootPart then
			local lookVector = rootPart.CFrame.LookVector
			local flingDirection = Vector3.new(lookVector.X, 0, lookVector.Z)

			if flingDirection.Magnitude < 0.001 then
				flingDirection = Vector3.new(0, 0, -1)
			end

			rootPart.AssemblyLinearVelocity = (flingDirection.Unit * HORIZONTAL_FORCE) + Vector3.new(0, UPWARD_FORCE, 0)
		end
	end

	self.part.Transparency = 1
	self.part.CanCollide = false

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
