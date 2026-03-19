local CollectionService = game:GetService("CollectionService")

local MinefieldService = {}

local function getSegmentsFolder()
	local map = workspace:FindFirstChild("Map")
	if not map then
		warn("MinefieldService: Map folder is missing in Workspace")
		return nil
	end

	local segments = map:FindFirstChild("Segments")
	if not segments then
		warn("MinefieldService: Segments folder is missing under Map")
		return nil
	end

	return segments
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

local function spawnMinesOnSegment(segment)
	local basePart = getSegmentBasePart(segment)
	if not basePart then
		warn("MinefieldService: couldn't find base part for segment", segment:GetFullName())
		return
	end

	for i = 1, 300 do
		local mine = Instance.new("Part")
		mine.Name = "Landmine"
		mine.Size = Vector3.new(2, 0.25, 2)
		mine.Anchored = true
		mine.CanCollide = false
		mine.Material = Enum.Material.Metal
		mine.BrickColor = BrickColor.new("Really red")
		mine.TopSurface = Enum.SurfaceType.Smooth
		mine.BottomSurface = Enum.SurfaceType.Smooth

		local x = (math.random() - 0.5) * math.max(0, basePart.Size.X - 0.9)
		local z = (math.random() - 0.5) * math.max(0, basePart.Size.Z - 0.9)
		local y = (basePart.Size.Y / 2) + (mine.Size.Y / 2) + 0.01
		mine.CFrame = basePart.CFrame * CFrame.new(x, y, z)
		mine.Parent = segment

		CollectionService:AddTag(mine, "Landmine")
	end
end

local function chooseHazardTag()
	-- Weighted randomness: mines are most common, but we also have special obstacles.
	local pool = {
		{ tag = "LavaSpinner", weight = 25 },
		{ tag = "Tsunami", weight = 15 },
		{ tag = "", weight = 10 },
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

function MinefieldService:onStart()
	local segments = getSegmentsFolder()
	if not segments then
		return
	end

	local allSegments = segments:GetChildren()
	if #allSegments == 0 then
		warn("MinefieldService: No segments found in Map/Segments")
		return
	end

	for _, segment in ipairs(allSegments) do
		if segment:IsA("BasePart") or segment:IsA("Model") then
			spawnMinesOnSegment(segment)

			local tag = chooseHazardTag()
			if tag ~= "" then
				CollectionService:AddTag(segment, tag)
				print(string.format("MinefieldService: placed %s on %s", tag, segment:GetFullName()))
			end
		end
	end

	print("MinefieldService: minefield generated with random hazards and mine clusters")
end

return MinefieldService
