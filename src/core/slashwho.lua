-- Addon global
local ClassicWoT = _G.ClassicWoT

-- WoW API
local CreateFrame = _G.CreateFrame

---@class ClassicWoTSlashWho
---@field Core ClassicWoTCore
---@field WoT ClassicWoTWoT
local ClassicWoTSlashWho = {}
ClassicWoTSlashWho.__index = ClassicWoTSlashWho
ClassicWoT.SlashWho = ClassicWoTSlashWho

setmetatable(ClassicWoTSlashWho, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function ClassicWoTSlashWho.new(Core, WoT)
    local self = setmetatable({}, ClassicWoTSlashWho)

    self.Core = Core
    self.WoT = WoT

    self.Frame = nil

    return self
end

function ClassicWoTSlashWho:Hook()
    if self.Frame then return end

    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("CHAT_MSG_SYSTEM")
    self.Frame:SetScript("OnEvent", function(_, event, ...)
        if (event == "CHAT_MSG_SYSTEM") then
            self:OnChatMsgSystem(...)
        end
    end)
end

function ClassicWoTSlashWho:OnChatMsgSystem(msg)
    ClassicWoT:DebugPrint("OnChatMsgSystem: " .. msg)
    -- ClassicWoT:DebugPrint("msg: " .. string.gsub(msg, "|", "||"))

    -- matching the player link escape sequence in /who response
    local who = string.match(msg, "|Hplayer:.-|h%[(.-)%]|h: Level [0-9][0-9]? (.-) %- (.+)")

    if who ~= nil then
        ClassicWoT:DebugPrint("/who: " .. who)

        local player = self.WoT:GetPlayerInfo(who)
        if player == nil then
            ClassicWoT:SystemEventPrint(who .. " not in WoT")
            return
        end

        if player.score ~= nil then
            ClassicWoT:SystemEventPrint(player.name .. " in our WoT, score: " .. player.score .. ", note: " .. player.note)
        end

        if ClassicWoT.table.cnt(player.opinions) == 0 then
            ClassicWoT:SystemEventPrint(player.name .. " not known by WoT")
        else
            local cnt, sum, minn, maxx = ClassicWoT.table.cntsumminmax(player.opinions, function(opinion)
                return opinion.score
            end)

            ClassicWoT:SystemEventPrint(string.format("%s known by %d in our WoT, min: %d max: %d avg: %.1f, opinions: ",
                    player.name, cnt, minn, maxx, sum / cnt))

            for sender, opinion in pairs(player.opinions) do
                ClassicWoT:SystemEventPrint(" - " .. sender .. ", score: " .. opinion.score)
            end
        end
    end
end