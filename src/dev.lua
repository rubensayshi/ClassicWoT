﻿--[[
This file contains development-only things that aren't pretty but don't need to be ... xD

@TODO: when we make something to build releases it should make sure to omit this file
--]]
-- Addon global
local ClassicWoT = _G.ClassicWoT

--[[
ClassicWoT:wotiam is our /wotiam handler, it changes our sender identity for debugging purposes
--]]
function ClassicWoT:wotiam(input)
    local name = self:GetArgs(input, 1)

    if name == nil then
        self:PPrint("Need a name")
    end

    self.Core.me = name
end

--[[
ClassicWoT:wothistory is our /wothistory handler
--]]
function ClassicWoT:wothistory()
    print("groups: " .. #self.InteractionTracker:GetGroupHistory() .. "/" .. self.DB.char.groupHistoryCount)

    for groupID, group in pairs(self.InteractionTracker:GetGroupHistory()) do
        print("Group #" .. groupID)

        for _, player in pairs(group.dbEntry.players) do
            print(player.name)
        end

        for _, zone in pairs(group.dbEntry.zones) do
            print(zone.name)
        end
    end
end

--[[
ClassicWoT:wotreset is our /wotreset handler, it resets the DB for debugging purposes
--]]
function ClassicWoT:wotreset()
    self.DB:ResetDB()
end

--[[
ClassicWoT:wot is our /wot handler, it's temporary because everything should get a UI ...
--]]
function ClassicWoT:wot(input)
    local name, score, note = self:GetArgs(input, 3)

    if score == nil then
        local player = self.WoT:GetPlayerInfo(name)
        if player == nil then
            self:PPrint(name .. " not known")
            return
        end

        if player.score ~= nil then
            self:PPrint(name .. " in our WoT, score: " .. player.score .. ", note: " .. player.note)
        end

        if ClassicWoT.table.cnt(player.opinions) == 0 then
            self:PPrint(name .. " not known by WoT")
        else
            local cnt, sum, minn, maxx = ClassicWoT.table.cntsumminmax(player.opinions, function(opinion)
                return opinion.score
            end)

            self:PPrint(string.format("%s known by %d in our WoT, min: %d max: %d avg: %.1f",
                    player.name, cnt, minn, maxx, sum / cnt))

            for sender, opinion in pairs(player.opinions) do
                self:PPrint(" - " .. sender .. ", score: " .. opinion.score)
            end
        end
    else
        -- sanity check that provided score is a number
        score = tonumber(score)
        if score == nil then
            self:PPrint("wot: invalid score, not a number, from input: " .. input)
            return
        end

        self.EventBus:PublishEvent(ClassicWoT.Config.Events.SetPlayerInfo, {
            name = name,
            score = score:GetValue(),
            note = note:GetText(),
        })
    end
end