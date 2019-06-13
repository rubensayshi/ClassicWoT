-- Addon global
local ClassicWoT = _G.ClassicWoT

---@class ClassicWoTCurrentGroup
local ClassicWoTCurrentGroup = {}
ClassicWoTCurrentGroup.__index = ClassicWoTCurrentGroup
ClassicWoT.CurrentGroup = ClassicWoTCurrentGroup
setmetatable(ClassicWoTCurrentGroup, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTCurrentGroup.new(Core, dbEntry)
    local self = setmetatable({}, ClassicWoTCurrentGroup)

    self.Core = Core
    self.dbEntry = dbEntry

    return self
end

function ClassicWoTCurrentGroup:Reset(dbEntry)
    self.dbEntry = dbEntry
end

function ClassicWoTCurrentGroup:IsNew()
    return self.dbEntry.started == nil
end

function ClassicWoTCurrentGroup:NumMembers()
    return self.dbEntry.numMembers
end

function ClassicWoTCurrentGroup:Started(time)
    if time == nil then
        time = self.Core:Now()
    end

    self.dbEntry.started = time
    self.dbEntry.numMembers = 1 -- self
end

function ClassicWoTCurrentGroup:Ended(time)
    if time == nil then
        time = self.Core:Now()
    end

    self.dbEntry.ended = time
    self.dbEntry.numMembers = 0
end

function ClassicWoTCurrentGroup:SyncPlayer(playerFull, time)
    ClassicWoT:DebugPrint("SyncPlayer(" .. playerFull .. ")")
    -- check if this person is new
    if self.dbEntry.players[playerFull].name == nil then
        return self:PlayerJoined(playerFull, time)
    end

    return false
end

function ClassicWoTCurrentGroup:PlayerJoined(playerFull, time)
    if time == nil then
        time = self.Core:Now()
    end

    self.dbEntry.players[playerFull].name = playerFull
    self.dbEntry.players[playerFull].joined = time

    self.dbEntry.numMembers = self.dbEntry.numMembers + 1

    return true
end

function ClassicWoTCurrentGroup:PlayerLeft(playerFull, time)
    if time == nil then
        time = self.Core:Now()
    end

    -- this should never happen ...
    if self.dbEntry.players[playerFull].name == nil then
        ClassicWoT:DebugPrint("PlayerLeft(" .. playerFull .. "), but was never in our group ...")
        return false
    end

    -- add the time since joined to our total time tracked
    local timeInGroup = time - self.dbEntry.players[playerFull].joined
    self.dbEntry.players[playerFull].totalTime = self.dbEntry.players[playerFull].totalTime + timeInGroup
    -- reset joined
    self.dbEntry.players[playerFull].joined = nil

    self.dbEntry.numMembers = self.dbEntry.numMembers - 1

    return true
end

function ClassicWoTCurrentGroup:ZoneEntered(zone, time)
    if time == nil then
        time = self.Core:Now()
    end

    -- @TODO: we need the zone when group is created
    if self.dbEntry.currentZone ~= nil then
        self:ZoneLeft(self.dbEntry.currentZone, time)
    end

    self.dbEntry.zones[zone].name = zone
    self.dbEntry.zones[zone].joined = time

    self.dbEntry.currentZone = zone
end

function ClassicWoTCurrentGroup:ZoneLeft(zone, time)
    if time == nil then
        time = self.Core:Now()
    end

    -- add the time since entered to our total time tracked
    local timeInZone = time - self.dbEntry.zones[zone].joined
    self.dbEntry.zones[zone].totalTime = self.dbEntry.zones[zone].totalTime + timeInZone
    -- reset joined
    self.dbEntry.zones[zone].joined = nil
end

