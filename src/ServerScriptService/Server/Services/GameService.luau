local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameService = {} 

local SEGMENTS_FOLDER: Folder = workspace.Map.Segments

local activeHazards = {}

local MINES_PER_SEGMENT = 200
local RANDOM = Random.new()

function GameService.onStart()
    while true do
        for _, segment in SEGMENTS_FOLDER:GetChildren() do
            if segment:IsA("Model") then
                populateSegmentWithLandmines(segment)
                applyRandomHazard(segment)
            end
        end
        task.wait(30)
        for _, segment in SEGMENTS_FOLDER:GetChildren() do
            if segment:IsA("Model") then
                destroyHazard(segment)
            end
        end
    end
end

function applyRandomHazard(segment:Model)
    local hazardTypes = ServerScriptService.Server.Hazards:GetChildren()
    local randomIndex = RANDOM:NextInteger(1, #hazardTypes)
    local selectedHazard = hazardTypes[randomIndex]
    applyHazard(segment, selectedHazard.Name)
end

function destroyHazard(segment:Model)
    local hazard = activeHazards[segment]
    if hazard then
        hazard:destroy()
        activeHazards[segment] = nil
    end
    local hazardModel = segment:FindFirstChild("Hazard")
    if hazardModel then
        hazardModel:Destroy()
    end
end

function applyHazard(segment:Model, hazardName: string)
    local hazardFolder = ReplicatedStorage.Assets.Hazards
    local hazard = hazardFolder:FindFirstChild(hazardName)

    assert(hazard,"Hazard was not found")

    local hazardClone = hazard:Clone()
    hazardClone.Name = "Hazard"
    hazardClone.Parent = segment
    hazardClone:PivotTo(segment:GetPivot())

    local hazardModule = require(ServerScriptService.Server.Hazards:FindFirstChild(hazardName))
    local newHazard = hazardModule.new(hazardClone)
    activeHazards[segment] = newHazard
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