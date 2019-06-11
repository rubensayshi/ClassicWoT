-- Libs
local LibStub = _G.LibStub

-- Addon global
---@class ClassicWoT
---@field Config ClassicWoTConfig
---@field Colors ClassicWoTColors
---@field Core ClassicWoTCore
---@field Network ClassicWoTNetwork
---@field EventBus ClassicWoTEventBus
---@field WoT ClassicWoTWoT
---@field InteractionTracker ClassicWoTInteractionTracker
---@field UnitPopup ClassicWoTUnitPopup
---@field Tooltip ClassicWoTTooltip
---@field SlashWho ClassicWoTSlashWho
---@field EditFrame ClassicWoTEditFrame
---@field HistoryFrame ClassicWoTHistoryFrame
ClassicWoT = LibStub("AceAddon-3.0"):NewAddon("ClassicWoT", "AceConsole-3.0")

function ClassicWoT:OnInitialize()
    self.DB = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)

    -- @TODO: these are related to the stuff in dev.lua...
    self:RegisterChatCommand("wot", "wot")
    self:RegisterChatCommand("wotreset", "wotreset")
    self:RegisterChatCommand("wothistory", "wothistory")
    self:RegisterChatCommand("wotiam", "wotiam")

    -- determine who we are
    local player, realm = UnitFullName("player")

    -- init components (should have minimal side effects)
    self.Core = ClassicWoT.Core(player, realm)
    self.EventBus = ClassicWoT.EventBus()
    self.Network = ClassicWoT.Network(self.Core, self.EventBus)
    self.WoT = ClassicWoT.WoT(self.Core, self.DB, self.Network, self.EventBus)
    self.InteractionTracker = ClassicWoT.InteractionTracker(self.Core, self.DB, self.EventBus, self.WoT)
    self.EditFrame = ClassicWoT.EditFrame(self.EventBus)
    self.HistoryFrame = ClassicWoT.HistoryFrame(self.EventBus)
    self.UnitPopup = ClassicWoT.UnitPopup(self.Core, self.WoT, self.EditFrame)
    self.Tooltip = ClassicWoT.Tooltip(self.Core, self.WoT)
    self.SlashWho = ClassicWoT.SlashWho(self.Core, self.WoT)

    self:DebugPrint("me: " .. self.Core:RealMe())
end

function ClassicWoT:OnEnable()
    -- debug print, will also help us know if debugging is enabled
    self:DebugPrint("ClassicWoT:OnEnable")

    -- init the chat channel we use for "networking"
    self.Network:InitChannel()

    -- add ourselves to the unit popup menu (right click menu)
    self.UnitPopup:AddToUnitPopupMenu()

    -- add ourselves to unit tooltips
    self.Tooltip:Hook()

    -- watch /who results
    self.SlashWho:Hook()
end
