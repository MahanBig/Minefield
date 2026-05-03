local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEvents = require(ReplicatedStorage.Shared.Utilities.GameEvents)

local RagdollService = {}

local characterStates = {}

local function getHumanoid(character: Model)
	return character:FindFirstChildOfClass("Humanoid")
end

local function getPlayerFromCharacter(character: Model)
	return Players:GetPlayerFromCharacter(character)
end

local function createConstraintForMotor(motor: Motor6D)
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "RagdollAttachment0"
	attachment0.CFrame = motor.C0
	attachment0.Parent = motor.Part0

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "RagdollAttachment1"
	attachment1.CFrame = motor.C1
	attachment1.Parent = motor.Part1

	local constraint = Instance.new("BallSocketConstraint")
	constraint.Name = "RagdollConstraint"
	constraint.Attachment0 = attachment0
	constraint.Attachment1 = attachment1
	constraint.Enabled = false
	constraint.LimitsEnabled = true
	constraint.TwistLimitsEnabled = true
	constraint.UpperAngle = 45
	constraint.TwistLowerAngle = -35
	constraint.TwistUpperAngle = 35
	constraint.Parent = motor.Parent

	return attachment0, attachment1, constraint
end

local function ensureState(character: Model)
	local existing = characterStates[character]
	if existing then
		return existing
	end

	local state = {
		character = character,
		motors = {},
		constraints = {},
		token = 0,
		isRagdolled = false,
		isDead = false,
	}

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") and descendant.Part0 and descendant.Part1 and descendant.Name ~= "RootJoint" then
			local attachment0, attachment1, constraint = createConstraintForMotor(descendant)
			table.insert(state.motors, descendant)
			table.insert(state.constraints, {
				attachment0 = attachment0,
				attachment1 = attachment1,
				constraint = constraint,
			})
		elseif descendant:IsA("BasePart") then
			descendant.CanCollide = true
		end
	end

	characterStates[character] = state
	return state
end

function RagdollService:RestoreCharacter(character: Model)
	local state = characterStates[character]
	if not state or state.isDead then
		return
	end

	local humanoid = getHumanoid(character)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	state.isRagdolled = false

	for _, motor in state.motors do
		motor.Enabled = true
	end

	for _, bundle in state.constraints do
		bundle.constraint.Enabled = false
	end

	humanoid.AutoRotate = true
	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	local player = getPlayerFromCharacter(character)
	if player then
		GameEvents.Ragdoll:FireAllClients(player.UserId, false)
	end
end

function RagdollService:RagdollCharacter(character: Model, duration: number?, reason: string?)
	local humanoid = getHumanoid(character)
	if not humanoid then
		return
	end

	local state = ensureState(character)
	state.token += 1
	local activeToken = state.token
	state.isRagdolled = true
	state.isDead = reason == "death" or humanoid.Health <= 0

	for _, motor in state.motors do
		motor.Enabled = false
	end

	for _, bundle in state.constraints do
		bundle.constraint.Enabled = true
	end

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local player = getPlayerFromCharacter(character)
	if player then
		GameEvents.Ragdoll:FireAllClients(player.UserId, true)
	end

	if duration and duration > 0 and not state.isDead then
		task.delay(duration, function()
			if not character.Parent then
				return
			end
			local currentState = characterStates[character]
			if not currentState or currentState.token ~= activeToken or currentState.isDead then
				return
			end
			self:RestoreCharacter(character)
		end)
	end
end

local function setupCharacter(character: Model)
	local humanoid = getHumanoid(character)
	if not humanoid then
		return
	end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	ensureState(character)

	humanoid.Died:Connect(function()
		RagdollService:RagdollCharacter(character, nil, "death")
	end)

	character.Destroying:Connect(function()
		characterStates[character] = nil
	end)
end

function RagdollService.onStart()
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(setupCharacter)
		if player.Character then
			task.defer(setupCharacter, player.Character)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(setupCharacter)
	end)
end

return RagdollService
