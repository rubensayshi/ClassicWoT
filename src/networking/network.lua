--[[
Networking code from https://github.com/DomenikIrrgang/ClassicLFG released under MIT.
Copyright (c) 2019 Domenik Irrgang

ClassicWoTNetwork will receive messages over Addon channels and broadcast them as events once received fully.
Objects sent are serialized and chunked to fit max size of messages.

@TODO: replace with AceComm-3.0
--]]
-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local CreateFrame, C_ChatInfo, JoinChannelByName, GetChannelList =
_G.CreateFrame, _G.C_ChatInfo, _G.JoinChannelByName, _G.GetChannelList

-- Libs
local LibStub = _G.LibStub
local Serializer = LibStub:GetLibrary("AceSerializer-3.0")

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

    -- create a Frame to use as thread to recieve messages on
    self.NetworkThread = CreateFrame("Frame")
    self.NetworkThread:SetScript("OnUpdate", function()
        --print("Network Thread invoked!")
    end)
    self.NetworkThread:RegisterEvent("CHAT_MSG_ADDON")
    self.NetworkThread:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
    self.NetworkThread:SetScript("OnEvent", function(_, event, ...)
        if (event == "CHAT_MSG_ADDON" or event == "CHAT_MSG_ADDON_LOGGED") then
            self:HandleAddonMessage(...)
        end
    end)

    -- register our prefix for addon messages
    C_ChatInfo.RegisterAddonMessagePrefix(ClassicWoT.Config.Network.Prefix)

    return self
end

function ClassicWoTNetwork:InitChannel()
    -- @TODO: do we need this when we're using C_ChatInfo.RegisterAddonMessagePrefix? there's a limit ...
    -- @TODO: can't we simply send over "world" or something?
    JoinChannelByName(ClassicWoT.Config.Network.Channel.Name)
    local channels = { GetChannelList() }
    local i = 2
    while i < #channels do
        if (channels[i] == ClassicWoT.Config.Network.Channel.Name) then
            ClassicWoT.Config.Network.Channel.Id = channels[i - 1]
            break
        end
        i = i + 3
    end
end

function ClassicWoTNetwork:HandleAddonMessage(...)
    local prefix, message, _, sender = ...

    -- so we can pretend to be somebody else
    if sender == self.Core:RealMe() then
        sender = self.Core:Me()
    end

    -- @TODO: does sender always include server?
    if (prefix:find(ClassicWoT.Config.Network.Prefix) and sender ~= self.Core:RealMe()) then
        local headers, content = self:SplitNetworkPackage(message)
        self.MessageBuffer[headers.Hash] = self.MessageBuffer[headers.Hash] or {}
        self.MessageBuffer[headers.Hash][headers.Order] = content

        -- manage count of chunks
        if (self.MessageBuffer[headers.Hash]["count"] ~= nil and self.MessageBuffer[headers.Hash]["count"] >= 1) then
            self.MessageBuffer[headers.Hash]["count"] = self.MessageBuffer[headers.Hash]["count"] + 1
        else
            self.MessageBuffer[headers.Hash]["count"] = 1
        end

        -- if this was the final chunk we can process it
        if (self.MessageBuffer[headers.Hash]["count"] == tonumber(headers.TotalCount)) then
            local _, object = Serializer:Deserialize(self:MergeMessages(headers, self.MessageBuffer[headers.Hash]))

            ClassicWoT:TracePrint("Network Package from " .. sender .. " complete! Event: " .. object.Event)

            self.MessageBuffer[headers.Hash] = nil
            self.EventBus:PublishEvent(object.Event, object.Payload, sender)
        end
    end
end

function ClassicWoTNetwork:SendObject(event, object, channel, target)
    -- default to using the configured channel ID
    if channel == "CHANNEL" and target == nil then
        target = ClassicWoT.Config.Network.Channel.Id
    end

    ClassicWoT:TracePrint("Network Event Send")
    ClassicWoT:TracePrint("Event: " .. event .. " Channel: " .. channel)
    self:SendMessage(ClassicWoT.Config.Network.Prefix, Serializer:Serialize({ Event = event, Payload = object }), channel, target)
end

function ClassicWoTNetwork:SendMessage(prefix, message, channel, target)
    local messages = self:SplitMessage(message)
    for key in pairs(messages) do
        C_ChatInfo.SendAddonMessage(prefix, messages[key], channel, target)
    end
end

function ClassicWoTNetwork:MergeMessages(headers, messages)
    local tmp = ""
    for i = 1, tonumber(headers.TotalCount) do
        tmp = tmp .. messages[tostring(i)]
    end
    return tmp
end

function ClassicWoTNetwork:SplitMessage(message)
    local messages = {}
    local hash = self.RandomHash(8)
    -- Note: -3 for Splitting Characters in protocol and -2 for MessageCount and TotalCount and - hashlength
    local maxSize = 255 - 3 - 2 - hash:len()
    local totalCount = math.ceil(message:len() / maxSize)
    if (totalCount >= 10) then
        -- Note: -9 for Messages with Count < 10 and -2 for for increased Size of MessageCount and TotalCount
        totalCount = math.ceil((message:len() - 9) / (maxSize - 2))
    end
    local index = 1
    local messageCount = 1
    while (index < message:len()) do
        local headers = self:CreatePackageHeaders(messageCount, hash, totalCount)
        local content = message:sub(index, (index - 1) + 255 - headers.Length)
        table.insert(messages, self:CreateNetworkPackage(headers, content))
        index = index + content:len()
        messageCount = messageCount + 1
    end
    return messages
end

function ClassicWoTNetwork:CreatePackageHeaders(messageCount, hash, totalCount)
    return { Order = messageCount, Hash = hash, TotalCount = totalCount, Length = 3 + hash:len() + tostring(messageCount):len() + tostring(totalCount):len() }
end

function ClassicWoTNetwork:CreateNetworkPackage(headers, content)
    local header = headers.Hash .. "\a" .. headers.Order .. "\a" .. headers.TotalCount .. "\a"
    return header .. content
end

function ClassicWoTNetwork:SplitNetworkPackage(package)
    local splitPackage = package:SplitString("\a")
    local headers = self:CreatePackageHeaders(splitPackage[2], splitPackage[1], splitPackage[3])
    local content = splitPackage[4]
    return headers, content
end

function ClassicWoTNetwork.RandomHash(length)
    return ClassicWoT.RandomHash(length)
end
