-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local CreateFrame = _G.CreateFrame

---@class ClassicWoTChatLink
---@field Core ClassicWoTCore
---@field WoT ClassicWoTWoT
local ClassicWoTChatLink = {}
ClassicWoTChatLink.__index = ClassicWoTChatLink
ClassicWoT.ChatLink = ClassicWoTChatLink

setmetatable(ClassicWoTChatLink, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTChatLink.new(Core, WoT)
    local self = setmetatable({}, ClassicWoTChatLink)

    self.Core = Core
    self.WoT = WoT

    self.Frame = nil

    return self
end

function ClassicWoTChatLink:Hook()
    hooksecurefunc("ChatFrame_OnHyperlinkShow", function(self, link, text, button)
        if link and link:sub(0, 10) == "classicwot" then
            local _, _, meta, characterName, displayName = text:find("|Hclassicwot(.-)|h|cFF8800FF%[([^%s]+)|r %- |cFF8800FF([^%]]+)%]|h")
            if(characterName and displayName) then
                characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "")
                displayName = displayName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "")

                ClassicWoT:DebugPrint("ChatLink: " .. meta)
                ClassicWoT:DebugPrint("ChatLink: " .. characterName)
                ClassicWoT:DebugPrint("ChatLink: " .. displayName)
            else
                ClassicWoT:PPrint("Malformed ClassicWoT chat link")
            end
        end
    end)

    -- replace _G.ItemRefTooltip.SetHyperlink for when our chatlink is clicked without a modifier
    local OriginalSetHyperlink = _G.ItemRefTooltip.SetHyperlink
    function _G.ItemRefTooltip:SetHyperlink(link, ...)
        -- do nothing, ChatFrame_OnHyperlinkShow will handle the click
        if link and link:sub(0, 10) == "classicwot" then
            return
        end
        return OriginalSetHyperlink(self, link, ...)
    end

    -- replace _G.HandleModifiedItemClick for when our chatlink is clicked with a modifier
    local OriginalHandleModifiedItemClick = _G.HandleModifiedItemClick
    function _G.HandleModifiedItemClick(link, ...)
        -- do nothing, ChatFrame_OnHyperlinkShow will handle the click
        if link and link:find("|Hclassicwot") then
            return
        end
        return OriginalHandleModifiedItemClick(link, ...)
    end

    ClassicWoT:PPrint("|Hclassicwot346327623:398237|h|cFF8800FF[" .. "bennie" .. "|r - |cFF8800FF" .. "hiii" .. "]|h|r")
end
