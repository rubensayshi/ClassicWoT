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