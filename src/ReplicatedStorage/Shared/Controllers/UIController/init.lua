local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function createTextLabel(name: string, parent: Instance, size: UDim2, position: UDim2, textSize: number, alignment)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("TextLabel") then
		return existing
	end

	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.TextScaled = false
	label.TextSize = textSize
	label.RichText = true
	label.TextXAlignment = alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function getOrCreateMainGui()
	local existing = PlayerGui:FindFirstChild("Main")
	local screenGui = existing
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "Main"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = PlayerGui
	end

	local debugUi = screenGui:FindFirstChild("DebugUI")
	if not debugUi then
		debugUi = Instance.new("Frame")
		debugUi.Name = "DebugUI"
		debugUi.BackgroundTransparency = 1
		debugUi.Size = UDim2.fromOffset(260, 120)
		debugUi.Position = UDim2.fromOffset(16, 16)
		debugUi.Parent = screenGui
	end

	createTextLabel("FPS", debugUi, UDim2.fromOffset(240, 24), UDim2.fromOffset(0, 0), 18, Enum.TextXAlignment.Left)
	createTextLabel("Ping", debugUi, UDim2.fromOffset(240, 24), UDim2.fromOffset(0, 28), 18, Enum.TextXAlignment.Left)
	createTextLabel("Physics", debugUi, UDim2.fromOffset(240, 24), UDim2.fromOffset(0, 56), 18, Enum.TextXAlignment.Left)
	createTextLabel("Location", debugUi, UDim2.fromOffset(240, 24), UDim2.fromOffset(0, 84), 18, Enum.TextXAlignment.Left)

	local statusUi = screenGui:FindFirstChild("StatusUI")
	if not statusUi then
		statusUi = Instance.new("Frame")
		statusUi.Name = "StatusUI"
		statusUi.AnchorPoint = Vector2.new(0.5, 0)
		statusUi.BackgroundTransparency = 1
		statusUi.Position = UDim2.fromScale(0.5, 0.035)
		statusUi.Size = UDim2.fromOffset(540, 120)
		statusUi.Parent = screenGui
	end

	local title = createTextLabel("Title", statusUi, UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 0), 28, Enum.TextXAlignment.Center)
	title.Text = "Minefield"

	local subtitle = createTextLabel("Subtitle", statusUi, UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 40), 18, Enum.TextXAlignment.Center)
	subtitle.TextColor3 = Color3.fromRGB(211, 234, 255)
	subtitle.Text = "Waiting for the round to begin"

	local announcement = createTextLabel(
		"Announcement",
		statusUi,
		UDim2.new(1, 0, 0, 30),
		UDim2.fromOffset(0, 74),
		16,
		Enum.TextXAlignment.Center
	)
	announcement.TextColor3 = Color3.fromRGB(255, 224, 134)
	announcement.Text = ""

	local progressUi = screenGui:FindFirstChild("ProgressUI")
	if not progressUi then
		progressUi = Instance.new("Frame")
		progressUi.Name = "ProgressUI"
		progressUi.AnchorPoint = Vector2.new(0.5, 1)
		progressUi.BackgroundColor3 = Color3.fromRGB(16, 23, 30)
		progressUi.BackgroundTransparency = 0.2
		progressUi.BorderSizePixel = 0
		progressUi.Position = UDim2.fromScale(0.5, 0.965)
		progressUi.Size = UDim2.fromOffset(300, 44)
		progressUi.Parent = screenGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = progressUi
	end

	local progressLabel = createTextLabel(
		"Progress",
		progressUi,
		UDim2.new(1, -24, 1, 0),
		UDim2.fromOffset(12, 0),
		18,
		Enum.TextXAlignment.Center
	)
	progressLabel.Text = "Reach the finish platform"

	return screenGui
end

local MainGui = getOrCreateMainGui()

local Shared = {}

Shared.Guis = {
	DebugUI = MainGui:WaitForChild("DebugUI"),
	StatusUI = MainGui:WaitForChild("StatusUI"),
	ProgressUI = MainGui:WaitForChild("ProgressUI"),
}

return Shared
