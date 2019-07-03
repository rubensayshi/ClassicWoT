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
    self.realme = player
    self.me = self.realme
end

function ClassicWoTCore:PlayerFull(player, realm)
    if realm == nil then
        realm = self.realm
    end

    return player .. "-" .. realm
end

function ClassicWoTCore:IsMyRealm(realm)
    return realm == nil or realm == self.realm
end

function ClassicWoTCore:MyRealm()
    return self.realm
end

function ClassicWoTCore:Me()
    return self.me
end

function ClassicWoTCore:RealMe()
    return self.realme
end

function ClassicWoTCore:FullMe()
    return self:PlayerFull(self.me)
end

function ClassicWoTCore:FullRealMe()
    return self:PlayerFull(self.realme)
end

function ClassicWoTCore:SplitFullPlayer(fullPlayer)
    local splt = ClassicWoT.SplitString(fullPlayer, "-")

    return splt[1], splt[2]
end

function ClassicWoTCore:NormalizeFullPlayer(fullPlayer)
    local name, realm = self:SplitFullPlayer(fullPlayer)

    return self:PlayerFull(name, realm)
end

function ClassicWoTCore:Now()
    return GetServerTime()
end
