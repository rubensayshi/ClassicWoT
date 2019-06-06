local ClassicWoT = _G.ClassicWoT

ClassicWoT.Colors = {
    WHITE = "|cFFFFFFFF",
    SYSTEM_EVENT_YELLOW = "|cFFFFFF00",
}

ClassicWoT.Config = {
    Debug = true,
    Trace = false,
    Score = {
        Min = -5,
        Default = 0,
        Max = 5,
        Trusted = 4,
    },
    Network = {
        Prefix = "CWOT",
        Channel = {
            Name = "ClassicWoTNetwork",
            Id = 1, -- will be set at runtime to channel ID when joined
        },
        Events = {
            SetScore = "CWOT_NE_SET_SCORE",
            RequestScores = "CWOT_NE_REQUEST_SCORES",
        }
    },
    Events = {
        SetPlayerInfo = "CWOT_SET_PLAYER_INFO",
    }
}
