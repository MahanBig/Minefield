local GameService = {} 

local MAP_FOLDER: Folder = workspace.Map
local SEGMENTS_FOLDER: Folder = MAP_FOLDER.Segments

local MINES_PER_SEGMENT = 200
local RANDOM = Random.new()

function GameService.onStart()
    for _, segment in SEGMENTS_FOLDER:GetChildren() do
        if segment:IsA("Model") then
            populateSegmentWithLandmines(segment)
        end
    end
end

function getOrMakeFolder(parent: Instance, folderName: string): Folder
    local folder = parent:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = parent
    end
    return folder
end

function makeMine(cframe:CFrame)
    local mine = Instance.new("Part")
    mine.Size = Vector3.new(1, .2, 1)
    mine.CFrame = cframe
    mine.Anchored = true
    mine:AddTag("Landmine")
    return mine
end

function populateSegmentWithLandmines(segment: Model)
    local primaryPart = segment.PrimaryPart
    if not primaryPart then
        warn("Segment missing primary part:", segment:GetFullName())
        return
    end
    local minesFolder = getOrMakeFolder(segment, "Mines")

    for i = 1, MINES_PER_SEGMENT do
        local randomXPos = RANDOM:NextNumber(-primaryPart.Size.X/2, primaryPart.Size.X/2)
        local randomZPos = RANDOM:NextNumber(-primaryPart.Size.Z/2, primaryPart.Size.Z/2)
        local Ypos = primaryPart.Size.Y/2 + 0.1
        local mineCFrame = primaryPart.CFrame * CFrame.new(randomXPos, Ypos, randomZPos)
        local mine = makeMine(mineCFrame)
        mine.Parent = minesFolder
    end
end

return GameService