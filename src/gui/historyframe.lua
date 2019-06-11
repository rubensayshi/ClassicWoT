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

function ClassicWoTHistoryFrame.new(EventBus, EditFrame)
    local self = setmetatable({}, ClassicWoTHistoryFrame)

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
    local DUMMY = {
        ZONES = {
            "Dire Maul", "Deadmines", "Arathi Basin", "Westfall", "Ironforge", "Molten Core",
        },
        PLAYERS = {
            "Nub", "Yoda", "LukeSkycrawler", "Thrall", "YoMama",
        },
    }

    -- tab needs a container
    local frame = AGUI:Create("SimpleGroup")
    frame:SetLayout("Flow")
    frame:SetFullWidth(true)
    frame:SetFullHeight(true)
    self.tabs:AddChild(frame)

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
        local groupRow = AGUI:Create("InlineGroup")
        groupRow:SetTitle("Grouped with x people from YYYY-MM-DD HH:II:SS till HH:II:SS")
        groupRow:SetLayout("Flow")
        groupRow:SetRelativeWidth(1.0)
        scroll:AddChild(groupRow)

        local zones = AGUI:Create("SimpleGroup")
        zones:SetLayout("Flow")
        zones:SetRelativeWidth(1.0)
        groupRow:AddChild(zones)
        
        for i = 1, 6 do
            local zone = AGUI:Create("Label")
            zone:SetWidth(100)
            zone:SetText(DUMMY.ZONES[i])

            zones:AddChild(zone)
        end

        local players = AGUI:Create("SimpleGroup")
        players:SetLayout("Flow")
        players:SetRelativeWidth(1.0)
        groupRow:AddChild(players)

        for i = 1, 5 do
            local data = {
                name = DUMMY.PLAYERS[i],
                score = 4,
                note = "",
            }

            if i == 1 then
                data.score = nil
            end

            local playerRow = AGUI:Create("SimpleGroup")
            playerRow:SetLayout("Flow")
            playerRow:SetRelativeWidth(0.5)
            players:AddChild(playerRow)

            local player = AGUI:Create("InteractiveLabel")
            player:SetWidth(100)
            player:SetText(DUMMY.PLAYERS[i])
            playerRow:AddChild(player)

            local score = AGUI:Create("InteractiveLabel")
            score:SetWidth(100)
            if data.score ~= nil then
                score:SetText("score: " .. data.score)
            else
                score:SetText("score: nil")
            end
            score:SetCallback("OnClick", function (button)
                ClassicWoT:DebugPrint("cliiiiick: " .. i .. "; " .. DUMMY.PLAYERS[i])

                self.EditFrame:ShowEditNoteFrame({
                    name = DUMMY.PLAYERS[i],
                    score = data.score,
                    note = "",
                })
            end)
            playerRow:AddChild(score)
        end
    end

    -- trigger layout update to fix blank first row 
    scroll:DoLayout() 
end
