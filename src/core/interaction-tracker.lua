-- Addon global
local ClassicWoT = _G.ClassicWoT

-- Consts
local CURRENT_GROUP = ClassicWoT.Config.CURRENT_GROUP

-- WoW API
local CreateFrame, GetNumGroupMembers, GetRealZoneText, GetRaidRosterInfo =
_G.CreateFrame, _G.GetNumGroupMembers, _G.GetRealZoneText, _G.GetRaidRosterInfo

---@class ClassicWoTInteractionTracker
---@field DB table<string, table>
---@field Core ClassicWoTCore
---@field EventBus ClassicWoTEventBus
---@field WoT ClassicWoTWoT
---@field CurrentGroup ClassicWoTCurrentGroup
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

    self.CurrentGroup = ClassicWoT.CurrentGroup(self.Core, DB.char.groupHistory[CURRENT_GROUP])

    -- reset the current group if there was still info pending from previous session
    -- @TODO: how do we determine the ended time if we disconnected while in a group and got back online and were out
    if GetNumGroupMembers() == 0 then
        self:ResetCurrentGroup()
    else
        -- @TODO: we need to sync
        -- self:OnGroupRosterUpdate()
    end

    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    -- self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- login(ish) event
    -- self.Frame:RegisterEvent("PLAYER_LEAVING_WORLD") -- logout(ish) event
    self.Frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    -- self.Frame:RegisterEvent("CHAT_MSG_SYSTEM")

    self.Frame:SetScript("OnEvent", function(_, event, ...)
        if (event == "GROUP_ROSTER_UPDATE") then
            ClassicWoT:DebugPrint("GROUP_ROSTER_UPDATE")
            self:OnGroupRosterUpdate(...)
        elseif (event == "ZONE_CHANGED_NEW_AREA") then
            ClassicWoT:DebugPrint("ZONE_CHANGED_NEW_AREA")
            self:OnZoneChangedNewArea(...)
        end
    end)

    return self
end

---@return ClassicWoTHistoricalGroup[]
function ClassicWoTInteractionTracker:GetGroupHistory()
    local groups = {}

    if not self.CurrentGroup:IsNew() then
        table.insert(groups, ClassicWoT.HistoricalGroup(self.Core, CURRENT_GROUP, self.DB.char.groupHistory[CURRENT_GROUP]))
    end

    for groupID = 1, self.DB.char.groupHistoryCount do
        print(groupID)
        local dbEntry = self.DB.char.groupHistory[groupID]
        table.insert(groups, ClassicWoT.HistoricalGroup(self.Core, groupID, dbEntry))
    end

    return groups
end

function ClassicWoTInteractionTracker:ResetCurrentGroup()
    ClassicWoT:DebugPrint("ResetCurrentGroup")
    -- need to wrap up the previous group
    if not self.CurrentGroup:IsNew() then
        self.CurrentGroup:Ended()

        -- increment our counter, and use the counter as ID for the group
        self.DB.char.groupHistoryCount = self.DB.char.groupHistoryCount + 1
        local groupID = self.DB.char.groupHistoryCount

        -- copy the dbEntry into the history
        self.DB.char.groupHistory[groupID] = self.CurrentGroup.dbEntry
    end

    -- reset DB record, AceDB will make it default values again when we access it
    self.DB.char.groupHistory[CURRENT_GROUP] = nil

    -- reset in memory wrapper
    self.CurrentGroup:Reset(self.DB.char.groupHistory[CURRENT_GROUP])
end

function ClassicWoTInteractionTracker:OnGroupRosterUpdate()
    -- we are part of GetNumGroupMembers(),
    -- so numMembers 0 -> 1 is when we /inv somebody but before they accept
    -- so numMembers 1 -> 2 is when they accept
    -- and numMembers 0 -> 2 is when we join a group
    local numMembers = GetNumGroupMembers()

    ClassicWoT:DebugPrint("numMembers: " .. numMembers)
    ClassicWoT:DebugPrint("DBnumMembers: " .. self.CurrentGroup:NumMembers())

    -- check if we left / disbanded a group
    if numMembers == 0 and self.CurrentGroup:NumMembers() > 1 then
        ClassicWoT:DebugPrint("Disbanded Group")
        self:ResetCurrentGroup()

        -- or if we joined / formed a new group
    elseif numMembers > 1 and self.CurrentGroup:NumMembers() == 0 then
        ClassicWoT:DebugPrint("Joined/Formed New Group")
        -- reset any old trace of a group
        self:ResetCurrentGroup()

        -- mark the group as started
        self.CurrentGroup:Started()

        for i = 1, numMembers do
            local playerName = GetRaidRosterInfo(i)
            local playerFull = self.Core:PlayerFull(playerName)

            if playerFull ~= self.Core:RealMe() then
                ClassicWoT:DebugPrint(playerFull .. " is in the group")

                if self.CurrentGroup:PlayerJoined(playerFull) then
                    self:PlayerMet(playerFull)
                end
            end
        end

        -- or if somebody joined our existing group
    elseif numMembers > 1 then
        ClassicWoT:DebugPrint("Somebody Joined Existing Group")

        for i = 1, numMembers do
            local playerName = GetRaidRosterInfo(i)
            local playerFull = self.Core:PlayerFull(playerName)

            if playerFull ~= self.Core:RealMe() then
                ClassicWoT:DebugPrint(playerFull .. " joined our group")

                if self.CurrentGroup:SyncPlayer(playerFull) then
                    self:PlayerMet(playerFull)
                end
            end
        end
    end
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

function ClassicWoTInteractionTracker:OnZoneChangedNewArea()
    -- @TODO: wiki says this is unreliable, need to test and otherwise find 
    local zone = GetRealZoneText()

    ClassicWoT:DebugPrint("OnZoneChangedNewArea: " .. zone)

    -- no reason to track zones when we're not really in a group
    if self.CurrentGroup:IsNew() then
        return
    end

    self.CurrentGroup:ZoneEntered(zone)
end
