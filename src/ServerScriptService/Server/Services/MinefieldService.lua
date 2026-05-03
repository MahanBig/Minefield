local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameEvents = require(ReplicatedStorage.Shared.Utilities.GameEvents)

local MinefieldService = {}

local SEGMENT_COUNT = 9
local SEGMENT_SIZE = Vector3.new(28, 2, 34)
local SEGMENT_GAP = 5
local MINES_PER_SEGMENT = 22
local SAFE_LANE_HALF_WIDTH = 4
local ROUND_DURATION = 65
local INTERMISSION_DURATION = 10

local GENERATED_MAP_NAME = "GeneratedMinefield"

local currentMap
local currentSpawnPart
local currentSpectatorPart
local currentGoalPart
local finishedPlayers = {}
local eliminatedPlayers = {}
local roundActive = false
local roundNumber = 0

local function ensureLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local wins = leaderstats:FindFirstChild("Wins")
	if not wins then
		wins = Instance.new("IntValue")
		wins.Name = "Wins"
		wins.Parent = leaderstats
	end

	local currency = leaderstats:FindFirstChild("Currency")
	if not currency then
		currency = Instance.new("IntValue")
		currency.Name = "Currency"
		currency.Parent = leaderstats
	end

	return leaderstats, wins, currency
end

local function getSegmentBasePart(segment)
	if segment:IsA("BasePart") then
		return segment
	end
	if segment:IsA("Model") then
		return segment.PrimaryPart or segment:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function createPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function createMapContainer()
	if currentMap then
		currentMap:Destroy()
	end

	local existing = Workspace:FindFirstChild(GENERATED_MAP_NAME)
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = GENERATED_MAP_NAME
	map.Parent = Workspace

	local segments = Instance.new("Folder")
	segments.Name = "Segments"
	segments.Parent = map

	return map, segments
end

local function createMarkerStrip(segment: BasePart, safeLaneX: number)
	local strip = Instance.new("Part")
	strip.Name = "SafeLaneHint"
	strip.Size = Vector3.new(SAFE_LANE_HALF_WIDTH * 2.1, 0.05, SEGMENT_SIZE.Z * 0.9)
	strip.Anchored = true
	strip.CanCollide = false
	strip.Material = Enum.Material.Neon
	strip.Color = Color3.fromRGB(99, 203, 142)
	strip.Transparency = 0.8
	strip.CFrame = segment.CFrame * CFrame.new(safeLaneX, (segment.Size.Y / 2) + 0.04, 0)
	strip.Parent = segment
end

local function spawnMinesOnSegment(segment, safeLaneX: number)
	local basePart = getSegmentBasePart(segment)
	if not basePart then
		return
	end

	createMarkerStrip(basePart, safeLaneX)

	local spawned = 0
	local attempts = 0
	while spawned < MINES_PER_SEGMENT and attempts < MINES_PER_SEGMENT * 8 do
		attempts += 1

		local x = (math.random() - 0.5) * math.max(0, basePart.Size.X - 2.5)
		if math.abs(x - safeLaneX) <= SAFE_LANE_HALF_WIDTH then
			continue
		end

		local z = (math.random() - 0.5) * math.max(0, basePart.Size.Z - 2.5)
		local mine = Instance.new("Part")
		mine.Name = "Landmine"
		mine.Size = Vector3.new(2, 0.25, 2)
		mine.Anchored = true
		mine.CanCollide = false
		mine.Transparency = 1

		local y = (basePart.Size.Y / 2) + (mine.Size.Y / 2) + 0.01
		mine.CFrame = basePart.CFrame * CFrame.new(x, y, z)
		mine.Parent = segment

		CollectionService:AddTag(mine, "Landmine")
		spawned += 1
	end
end

local function chooseHazardTag()
	local pool = {
		{ tag = "LavaSpinner", weight = 22 },
		{ tag = "Tsunami", weight = 14 },
		{ tag = "", weight = 28 },
	}

	local total = 0
	for _, entry in ipairs(pool) do
		total = total + entry.weight
	end

	local choice = math.random(1, total)
	local cursor = 0
	for _, entry in ipairs(pool) do
		cursor = cursor + entry.weight
		if choice <= cursor then
			return entry.tag
		end
	end

	return ""
end

local function sendRoundState(title: string, subtitle: string, progress: string, announcement: string?)
	GameEvents.RoundState:FireAllClients({
		title = title,
		subtitle = subtitle,
		progress = progress,
		announcement = announcement or "",
	})
end

local function getCharacterRoot(player: Player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function movePlayerToPart(player: Player, destination: BasePart?)
	if not destination then
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return
	end

	local offsetX = math.random(-5, 5)
	character:PivotTo(destination.CFrame + Vector3.new(offsetX, 4, 0))
end

local function countResolvedPlayers()
	local resolved = 0
	for _, player in Players:GetPlayers() do
		if finishedPlayers[player] or eliminatedPlayers[player] then
			resolved += 1
		end
	end
	return resolved
end

local function allPlayersResolved()
	local players = Players:GetPlayers()
	if #players == 0 then
		return false
	end

	return countResolvedPlayers() >= #players
end

local function awardWinner(player: Player)
	local _, wins, currency = ensureLeaderstats(player)
	wins.Value += 1
	currency.Value += 25
end

local function setupGoal(goalPart: BasePart)
	goalPart.Touched:Connect(function(hit)
		if not roundActive then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or finishedPlayers[player] or eliminatedPlayers[player] then
			return
		end

		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		finishedPlayers[player] = true
		awardWinner(player)
		GameEvents.Notification:FireAllClients(string.format("%s reached the goal!", player.DisplayName))
	end)
end

local function buildRoundMap()
	local map, segmentsFolder = createMapContainer()
	currentMap = map

	local totalLength = (SEGMENT_COUNT * SEGMENT_SIZE.Z) + ((SEGMENT_COUNT - 1) * SEGMENT_GAP)
	local startZ = -(totalLength / 2)

	local floor = createPart(
		"Backdrop",
		Vector3.new(SEGMENT_SIZE.X + 100, 1, totalLength + 120),
		CFrame.new(0, -4, startZ + (totalLength / 2)),
		Color3.fromRGB(26, 36, 28),
		map
	)
	floor.Material = Enum.Material.Slate

	local spawnPlatform = createPart(
		"SpawnPlatform",
		Vector3.new(SEGMENT_SIZE.X + 8, 1.5, 24),
		CFrame.new(0, 2, startZ - 24),
		Color3.fromRGB(84, 136, 84),
		map
	)
	spawnPlatform.Material = Enum.Material.Grass
	currentSpawnPart = spawnPlatform

	local spectatorPlatform = createPart(
		"SpectatorPlatform",
		Vector3.new(18, 1, 18),
		spawnPlatform.CFrame * CFrame.new(0, 16, -4),
		Color3.fromRGB(71, 86, 102),
		map
	)
	spectatorPlatform.Material = Enum.Material.SmoothPlastic
	currentSpectatorPart = spectatorPlatform

	for index = 1, SEGMENT_COUNT do
		local z = startZ + ((index - 1) * (SEGMENT_SIZE.Z + SEGMENT_GAP))
		local segment = createPart(
			"Segment" .. index,
			SEGMENT_SIZE,
			CFrame.new(0, 0, z),
			Color3.fromRGB(63 + (index * 3), 122, 70),
			segmentsFolder
		)
		segment.Material = Enum.Material.Grass

		local safeLaneX = math.random(-8, 8)
		spawnMinesOnSegment(segment, safeLaneX)

		if index > 1 and index < SEGMENT_COUNT then
			local hazardTag = chooseHazardTag()
			if hazardTag ~= "" then
				CollectionService:AddTag(segment, hazardTag)
			end
		end
	end

	local goalZ = startZ + ((SEGMENT_COUNT - 1) * (SEGMENT_SIZE.Z + SEGMENT_GAP)) + 26
	local goal = createPart(
		"GoalPlatform",
		Vector3.new(SEGMENT_SIZE.X + 10, 1.5, 24),
		CFrame.new(0, 2, goalZ),
		Color3.fromRGB(222, 196, 88),
		map
	)
	goal.Material = Enum.Material.Neon
	currentGoalPart = goal

	local banner = createPart(
		"GoalBanner",
		Vector3.new(SEGMENT_SIZE.X + 4, 16, 1),
		goal.CFrame * CFrame.new(0, 8, -10),
		Color3.fromRGB(245, 236, 168),
		map
	)
	banner.Material = Enum.Material.Neon
	banner.CanCollide = false

	setupGoal(goal)
end

local function sendPlayersToCurrentSpawn()
	for _, player in Players:GetPlayers() do
		task.defer(movePlayerToPart, player, currentSpawnPart)
	end
end

local function updatePlayerEliminationState(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		if not roundActive or finishedPlayers[player] then
			return
		end

		eliminatedPlayers[player] = true
		GameEvents.Notification:FireAllClients(string.format("%s was eliminated!", player.DisplayName))

		task.delay(1.25, function()
			if player.Character then
				movePlayerToPart(player, currentSpectatorPart)
			end
		end)
	end)
end

local function setupPlayers()
	local function onPlayerAdded(player: Player)
		ensureLeaderstats(player)

		player.CharacterAdded:Connect(function(character)
			task.defer(updatePlayerEliminationState, character)
			task.delay(0.15, function()
				if roundActive then
					if eliminatedPlayers[player] then
						movePlayerToPart(player, currentSpectatorPart)
					else
						movePlayerToPart(player, currentSpawnPart)
					end
				elseif currentSpawnPart then
					movePlayerToPart(player, currentSpawnPart)
				end
			end)
		end)

		if player.Character then
			task.defer(updatePlayerEliminationState, player.Character)
		end
	end

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		finishedPlayers[player] = nil
		eliminatedPlayers[player] = nil
	end)
end

local function resetRoundState()
	table.clear(finishedPlayers)
	table.clear(eliminatedPlayers)
end

local function runIntermission()
	roundActive = false
	resetRoundState()
	buildRoundMap()
	sendPlayersToCurrentSpawn()

	for timeLeft = INTERMISSION_DURATION, 1, -1 do
		sendRoundState(
			"Minefield",
			string.format("Round %d starts in %ds", roundNumber + 1, timeLeft),
			"Study the field and pick a lane",
			"Landmines fling you forward based on your facing direction"
		)
		task.wait(1)
	end
end

local function runRound()
	roundNumber += 1
	roundActive = true

	for timeLeft = ROUND_DURATION, 0, -1 do
		local resolved = countResolvedPlayers()
		sendRoundState(
			string.format("Minefield - Round %d", roundNumber),
			string.format("Reach the goal before time runs out: %ds", timeLeft),
			string.format("%d/%d players resolved", resolved, #Players:GetPlayers()),
			"Green strips hint at safer lanes, but hazards can still punish sloppy movement"
		)

		if timeLeft < ROUND_DURATION and allPlayersResolved() then
			break
		end

		task.wait(1)
	end

	roundActive = false
	local winners = 0
	for _player, didFinish in finishedPlayers do
		if didFinish then
			winners += 1
		end
	end

	sendRoundState(
		"Round Complete",
		string.format("%d player%s survived the field", winners, if winners == 1 then "" else "s"),
		"New hazards are being placed",
		""
	)
	task.wait(3)
end

function MinefieldService:onStart()
	setupPlayers()

	while true do
		runIntermission()
		runRound()
	end
end

return MinefieldService
