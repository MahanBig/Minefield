local RunService = game:GetService("RunService")

local Tsunami = {}
Tsunami.Tag = script.Name
Tsunami.__index = Tsunami

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

function Tsunami.new(instance)
	local self = setmetatable({}, Tsunami)
	self.instance = instance
	self.part = getBasePart(instance)
	self.running = true

	self:init()
	return self
end

function Tsunami:init()
	if not self.part then
		warn("Tsunami: missing part on", self.instance:GetFullName())
		return
	end

	task.spawn(function()
		while self.running do
			local base = self.part
			local halfX = base.Size.X / 2 + 2
			local startCFrame = base.CFrame * CFrame.new(-halfX, 2.5, 0)
			local endCFrame = base.CFrame * CFrame.new(halfX, 2.5, 0)

			local wave = Instance.new("Part")
			wave.Name = "TsunamiWave"
			wave.Size = Vector3.new(3, 5, base.Size.Z * 0.6)
			wave.Anchored = true
			wave.CanCollide = false
			wave.Transparency = 0.55
			wave.Material = Enum.Material.Neon
			wave.BrickColor = BrickColor.new("Bright blue")
			wave.CFrame = startCFrame
			wave.Parent = base

			wave.Touched:Connect(function(hit)
				damageHumanoid(hit, 12)
			end)

			local totalTime = 1.4
			local elapsed = 0
			while elapsed < totalTime and wave and wave.Parent and self.running do
				local alpha = elapsed / totalTime
				wave.CFrame = startCFrame:Lerp(endCFrame, alpha)
				local dt = RunService.Heartbeat:Wait()
				elapsed = elapsed + dt
			end

			if wave and wave.Parent then
				wave:Destroy()
			end

			task.wait(3)
		end
	end)
end

function Tsunami:destroy()
	self.running = false
	print("Tsunami component destroyed for", self.instance:GetFullName())
end

return Tsunami
