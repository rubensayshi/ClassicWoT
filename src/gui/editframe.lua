-- Libs
local LibStub = _G.LibStub

-- Addon global
local ClassicWoT = _G.ClassicWoT

-- deps
local AGUI = LibStub("AceGUI-3.0")

---@class ClassicWoTEditFrame
local ClassicWoTEditFrame = {}
ClassicWoTEditFrame.__index = ClassicWoTEditFrame
ClassicWoT.EditFrame = ClassicWoTEditFrame
setmetatable(ClassicWoTEditFrame, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTEditFrame.new(EventBus)
    local self = setmetatable({}, ClassicWoTEditFrame)

    self.EventBus = EventBus
    self.frame = nil

    return self
end

function ClassicWoTEditFrame:ShowEditNoteFrame(data)
    -- close currently open frame
    if self.frame then
        self.frame:Hide()
    end

    local _self = self

    if data.score == nil then
        data.score = ClassicWoT.Config.Score.Default
    end

    local frame = AGUI:Create("Window")
    frame:SetTitle("Edit WoT")
    frame:SetWidth(300)
    frame:SetHeight(250)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        widget:ReleaseChildren()
        widget:Release()
        _self.frame = nil
    end)

    local title = AGUI:Create("Label")
    title:SetFullWidth(true)
    title:SetText(data.name)
    title:SetFont(_G.GameFontNormalLarge:GetFont())
    title.label:SetJustifyH("CENTER")
    frame:AddChild(title)

    local score = AGUI:Create("Slider")
    score:SetFullWidth(true)
    score:SetLabel("Score")
    score.label:SetJustifyH("LEFT")
    score:SetValue(data.score)
    score:SetSliderValues(ClassicWoT.Config.Score.Min, ClassicWoT.Config.Score.Max, 1)
    frame:AddChild(score)

    local note = AGUI:Create("MultiLineEditBox")
    note:SetFullWidth(true)
    note:SetLabel("Note")
    note:SetText(data.note)
    note:SetNumLines(5)
    note:SetMaxLetters(0)
    note:SetFocus()
    note:DisableButton(true)
    frame:AddChild(note)

    local sucessbtn = AGUI:Create("Button")
    sucessbtn:SetFullWidth(true)
    sucessbtn:SetText("Save")
    sucessbtn:SetCallback("OnClick", function()
        frame:Hide()
        _self.EventBus:PublishEvent(ClassicWoT.Config.Events.SetPlayerInfo, {
            name = data.name,
            score = score:GetValue(),
            note = note:GetText(),
        })
    end)
    frame:AddChild(sucessbtn)

    self.frame = frame
end