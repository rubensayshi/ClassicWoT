local ClassicWoT = _G.ClassicWoT

ClassicWoT.DefaultDB = {
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
        party = {
            numMembers = 0,
            started = nil,
            ['**'] = {
                name = nil,
                joined = nil,
            }
        },
    },
}
