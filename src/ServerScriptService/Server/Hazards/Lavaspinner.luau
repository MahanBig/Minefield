local RunService = game:GetService("RunService")
local Lavaspinner = {}
Lavaspinner.__index = Lavaspinner
local SPIN_SPEED = 90

function Lavaspinner.new(instance:Model)
    local self = setmetatable({}, Lavaspinner)
    self.instance = instance
    self.spinner = self.instance:FindFirstChild("Spinner")
    self.connections = {}

    self:init()
    return self
end
function Lavaspinner:init()
    local spinConnection = RunService.Heartbeat:Connect(function(dt)
            if self.spinner then
                self.spinner.CFrame *= CFrame.Angles(0, math.rad(SPIN_SPEED*dt), 0)
            end
        end)
    table.insert(self.connections, spinConnection)
end
function Lavaspinner:destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}
end

return Lavaspinner
