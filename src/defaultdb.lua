local ClassicWoT = _G.ClassicWoT

---@class ClassicWoTDefaultDB
local ClassicWoTDefaultDB = {
    profile = {
        minimap = {
            hide = false,
        },
    },
    realm = {
        wot = {
            ['**'] = {
                name = nil,
                realm = nil,
                score = nil,
                note = "",
                opinions = {
                    ['**'] = {
                        score = nil,
                    },
                }
            },
        },
    },
    char = {
        lastOnline = nil,
        groupHistoryCount = 0,
        groupHistory = {
            -- ["CURRENT"] is our magic current group key
            ['**'] = {
                numMembers = 0,
                started = nil,
                ended = nil,
                currentZone = nil,
                players = {
                    ['**'] = {
                        name = nil,
                        joined = nil,
                        totalTime = 0,
                    },
                },
                zones = {
                    ['**'] = {
                        name = nil,
                        joined = nil,
                        totalTime = 0,
                    },
                },
            },
        },
    },
}
ClassicWoT.DefaultDB = ClassicWoTDefaultDB