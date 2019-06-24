-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local CreateFrame = _G.CreateFrame

---@class ClassicWoTWoT
---@field DB table<string, table>
---@field Core ClassicWoTCore
---@field Network ClassicWoTNetwork
local ClassicWoTWoT = {}
ClassicWoTWoT.__index = ClassicWoTWoT
ClassicWoT.WoT = ClassicWoTWoT
setmetatable(ClassicWoTWoT, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTWoT.new(Core, DB, Network, EventBus)
    local self = setmetatable({}, ClassicWoTWoT)

    self.Core = Core
    self.DB = DB
    self.Network = Network

    -- @TODO: do we need the frame?
    self.Frame = CreateFrame("Frame")
    self.Frame:SetScript("OnEvent", function()
    end)

    -- subscribe to network events
    EventBus:RegisterCallback(ClassicWoT.Config.Network.Events.SetScore, self, self.OnReceiveScore)
    EventBus:RegisterCallback(ClassicWoT.Config.Network.Events.RequestScores, self, self.OnScoresRequested)
    -- subscribe to local events
    EventBus:RegisterCallback(ClassicWoT.Config.Events.SetPlayerInfo, self, self.OnSetPlayerInfo)

    return self
end

function ClassicWoTWoT:GetPlayerInfo(playerFull)
    if self.DB.realm.wot[playerFull].name == nil then
        -- AceDB will initialize the entry with defaults, 
        -- we need to unset to avoid lots of unused entries
        self.DB.realm.wot[playerFull] = nil
        return nil
    else
        return self.DB.realm.wot[playerFull]
    end
end

function ClassicWoTWoT:GetPlayers()
    return self.DB.realm.wot
end

function ClassicWoTWoT:IsTrusted(playerFull)
    local playerInfo = self:GetPlayerInfo(playerFull)

    return playerInfo ~= nil and
            playerInfo.score ~= nil
            and playerInfo.score >= ClassicWoT.Config.Score.Trusted
end

function ClassicWoTWoT:OnSetPlayerInfo(data)
    self:SetPlayerScore(data.name, data.score)
    if data.note ~= nil then
        self:SetPlayerNote(data.name, data.note)
    end

    ClassicWoT:PPrint(data.name .. " added to your WoT with score: " .. data.score)
end

function ClassicWoTWoT:SetPlayerScore(name, score)
    local wasTrusted = self:IsTrusted(name)

    -- sanity check that provided score is a number
    score = tonumber(score)
    if score == nil then
        self:DebugPrint("SetPlayerScore: invalid score, not a number")
        return
    end

    self.DB.realm.wot[name].name = name
    self.DB.realm.wot[name].score = score

    -- @TODO: should WHISPER to our WoT instead of CHANNEL
    self.Network:SendObject(ClassicWoT.Config.Network.Events.SetScore, { name = name, score = score }, "CHANNEL")

    -- if their trust level changed then we should should update our DB
    if not wasTrusted and self:IsTrusted(name) then
        -- @TODO: ask for their opinions
        self.Network:SendObject(ClassicWoT.Config.Network.Events.RequestScores, true, "WHISPER", name)
    elseif wasTrusted and not self:IsTrusted(name) then
        -- @TODO: remove their opinions
    end
end

function ClassicWoTWoT:SetPlayerNote(name, note)
    self.DB.realm.wot[name].name = name
    self.DB.realm.wot[name].note = note
end

function ClassicWoTWoT:OnReceiveScore(object, sender)
    -- sanity check on the object
    if object == nil or object.name == nil or object.score == nil then
        return
    end

    ClassicWoT:DebugPrint(string.format("Received score from %s for %s, score: %d trusted: %s",
            sender, object.name, object.score, tostring(self:IsTrusted(sender))))

    if self:IsTrusted(sender) then
        -- @TODO: should we ensure 1 person doesn't flood our DB?

        -- store their opinion
        local playerInfo = self.DB.realm.wot[object.name]
        playerInfo.name = object.name
        playerInfo.opinions[sender].score = object.score

        for k, v in pairs(playerInfo.opinions) do
            ClassicWoT:DebugPrint(" - opinion: " .. k .. ": " .. v.score)
        end

        ClassicWoT:DebugPrint(playerInfo.name .. " opinions: " .. ClassicWoT.table.cnt(playerInfo.opinions))
    else
        -- they trust us enough to send us their scores <3
        -- but we don't trust them, we can stash the score in case we do trust them in the future?
    end
end

function ClassicWoTWoT:OnScoresRequested(_, sender)
    ClassicWoT:DebugPrint(string.format("Score requested by %s, trusted: %s",
            sender, tostring(self:IsTrusted(sender))))

    if self:IsTrusted(sender) then
        -- send them our scores
        for name, player in pairs(self.DB.realm.wot) do
            if player.score ~= nil then
                self.Network:SendObject(ClassicWoT.Config.Network.Events.SetScore, { name = name, score = player.score }, "WHISPER", sender)
            end
        end
    else
        -- we don't trust them enough to send them our scores :/
    end
end
