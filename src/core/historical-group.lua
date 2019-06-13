-- Addon global
local ClassicWoT = _G.ClassicWoT

---@class ClassicWoTHistoricalGroup
local ClassicWoTHistoricalGroup = {}
ClassicWoTHistoricalGroup.__index = ClassicWoTHistoricalGroup
ClassicWoT.HistoricalGroup = ClassicWoTHistoricalGroup
setmetatable(ClassicWoTHistoricalGroup, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTHistoricalGroup.new(Core, groupID, dbEntry)
    local self = setmetatable({}, ClassicWoTHistoricalGroup)

    self.Core = Core
    self.groupID = groupID
    self.dbEntry = dbEntry

    return self
end

function ClassicWoTHistoricalGroup:IsActive()
    return self.dbEntry.ended == nil
end

function ClassicWoTHistoricalGroup:Duration()
    local ended = self.dbEntry.ended
    if ended == nil then
        ended = self.Core:Now()
    end

    return ended - self.dbEntry.started
end
