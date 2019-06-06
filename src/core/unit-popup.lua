-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local UnitPopupMenus, UnitPopupButtons, UnitName, hooksecurefunc =
_G.UnitPopupMenus, _G.UnitPopupButtons, _G.UnitName, _G.hooksecurefunc

---@class ClassicWoTUnitPopup
---@field Core ClassicWoTCore
---@field WoT ClassicWoTWoT
---@field EditFrame ClassicWoTEditFrame
local ClassicWoTUnitPopup = {}
ClassicWoTUnitPopup.__index = ClassicWoTUnitPopup
ClassicWoT.UnitPopup = ClassicWoTUnitPopup

setmetatable(ClassicWoTUnitPopup, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTUnitPopup.new(Core, WoT, EditFrame)
    local self = setmetatable({}, ClassicWoTUnitPopup)

    self.Core = Core
    self.WoT = WoT
    self.EditFrame = EditFrame

    return self
end


function ClassicWoTUnitPopup:OnUnitPopupClick(unit, name)
    local playerFull
    if unit then
        ClassicWoT:DebugPrint("OnUnitPopupClick.unit: " .. unit)
        local playerName, playerRealm = UnitName(unit)
        playerFull = self.Core:PlayerFull(playerName, playerRealm)
    elseif name then
        -- @TODO: we get realm name here too?
        ClassicWoT:DebugPrint("OnUnitPopupClick.name: " .. name)
        playerFull = name
    end

    ClassicWoT:DebugPrint("OnUnitPopupClick.playerFull: " .. playerFull)

    local playerInfo = self.WoT:GetPlayerInfo(playerFull)
    if not playerInfo then
        playerInfo = {
            name = playerFull,
            score = ClassicWoT.Config.Score.Default,
            note = "",
        }
    end

    if playerInfo.score == nil then
        playerInfo.score = ClassicWoT.Config.Score.Default
    end

    self.EditFrame:ShowEditNoteFrame(playerInfo)
end

function ClassicWoTUnitPopup:AddToUnitPopupMenu()
    -- alias self to use it in event handlers
    local _self = self

    -- add our button to the list of possible buttons
    UnitPopupButtons["CWOT_EDIT"] = { text = "Edit WoT" }

    -- enable our button in the relevant menus
    local menus = {
        "PLAYER", -- non-party players
        "PARTY", -- party players
        "FRIEND", -- friends list
        "FRIEND_OFFLINE", -- friends list offline
        "RAID_PLAYER", -- raid screen
        "CHAT_ROSTER", -- ??
    }
    for _, menu in ipairs(menus) do
        table.insert(UnitPopupMenus[menu],
                #UnitPopupMenus[menu],
                "CWOT_EDIT")
    end

    -- add handler on ShowMenu so we can the click for the button
    hooksecurefunc("UnitPopup_ShowMenu", function(_, _, unit, name)
        for i = 1, _G.UIDROPDOWNMENU_MAXBUTTONS do
            local button = _G["DropDownList" .. _G.UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i]
            if button.value == "CWOT_EDIT" then
                button.func = function()
                    _self:OnUnitPopupClick(unit, name)
                end
            end
        end
    end)
end