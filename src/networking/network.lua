-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local CreateFrame, GetChannelList, GetNumDisplayChannels, JoinChannelByName =
_G.CreateFrame, _G.GetChannelList, _G.GetNumDisplayChannels, _G.JoinChannelByName

-- Libs
local LibStub = _G.LibStub
local Serializer = LibStub:GetLibrary("AceSerializer-3.0")
local AceComm = LibStub:GetLibrary("AceComm-3.0")

--[[
ClassicWoTNetwork uses AceComm to send and receive messages over Addon channels
and broadcast them as events once received fully over our EventBus.
--]]
---@class ClassicWoTNetwork
---@field Core ClassicWoTCore
---@field EventBus ClassicWoTEventBus
local ClassicWoTNetwork = {}
ClassicWoTNetwork.__index = ClassicWoTNetwork
ClassicWoT.Network = ClassicWoTNetwork

setmetatable(ClassicWoTNetwork, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

---@param Core ClassicWoTCore
---@param EventBus ClassicWoTEventBus
function ClassicWoTNetwork.new(Core, EventBus)
    local self = setmetatable({}, ClassicWoTNetwork)

    self.Core = Core
    self.EventBus = EventBus
    self.MessageBuffer = {}

    -- create a Frame to use as thread to recieve events on
    self.Thread = CreateFrame("Frame")
    self.Thread:Hide()
    self.Thread:SetScript("OnEvent", function(_, event)
        ClassicWoT:DebugPrint(event)
        if (event == "CHANNEL_UI_UPDATE") then
            self:InitChannel()
        end
    end)

    -- init channel if we're not too early (otherwise we'll wait for CHANNEL_UI_UPDATE)
    if GetNumDisplayChannels() > 0 then
        self:InitChannel()
    end
    -- register for CHANNEL_UI_UPDATE so we know when our channel might have changed
    self.Thread:RegisterEvent("CHANNEL_UI_UPDATE")

    AceComm:RegisterComm(ClassicWoT.Config.Network.Prefix, function(...)
        self:HandleAddonMessage(...)
    end)

    return self
end

function ClassicWoTNetwork:InitChannel()
    JoinChannelByName(ClassicWoT.Config.Network.Channel.Name)

    local channelId = nil
    local channels = { GetChannelList() }
    local i = 2
    while i < #channels do
        if (channels[i] == ClassicWoT.Config.Network.Channel.Name) then
            channelId = channels[i - 1]
            break
        end
        i = i + 3
    end

    ClassicWoT.Config.Network.Channel.Id = channelId
end

function ClassicWoTNetwork:HandleAddonMessage(...)
    -- sender is always full name (name-realm)
    local prefix, message, _, sender = ...

    -- check if it's our prefix
    if prefix ~= ClassicWoT.Config.Network.Prefix then
        return
    end

    -- so we can pretend to be somebody else
    if sender == self.Core:FullRealMe() then
        sender = self.Core:FullMe()
    end

    -- ignore our own messages
    if sender == self.Core:FullRealMe() then
        return
    end

    -- completely ignore anything from other realms
    local _, senderRealm = self.Core:SplitFullPlayer(sender)
    if not self.Core:IsMyRealm(senderRealm) then
        return
    end

    local _, object = Serializer:Deserialize(message)
    local event, payload = object[1], object[2]

    ClassicWoT:TracePrint("Received Network Event: " .. event .. " From: " .. sender)

    self.EventBus:PublishEvent(event, payload, sender)
end

function ClassicWoTNetwork:SendObject(event, object, channel, target, prio)
    -- default to using the configured channel ID
    if channel == "CHANNEL" and target == nil then
        target = ClassicWoT.Config.Network.Channel.Id
    end
    -- no channel, no broadcast
    if channel == "CHANNEL" and target == nil then
        return
    end
    -- no priority, BULK
    if prio == nil then
        prio = "BULK"
    end

    ClassicWoT:TracePrint("Send Network Event: " .. event .. " Channel: " .. channel)

    AceComm:SendCommMessage(
            ClassicWoT.Config.Network.Prefix,
            Serializer:Serialize({event, object}),
            channel,
            target,
            prio)
end
