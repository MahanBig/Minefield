local RunService = game:GetService("RunService")

local LavaSpinner = {}
LavaSpinner.Tag = script.Name
LavaSpinner.__index = LavaSpinner

local function getBasePart(instance)
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function damageHumanoid(hit, amount)
	local character = hit and hit.Parent
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(amount)
	end
end

function LavaSpinner.new(instance)
	local self = setmetatable({}, LavaSpinner)
	self.instance = instance
	self.part = getBasePart(instance)
	self.active = true

	self:init()
	return self
end

function LavaSpinner:init()
	if not self.part then
		warn("LavaSpinner: missing part on", self.instance:GetFullName())
		return
	end

	self.spinner = Instance.new("Part")
	self.spinner.Name = "LavaSpinnerBlade"
	self.spinner.Size = Vector3.new(self.part.Size.X * 0.8, 1, 1)
	self.spinner.Anchored = true
	self.spinner.CanCollide = false
	self.spinner.Transparency = 0.3
	self.spinner.Material = Enum.Material.Neon
	self.spinner.BrickColor = BrickColor.new("Bright orange")
	self.spinner.CFrame = self.part.CFrame * CFrame.new(0, 2.5, 0)
	self.spinner.Parent = self.part

	self.spinner.Touched:Connect(function(hit)
		damageHumanoid(hit, 15)
	end)

	RunService.Heartbeat:Connect(function(dt)
		if not self.active or not self.spinner.Parent then
			return
		end
		self.spinner.CFrame = self.spinner.CFrame * CFrame.Angles(0, math.rad(160 * dt), 0)
	end)
end

function LavaSpinner:destroy()
	self.active = false
	if self.spinner then
		self.spinner:Destroy()
	end
	print("LavaSpinner component destroyed for", self.instance:GetFullName())
end

return LavaSpinner
