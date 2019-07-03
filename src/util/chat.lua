local ClassicWoT = _G.ClassicWoT

function ClassicWoT:Print(message)
    print("|cFFFFFFFF", message)
end

function ClassicWoT:SystemEventPrint(message)
    print(ClassicWoT.Colors.SYSTEM_EVENT_YELLOW, message)
end

function ClassicWoT:PPrint(message)
    print("|cFF7777FFClassicWoT:|cFFFFFFFF", message)
end

function ClassicWoT:DebugPrint(message)
    if (self.Config.Debug == true) then
        print("|cFF7777FFClassicWoT Debug:|cFFFFFFFF", message)
    end
end

function ClassicWoT:TracePrint(message)
    if (self.Config.Trace == true) then
        print("|cFF7777FFClassicWoT Trace:|cFFFFFFFF", message)
    end
end

function ClassicWoT:DebugPrintTable(t)
    local function dump(o)
        if type(o) == "table" then
            local s = "{ "
            for k,v in pairs(o) do
                s = s .. "[" .. k .. "] = " .. dump(v) .. ", "
            end
            return s .. "} "
        else
            return tostring(o)
        end
    end

    if (self.Config.Debug == true) then
        print("|cFF7777FFClassicWoT Debug:|cFFFFFFFF table...")
        print(dump(t))
    end
end

function ClassicWoT:PlayerChatLink(playerName, linkTitle)
    if linkTitle == nil then
        linkTitle = playerName
    end

    return ClassicWoT.Colors.SYSTEM_EVENT_YELLOW ..
            "|Hplayer:" .. playerName .. "|h[" .. linkTitle .. "]|h" ..
            ClassicWoT.Colors.WHITE
end