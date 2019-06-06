_G.GetRealmName = function()
    return "NubVille"
end

_G.UnitName = function()
    return "Nub"
end

_G.UnitClass = function()
    return "Druid"
end

_G.UnitRace = function()
    return "Night Elf"
end

_G.UnitFactionGroup = function()
    return "Alliance"
end

_G.GetLocale = function()
    return "enUS"
end

_G.GetCurrentRegion = function()
    return 3 -- EU, from ("US", "KR", "EU", "TW", "CN")
end

_G.UnitFullName = function(target)
    if target == "player" then
        return _G.UnitName(), _G.GetRealmName()
    else
        error("unsupported", 1)
    end
end

_G.GetTime = function()
    return 60123.558
end

local numGroupMembers = 0
_G.SetNumGroupMembers = function(i)
    numGroupMembers = i
end

_G.GetNumGroupMembers = function()
    return numGroupMembers
end

_G.GetRaidRosterInfo = function(i)
    return "Player-" .. i
end