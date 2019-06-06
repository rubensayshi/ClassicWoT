local ClassicWoT = _G.ClassicWoT

---@class ClassicWoTEventBus
local ClassicWoTEventBus = {}
ClassicWoTEventBus.__index = ClassicWoTEventBus

ClassicWoT.EventBus = ClassicWoTEventBus

setmetatable(ClassicWoTEventBus, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTEventBus.new()
    local self = setmetatable({}, ClassicWoTEventBus)
    self.Listeners = {}
    return self
end

function ClassicWoTEventBus:RegisterCallback(event, object, callback)
    if (self.Listeners[event] == nil) then
        self.Listeners[event] = {}
    end
    table.insert(self.Listeners[event], { Object = object, Callback = callback })
end

function ClassicWoTEventBus:PublishEvent(event, ...)
    ClassicWoT:TracePrint("Event published: " .. event)
    if (self.Listeners[event] ~= nil) then
        for key in pairs(self.Listeners[event]) do
            self.Listeners[event][key].Callback(self.Listeners[event][key].Object, ...)
        end
    end
end