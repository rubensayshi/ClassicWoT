-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local GameTooltip, IsShiftKeyDown, UnitName =
_G.GameTooltip, _G.IsShiftKeyDown, _G.UnitName

---@class ClassicWoTTooltip
---@field Core ClassicWoTCore
---@field WoT ClassicWoTWoT
local ClassicWoTTooltip = {}
ClassicWoTTooltip.__index = ClassicWoTTooltip
ClassicWoT.Tooltip = ClassicWoTTooltip

setmetatable(ClassicWoTTooltip, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTTooltip.new(Core, WoT)
    local self = setmetatable({}, ClassicWoTTooltip)

    self.Core = Core
    self.WoT = WoT

    return self
end

function ClassicWoTTooltip:Hook()
    -- alias self to use it in event handlers
    local _self = self

    -- bind to OnTooltipSetUnit event
    GameTooltip:HookScript("OnTooltipSetUnit", function(...)
        _self:OnTooltipSetUnit(...)
    end)
end

function ClassicWoTTooltip:OnTooltipSetUnit()
    local _, playerUnitID = GameTooltip:GetUnit()
    if playerUnitID == nil then
        return
    end

    local playerFull = self.Core:PlayerFull(UnitName(playerUnitID))
    if playerFull == nil then
        return
    end

    -- don't add WoT to own tooltip
    if playerFull == self.Core:RealMe() then
        return
    end

    ClassicWoT:DebugPrint("ToolTip: " .. playerFull .. " sdown: " .. tostring(IsShiftKeyDown()))

    local playerInfo = self.WoT:GetPlayerInfo(playerFull)
    if playerInfo == nil then
        ClassicWoT:DebugPrint(playerFull .. " not known")
        return
    end

    if playerInfo.score ~= nil then
        GameTooltip:AddLine("|cffffffffin our WoT, score: " .. playerInfo.score .. ", note: " .. playerInfo.note)
    end

    if ClassicWoT.table.cnt(playerInfo.opinions) == 0 then
        --
    else
        local cnt, sum, minn, maxx = ClassicWoT.table.cntsumminmax(playerInfo.opinions, function(opinion)
            return opinion.score
        end)

        GameTooltip:AddLine("|cffffffff" ..
                string.format("%s known by %d in our WoT, min: %d max: %d avg: %.1f",
                        playerInfo.name, cnt, minn, maxx, sum / cnt))

        -- @TODO: is not toggling when pressed while mouse over
        if IsShiftKeyDown() then
            for sender, opinion in pairs(playerInfo.opinions) do
                GameTooltip:AddLine("|cffffffff" ..
                        " - " .. sender .. ", score: " .. opinion.score)
            end
        end
    end

    -- do we really need this, to adjust the height?
    -- GameTooltip:Show()
end