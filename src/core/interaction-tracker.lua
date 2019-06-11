-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local CreateFrame, GetNumGroupMembers, GetTime, GetRaidRosterInfo =
_G.CreateFrame, _G.GetNumGroupMembers, _G.GetTime, _G.GetRaidRosterInfo

---@class ClassicWoTInteractionTracker
---@field DB table<string, table>
---@field Core ClassicWoTCore
---@field EventBus ClassicWoTEventBus
---@field WoT ClassicWoTWoT
local ClassicWoTInteractionTracker = {}
ClassicWoTInteractionTracker.__index = ClassicWoTInteractionTracker
ClassicWoT.InteractionTracker = ClassicWoTInteractionTracker
setmetatable(ClassicWoTInteractionTracker, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTInteractionTracker.new(Core, DB, EventBus, WoT)
    local self = setmetatable({}, ClassicWoTInteractionTracker)

    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus
    self.WoT = WoT

    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    -- self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- self.Frame:RegisterEvent("PLAYER_LEAVING_WORLD")
    -- self.Frame:RegisterEvent("CHAT_MSG_SYSTEM")

    self.Frame:SetScript("OnEvent", function(_, event, ...)
        if (event == "GROUP_ROSTER_UPDATE") then
            ClassicWoT:DebugPrint("GROUP_ROSTER_UPDATE")
            self:OnGroupRosterUpdate(...)
        end
    end)

    -- @TODO: we need to deal with disconnecting while in a party

    return self
end

function ClassicWoTInteractionTracker:ResetParty()
    -- @TODO: can we simply self.DB.char.party = nil?

    for playerName in pairs(self.DB.char.party) do
        self.DB.char.party[playerName] = nil
    end

    self.DB.char.party.numMembers = 0
    self.DB.char.party.started = nil
end

function ClassicWoTInteractionTracker:OnGroupRosterUpdate()
    -- we are part of GetNumGroupMembers(),
    -- so numMembers 0 -> 1 is when we /inv somebody but before they accept
    -- so numMembers 1 -> 2 is when they accept
    -- and numMembers 0 -> 2 is when we join a party
    local numMembers = GetNumGroupMembers()

    ClassicWoT:DebugPrint("numMembers: " .. numMembers)
    ClassicWoT:DebugPrint("DBnumMembers: " .. self.DB.char.party.numMembers)

    -- check if we left / disbanded a party
    if numMembers == 0 and self.DB.char.party.numMembers > 1 then
        -- @TODO: wrap it up

        self:ResetParty()

        -- or if we joined / formed a new party
    elseif numMembers > 1 and self.DB.char.party.numMembers == 0 then
        self:ResetParty()
        self.DB.char.party.started = GetTime()

        for i = 1, numMembers do
            local playerName = GetRaidRosterInfo(i)
            local playerFull = self.Core:PlayerFull(playerName)

            if playerFull ~= self.Core:RealMe() then
                ClassicWoT:DebugPrint(playerFull .. " is in the party")

                self.DB.char.party[playerFull].name = playerFull
                self.DB.char.party[playerFull].joined = GetTime()

                self:PlayerMet(playerFull)
            end
        end

        -- or if somebody joined our existing party
    elseif numMembers > 1 then
        for i = 1, numMembers do
            local playerName = GetRaidRosterInfo(i)
            local playerFull = self.Core:PlayerFull(playerName)

            if playerFull ~= self.Core:RealMe() then
                ClassicWoT:DebugPrint(playerFull .. " joined our party")

                -- check if this person is new
                if self.DB.char.party[playerFull].name == nil then

                    self.DB.char.party[playerFull].name = playerFull
                    self.DB.char.party[playerFull].joined = GetTime()

                    self:PlayerMet(playerFull)
                end
            end
        end
    end

    self.DB.char.party.numMembers = numMembers
end

function ClassicWoTInteractionTracker:PlayerMet(playerFull)
    if playerFull == self.Core:RealMe() then
        return
    end

    local player = self.WoT:GetPlayerInfo(playerFull)
    if player ~= nil then
        if player.score ~= nil then
            ClassicWoT:Print(player.name .. " in our WoT, score: " .. player.score .. ", note: " .. player.note)
        end

        if ClassicWoT.table.cnt(player.opinions) == 0 then
            ClassicWoT:Print(player.name .. " not known by WoT")
        else
            local cnt, sum, minn, maxx = ClassicWoT.table.cntsumminmax(player.opinions, function(opinion)
                return opinion.score
            end)

            self:Print(string.format("%s known by %d in our WoT, min: %d max: %d avg: %.1f, opinions: ",
                    player.name, cnt, minn, maxx, sum / cnt))

            for sender, opinion in pairs(player.opinions) do
                ClassicWoT:Print(" - " .. sender .. ", score: " .. opinion.score)
            end
        end
    end
end