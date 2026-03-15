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
	self.baseCFrame = self.instance.CFrame
	self.elapsed = 0

	self.windSpeed = 0.6 -- cycles per second
	self.twistAmount = math.rad(8)
	self.bobAmount = 0.12
	self.spinSpeed = math.rad(30)

	self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		self.elapsed = self.elapsed + deltaTime

		local overallSpin = self.elapsed * self.spinSpeed
		local windSway = math.sin(self.elapsed * self.windSpeed * math.pi * 2) * self.twistAmount
		local lean = math.sin(self.elapsed * 1.3) * 0.02
		local bob = math.sin(self.elapsed * 1.7) * self.bobAmount

		local animatedCFrame = self.baseCFrame * CFrame.new(0, bob, 0) * CFrame.Angles(lean, overallSpin, windSway)

		self.instance.CFrame = animatedCFrame

		-- Optional extra per-part leaf jiggle if leaf parts exist
		for _, part in ipairs(self.instance:GetDescendants()) do
			if part:IsA("BasePart") and part.Name:lower():find("leaf") then
				local pulse = (1 + math.sin(self.elapsed * 6 + part:GetDebugId(1) % 10)) * 0.5
				part.Transparency = math.clamp(0.0 + (1 - pulse) * 0.2, 0, 1)
			end
		end
	end)
end

function Tree:destroy()
	print("Test component destroyed for", self.instance:GetFullName())
	if self.heartbeatConnection then
		self.heartbeatConnection:Disconnect()
		self.heartbeatConnection = nil
	end
	self.instance:Destroy()
end
return Tree
