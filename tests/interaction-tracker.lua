-- load test base
ClassicWoT = require("testbase")

-- WoW mock API control
local SetNumGroupMembers = _G.SetNumGroupMembers

describe("ClassicWoT.InteractionTracker", function()
    it("can be initialized", function()
        local db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
        db:ResetDB()

        local core = ClassicWoT.Core("Nub", "NubVille")
        local eventbus = ClassicWoT.EventBus()
        local network = ClassicWoT.Network(core, eventbus)
        local wot = ClassicWoT.WoT(core, db, network, eventbus)

        ClassicWoT.InteractionTracker(core, db, eventbus, wot)
    end)

    describe("setting scores", function()
        local db
        local core
        local network
        local eventbus
        local wot
        local itracker

        before_each(function()
            db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
            db:ResetDB()
            core = ClassicWoT.Core("Nub", "NubVille")
            eventbus = ClassicWoT.EventBus()
            network = ClassicWoT.Network(core, eventbus)
            wot = ClassicWoT.WoT(core, db, network, eventbus)
            itracker = ClassicWoT.InteractionTracker(core, db, eventbus, wot)
        end)

        it("can process creating a party", function()
            local GetPlayerInfoSpy = spy.on(wot, "GetPlayerInfo")

            itracker:OnGroupRosterUpdate()

            -- we've sent /inv
            SetNumGroupMembers(1)
            itracker:OnGroupRosterUpdate()

            -- first player joined
            SetNumGroupMembers(2)
            itracker:OnGroupRosterUpdate()
            assert.spy(GetPlayerInfoSpy).was_called_with(match.is_ref(wot), "Player-2-NubVille")

             --party disbanded
            SetNumGroupMembers(0)
            itracker:OnGroupRosterUpdate()
        end)

        it("can process joining a party", function()
            local GetPlayerInfoSpy = spy.on(wot, "GetPlayerInfo")

            itracker:OnGroupRosterUpdate()

            -- we go invited to a 2 player party (so 2 + 1 = 3)
            SetNumGroupMembers(3)
            itracker:OnGroupRosterUpdate()
            assert.spy(GetPlayerInfoSpy).was_called_with(match.is_ref(wot), "Player-2-NubVille")
            assert.spy(GetPlayerInfoSpy).was_called_with(match.is_ref(wot), "Player-3-NubVille")

            -- party disbanded
            SetNumGroupMembers(0)
            itracker:OnGroupRosterUpdate()
        end)
    end)
end)