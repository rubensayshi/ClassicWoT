-- Libs
local LibStub = _G.LibStub

-- Addon global
local ClassicWoT = _G.ClassicWoT

-- deps
local AGUI = LibStub("AceGUI-3.0")

---@class ClassicWoTHistoryFrame
local ClassicWoTHistoryFrame = {}
ClassicWoTHistoryFrame.__index = ClassicWoTHistoryFrame
ClassicWoT.HistoryFrame = ClassicWoTHistoryFrame
setmetatable(ClassicWoTHistoryFrame, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTHistoryFrame.new(EventBus)
    local self = setmetatable({}, ClassicWoTHistoryFrame)

    self.EventBus = EventBus
    self.frame = nil
    self.tabs = nil

    return self
end

function ClassicWoTHistoryFrame:Show()
    -- close currently open frame
    if self.frame then
        self.frame:Hide()
    end

    local _self = self

    local frame = AGUI:Create("Window")
    frame:SetLayout("Flow")
    frame:SetTitle("Web of Trust")
    frame:SetWidth(500)
    frame:SetHeight(400)
    frame:SetCallback("OnClose", function(widget)
        widget:ReleaseChildren()
        widget:Release()
        _self.frame = nil
    end)

    local tabs = AGUI:Create("TabGroup")
    tabs:SetLayout("Flow")
    tabs:SetFullWidth(true)
    tabs:SetFullHeight(true)
    tabs:SetTabs({
        {value = "TAB_GROUP_HISTORY", text = "Group History", },
    })
    tabs:SelectTab("TAB_GROUP_HISTORY")
    frame:AddChild(tabs)

    self.frame = frame
    self.tabs = tabs

    self:ShowTab()

    self.frame:DoLayout()
end

function ClassicWoTHistoryFrame:ShowTab()
    -- tab needs a container
    local frame = AGUI:Create("SimpleGroup")
    frame:SetLayout("Flow")
    frame:SetFullWidth(true)
    frame:SetFullHeight(true)
    self.tabs:AddChild(frame)

    local TABWIDTHS = {
        NAME = 0.5,
        REALM = 0.5,
    }

    local header = AGUI:Create("SimpleGroup")
    header:SetLayout("Flow")
    header:SetRelativeWidth(1.0)
    frame:AddChild(header)

    local playerNameHeader = AGUI:Create("Label")
    playerNameHeader:SetText("Player")
    playerNameHeader:SetRelativeWidth(TABWIDTHS.NAME)
    header:AddChild(playerNameHeader)

    local playerRealmHeader = AGUI:Create("Label")
    playerRealmHeader:SetText("Realm")
    playerRealmHeader:SetRelativeWidth(TABWIDTHS.REALM)
    header:AddChild(playerRealmHeader)

    local scrolltainer = AGUI:Create("SimpleGroup")
    scrolltainer:SetLayout("Fill") -- important! first child fills container
    scrolltainer:SetFullWidth(true)
    scrolltainer:SetFullHeight(true)
    frame:AddChild(scrolltainer)

    local scroll = AGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scrolltainer:AddChild(scroll)

    for i = 0, 40 do
        local playerRow = AGUI:Create("InlineGroup")
        playerRow:SetLayout("Flow")
        playerRow:SetRelativeWidth(1.0)
        scroll:AddChild(playerRow)

        local playerName = AGUI:Create("Label")
        playerName:SetText("Nub - NubVille")
        playerName:SetRelativeWidth(TABWIDTHS.NAME)
        playerRow:AddChild(playerName)

        local playerRealm = AGUI:Create("Label")
        playerRealm:SetText("NubVille")
        playerRealm:SetRelativeWidth(TABWIDTHS.REALM)
        playerRow:AddChild(playerRealm)
    end

    -- trigger layout update to fix blank first row 
    scroll:DoLayout()
    
end