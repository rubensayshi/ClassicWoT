-- Libs
local LibStub = _G.LibStub

-- Addon global
local ClassicWoT = _G.ClassicWoT

-- deps
local AceGUI = LibStub("AceGUI-3.0")

-- WoW API
local date = _G.date

---@class ClassicWoTHistoryFrame
local ClassicWoTHistoryFrame = {}
ClassicWoTHistoryFrame.__index = ClassicWoTHistoryFrame
ClassicWoT.HistoryFrame = ClassicWoTHistoryFrame
setmetatable(ClassicWoTHistoryFrame, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTHistoryFrame.new(InteractionTracker, WoT, EventBus, EditFrame)
    local self = setmetatable({}, ClassicWoTHistoryFrame)

    self.InteractionTracker = InteractionTracker
    self.WoT = WoT
    self.EventBus = EventBus
    self.EditFrame = EditFrame
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

    local frame = AceGUI:Create("Window")
    frame:SetLayout("Flow")
    frame:SetTitle("Web of Trust")
    frame:SetWidth(500)
    frame:SetHeight(400)
    frame:SetCallback("OnClose", function(widget)
        widget:ReleaseChildren()
        widget:Release()
        _self.frame = nil
    end)

    local tabs = AceGUI:Create("TabGroup")
    tabs:SetLayout("Flow")
    tabs:SetFullWidth(true)
    tabs:SetFullHeight(true)
    tabs:SetTabs({
        {value = "TAB_GROUP_HISTORY", text = "Group History", },
        {value = "TAB_WOT", text = "Your WoT", },
    })
    tabs:SelectTab("TAB_GROUP_HISTORY")
    frame:AddChild(tabs)

    self.frame = frame
    self.tabs = tabs

    self:ShowGroupHistoryTab()

    -- trigger redraw of layout
    self.frame:DoLayout()
end

function ClassicWoTHistoryFrame:ShowGroupHistoryTab()
    local DUMMY = {
        ZONES = {
            "Dire Maul", "Deadmines", "Arathi Basin", "Westfall", "Ironforge", "Molten Core",
        },
        PLAYERS = {
            "Nub", "Yoda", "LukeSkycrawler", "Thrall", "YoMama",
        },
    }

    -- tab needs a container
    local frame = AceGUI:Create("SimpleGroup")
    frame:SetLayout("Flow")
    frame:SetFullWidth(true)
    frame:SetFullHeight(true)
    self.tabs:AddChild(frame)

    local scrolltainer = AceGUI:Create("SimpleGroup")
    scrolltainer:SetLayout("Fill") -- important! first child fills container
    scrolltainer:SetFullWidth(true)
    scrolltainer:SetFullHeight(true)
    frame:AddChild(scrolltainer)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scrolltainer:AddChild(scroll)

    for groupID, group in pairs(self.InteractionTracker:GetGroupHistory()) do
        local groupRow = AceGUI:Create("InlineGroup")

        -- @TODO: pretty print duration
        groupRow:SetTitle("Grouped with " .. ClassicWoT.table.cnt(group.dbEntry.players) .. " players " .. 
        "on " .. date("%A, %B %#d", group.dbEntry.started) .. " for " .. group:Duration() .. "ms")
        groupRow:SetLayout("Flow")
        groupRow:SetRelativeWidth(1.0)
        scroll:AddChild(groupRow)

        local zones = AceGUI:Create("SimpleGroup")
        zones:SetLayout("Flow")
        zones:SetRelativeWidth(1.0)
        groupRow:AddChild(zones)
        
        if (ClassicWoT.table.cnt(group.dbEntry.zones)) == 0 then
            local zoneLabel = AceGUI:Create("Label")
            zoneLabel:SetWidth(100)
            zoneLabel:SetText("Some zone")

            zones:AddChild(zoneLabel)
        end

        for _, zone in pairs(group.dbEntry.zones) do
            local zoneLabel = AceGUI:Create("Label")
            zoneLabel:SetWidth(100)
            zoneLabel:SetText(zone.name)

            zones:AddChild(zoneLabel)
        end

        local players = AceGUI:Create("SimpleGroup")
        players:SetLayout("Flow")
        players:SetRelativeWidth(1.0)
        groupRow:AddChild(players)

        for _, player in pairs(group.dbEntry.players) do
            local playerInfo = self.WoT:GetPlayerInfo(player.name)
            if playerInfo == nil then
                playerInfo = {
                    name = player.name,
                    score = nil,
                    note = "",
                }
            end

            local playerRow = AceGUI:Create("SimpleGroup")
            playerRow:SetLayout("Flow")
            playerRow:SetRelativeWidth(0.5)
            players:AddChild(playerRow)

            local player = AceGUI:Create("InteractiveLabel")
            player:SetWidth(100)
            player:SetText(playerInfo.name)
            playerRow:AddChild(player)

            local score = AceGUI:Create("InteractiveLabel")
            score:SetWidth(100)
            if playerInfo.score ~= nil then
                score:SetText("score: " .. playerInfo.score)
            else
                score:SetText("score: nil")
            end
            score:SetCallback("OnClick", function (button)
                ClassicWoT:DebugPrint("cliiiiick: " .. playerInfo.name)

                -- @TODO: can we get updates from edit frame to update the score here?
                self.EditFrame:ShowEditNoteFrame({
                    name = playerInfo.name,
                    score = playerInfo.score,
                    note = "",
                })

                -- attach the edit frame to the history frame
                self.EditFrame.frame.frame:SetPoint("TOPLEFT", self.frame.frame, "TOPRIGHT")
            end)
            playerRow:AddChild(score)
        end
    end

    -- trigger layout update to fix blank first row 
    scroll:DoLayout() 
end
