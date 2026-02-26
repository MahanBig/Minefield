local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BasicNetwork = require(ReplicatedStorage.Shared.Utilities.BasicNetwork)
local testRemote = BasicNetwork.new("Test")

testRemote:Connect(function(plr, data)
	print(data)
end)
