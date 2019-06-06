-- Addon global
local ClassicWoT = _G.ClassicWoT

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

    self.realm = realm
    self.realme = self:PlayerFull(player, realm)
    self.me = self.realme

    return self
end

function ClassicWoTCore:PlayerFull(name, realm)
    if realm == nil then
        realm = self.realm
    end

    return name .. "-" .. realm
end

function ClassicWoTCore:Me()
    return self.me
end

function ClassicWoTCore:RealMe()
    return self.realme
end
