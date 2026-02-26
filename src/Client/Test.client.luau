local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BasicNetwork = require(ReplicatedStorage.Shared.Utilities.BasicNetwork)
local testRemote = BasicNetwork.new("Test")

testRemote:FireServer("Hello World")
