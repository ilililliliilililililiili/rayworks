local FriendService = {}

local AnotherService

function FriendService:Init(Rayworks)
    self.Logger = Rayworks.Util.Logger.new("FriendService")
    self.Logger:LogInfo("Logger testing :3")
end

function FriendService:Start(Rayworks)
    AnotherService = Rayworks:GetModule("AnotherService")
    self.Logger:LogInfo("got all required services")

    self:SomeFunction()
end

function FriendService:SomeFunction()
    AnotherService:TestFunction()
end

return FriendService