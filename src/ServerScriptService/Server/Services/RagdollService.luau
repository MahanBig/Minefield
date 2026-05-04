local Players = game:GetService("Players")

local RagdollService = {}

local RAGDOLL_FOLDER_NAME = "RagdollSetup"
local CONSTRAINTS_FOLDER_NAME = "Constraints"
local COLLIDERS_FOLDER_NAME = "Colliders"
local RAGDOLL_ATTRIBUTE = "Ragdolling"
local PREPARED_ATTRIBUTE = "RagdollPrepared"

local function isCharacterPart(character, instance)
	return instance:IsA("BasePart") and instance.Parent == character and instance.Name ~= "HumanoidRootPart"
end

local function getRagdollMotors(character)
	local motors = {}

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") and descendant.Name ~= "RootJoint" then
			if descendant.Part0 and descendant.Part1 then
				table.insert(motors, descendant)
			end
		end
	end

	return motors
end

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if folder then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createCollider(part, collidersFolder)
	local collider = Instance.new("Part")
	collider.Name = `{part.Name}Collider`
	collider.Size = part.Size * 0.85
	collider.CFrame = part.CFrame
	collider.Transparency = 1
	collider.Massless = true
	collider.Anchored = false
	collider.CanCollide = false
	collider.CanTouch = false
	collider.CanQuery = false
	collider.Parent = collidersFolder

	local weld = Instance.new("WeldConstraint")
	weld.Name = "ColliderWeld"
	weld.Part0 = part
	weld.Part1 = collider
	weld.Parent = collider

	local noCollision = Instance.new("NoCollisionConstraint")
	noCollision.Name = "SourceNoCollision"
	noCollision.Part0 = part
	noCollision.Part1 = collider
	noCollision.Parent = collider

	return collider
end

local function disableColliderSelfCollision(colliders)
	for index, collider in colliders do
		for otherIndex = index + 1, #colliders do
			local otherCollider = colliders[otherIndex]

			local noCollision = Instance.new("NoCollisionConstraint")
			noCollision.Name = "ColliderNoCollision"
			noCollision.Part0 = collider
			noCollision.Part1 = otherCollider
			noCollision.Parent = collider
		end
	end
end

function RagdollService.onStart()
	for _, player in Players:GetPlayers() do
		if player.Character then
			task.defer(function()
				RagdollService:PrepareCharacter(player.Character)
			end)
		end

		player.CharacterAdded:Connect(function(character)
			RagdollService:PrepareCharacter(character)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			RagdollService:PrepareCharacter(character)
		end)
	end)
end

function RagdollService:PrepareCharacter(character)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid or character:GetAttribute(PREPARED_ATTRIBUTE) then
		return
	end

	if not character:FindFirstChild("Torso") then
		character:WaitForChild("Torso", 5)
	end

	character:SetAttribute(PREPARED_ATTRIBUTE, true)

	local setupFolder = getOrCreateFolder(character, RAGDOLL_FOLDER_NAME)
	local constraintsFolder = getOrCreateFolder(setupFolder, CONSTRAINTS_FOLDER_NAME)
	local collidersFolder = getOrCreateFolder(setupFolder, COLLIDERS_FOLDER_NAME)

	for _, motor in getRagdollMotors(character) do
		local attachment0 = Instance.new("Attachment")
		attachment0.Name = `{motor.Name}RagdollAttachment0`
		attachment0.CFrame = motor.C0
		attachment0.Parent = motor.Part0

		local attachment1 = Instance.new("Attachment")
		attachment1.Name = `{motor.Name}RagdollAttachment1`
		attachment1.CFrame = motor.C1
		attachment1.Parent = motor.Part1

		local socket = Instance.new("BallSocketConstraint")
		socket.Name = `{motor.Name}RagdollSocket`
		socket.Attachment0 = attachment0
		socket.Attachment1 = attachment1
		socket.LimitsEnabled = true
		socket.TwistLimitsEnabled = true
		socket.UpperAngle = 55
		socket.TwistLowerAngle = -35
		socket.TwistUpperAngle = 35
		socket.Enabled = false
		socket.Parent = constraintsFolder
	end

	local colliders = {}
	for _, child in character:GetChildren() do
		if isCharacterPart(character, child) then
			table.insert(colliders, createCollider(child, collidersFolder))
		end
	end
	disableColliderSelfCollision(colliders)
end

function RagdollService:RagdollCharacter(character, duration)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or character:GetAttribute(RAGDOLL_ATTRIBUTE) then
		return
	end

	self:PrepareCharacter(character)

	local setupFolder = character:FindFirstChild(RAGDOLL_FOLDER_NAME)
	if not setupFolder then
		return
	end

	local constraintsFolder = setupFolder:FindFirstChild(CONSTRAINTS_FOLDER_NAME)
	local collidersFolder = setupFolder:FindFirstChild(COLLIDERS_FOLDER_NAME)
	if not constraintsFolder or not collidersFolder then
		return
	end

	character:SetAttribute(RAGDOLL_ATTRIBUTE, true)

	local previousRequiresNeck = humanoid.RequiresNeck
	local previousAutoRotate = humanoid.AutoRotate
	local collisionCache = {}

	humanoid.RequiresNeck = false
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	for _, part in character:GetChildren() do
		if part:IsA("BasePart") then
			collisionCache[part] = part.CanCollide
			part.CanCollide = false
		end
	end

	local disabledMotors = {}
	for _, motor in getRagdollMotors(character) do
		motor.Enabled = false
		table.insert(disabledMotors, motor)
	end

	for _, constraint in constraintsFolder:GetChildren() do
		if constraint:IsA("BallSocketConstraint") then
			constraint.Enabled = true
		end
	end

	for _, collider in collidersFolder:GetChildren() do
		if collider:IsA("BasePart") then
			collider.CanCollide = true
		end
	end

	task.delay(duration, function()
		self:UnragdollCharacter(character, disabledMotors, collisionCache, previousAutoRotate, previousRequiresNeck)
	end)
end

function RagdollService:UnragdollCharacter(character, disabledMotors, collisionCache, previousAutoRotate, previousRequiresNeck)
	if not character or not character.Parent then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local setupFolder = character:FindFirstChild(RAGDOLL_FOLDER_NAME)
	local constraintsFolder = setupFolder and setupFolder:FindFirstChild(CONSTRAINTS_FOLDER_NAME)
	local collidersFolder = setupFolder and setupFolder:FindFirstChild(COLLIDERS_FOLDER_NAME)

	if constraintsFolder then
		for _, constraint in constraintsFolder:GetChildren() do
			if constraint:IsA("BallSocketConstraint") then
				constraint.Enabled = false
			end
		end
	end

	if collidersFolder then
		for _, collider in collidersFolder:GetChildren() do
			if collider:IsA("BasePart") then
				collider.CanCollide = false
			end
		end
	end

	for _, motor in disabledMotors do
		if motor.Parent then
			motor.Enabled = true
		end
	end

	for part, canCollide in collisionCache do
		if part.Parent then
			part.CanCollide = canCollide
		end
	end

	if humanoid and humanoid.Parent and humanoid.Health > 0 then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = previousAutoRotate
		humanoid.RequiresNeck = previousRequiresNeck
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	character:SetAttribute(RAGDOLL_ATTRIBUTE, nil)
end

return RagdollService
