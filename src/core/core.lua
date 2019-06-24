-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local GetServerTime = _G.GetServerTime

---@class ClassicWoTCore
local ClassicWoTCore = {}
ClassicWoTCore.__index = ClassicWoTCore
ClassicWoT.Core = ClassicWoTCore

setmetatable(ClassicWoTCore, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTCore.new(player, realm)
    local self = setmetatable({}, ClassicWoTCore)

    self.InitMe(self, player, realm)

    return self
end

function ClassicWoTCore:InitMe(player, realm)
    ClassicWoT:DebugPrint("InitMe: " .. tostring(player)  .. ", " .. tostring(realm))
    if realm == nil then
        realm = "NaN"
    end

    self.realm = realm
    self.realme = self:PlayerFull(player, realm)
    self.me = self.realme
end

function ClassicWoTCore:PlayerFull(player, realm)
    if realm == nil then
        realm = self.realm
    end

    return player .. "-" .. realm
end

function ClassicWoTCore:Me()
    return self.me
end

function ClassicWoTCore:RealMe()
    return self.realme
end

function ClassicWoTCore:Now()
    return GetServerTime()
end
