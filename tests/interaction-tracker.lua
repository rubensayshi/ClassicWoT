-- load test base
ClassicWoT = require("testbase")

-- Consts
local CURRENT_GROUP = ClassicWoT.Config.CURRENT_GROUP

-- WoW mock API control
local SetNumGroupMembers, SetRealZoneText = _G.SetNumGroupMembers, _G.SetRealZoneText

describe("ClassicWoT.InteractionTracker", function()
    -- @TODO: test multiple groups in history and consistency of order of groups
    -- @TODO: test internals of PlayerMet when player is in WoT (also need to do some of the functionality for this)

    it("can be initialized", function()
        local db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
        db:ResetDB()

        local core = ClassicWoT.Core("Nub", "NubVille")
        local eventbus = ClassicWoT.EventBus()
        local network = {SendObject = function() end}
        local wot = ClassicWoT.WoT(core, db, network, eventbus)

        ClassicWoT.InteractionTracker(core, db, eventbus, wot)
    end)

    describe("can track groups", function()
        local db
        ---@type ClassicWoTCore
        local core
        ---@type ClassicWoTNetwork
        local network
        ---@type ClassicWoTEventBus
        local eventbus
        ---@type ClassicWoTWoT
        local wot
        ---@type ClassicWoTInteractionTracker
        local itracker
        local time = 1000000000

        before_each(function()
            db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
            db:ResetDB()
            core = ClassicWoT.Core("Nub", "NubVille")
            -- mock core:Now() to return our mocked time
            function core:Now() return time end
            eventbus = ClassicWoT.EventBus()
            network = {SendObject = function() end}
            wot = ClassicWoT.WoT(core, db, network, eventbus)
            itracker = ClassicWoT.InteractionTracker(core, db, eventbus, wot)
        end)

        describe("can process NumGroupMembers flow", function()
            it("when creating a party", function()
                local PlayerJoinedSpy = spy.on(itracker.CurrentGroup, "PlayerJoined")
                local PlayerMetSpy = spy.on(itracker, "PlayerMet")

                itracker:OnGroupRosterUpdate()

                assert.is_true(itracker.CurrentGroup:IsNew())

                -- we've sent /inv
                SetNumGroupMembers(1)
                itracker:OnGroupRosterUpdate()

                -- assert that nothing really happened yet
                assert.is_true(itracker.CurrentGroup:IsNew())

                -- first player joined
                SetNumGroupMembers(2)
                itracker:OnGroupRosterUpdate()
                assert.spy(PlayerJoinedSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player2-NubVille")
                assert.spy(PlayerMetSpy).was_called_with(match.is_ref(itracker), "Player2-NubVille")

                assert.is_false(itracker.CurrentGroup:IsNew())

                local history = itracker:GetGroupHistory()

                assert.equals(1, #history)
                assert.is_true(history[1]:IsActive())
                assert.equals(0, history[1]:Duration())

                -- advance time
                time = time + 100

                -- assert duration increased
                assert.equals(100, history[1]:Duration())

                -- party disbanded
                SetNumGroupMembers(0)
                itracker:OnGroupRosterUpdate()

                assert.is_true(itracker.CurrentGroup:IsNew())

                -- assert underlying db entry is modified
                assert.is_false(history[1]:IsActive())
                assert.equals(100, history[1]:Duration())

                history = itracker:GetGroupHistory()

                assert.equals(1, #history)
                assert.is_false(history[1]:IsActive())
                assert.equals(100, history[1]:Duration())
            end)

            it("when joining a party", function()
                local PlayerJoinedSpy = spy.on(itracker.CurrentGroup, "PlayerJoined")
                local PlayerMetSpy = spy.on(itracker, "PlayerMet")

                itracker:OnGroupRosterUpdate()

                assert.is_true(itracker.CurrentGroup:IsNew())

                -- we go invited to a 2 player party (so 2 + 1 = 3)
                SetNumGroupMembers(3)
                itracker:OnGroupRosterUpdate()
                assert.spy(PlayerJoinedSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player2-NubVille")
                assert.spy(PlayerJoinedSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player3-NubVille")
                assert.spy(PlayerMetSpy).was_called_with(match.is_ref(itracker), "Player2-NubVille")
                assert.spy(PlayerMetSpy).was_called_with(match.is_ref(itracker), "Player3-NubVille")

                assert.is_false(itracker.CurrentGroup:IsNew())

                -- party disbanded
                SetNumGroupMembers(0)
                itracker:OnGroupRosterUpdate()

                assert.is_true(itracker.CurrentGroup:IsNew())
            end)

            it("when somebody is invited to existing party", function()
                local SyncPlayerSpy = spy.on(itracker.CurrentGroup, "SyncPlayer")
                local PlayerJoinedSpy = spy.on(itracker.CurrentGroup, "PlayerJoined")
                local PlayerMetSpy = spy.on(itracker, "PlayerMet")

                itracker:OnGroupRosterUpdate()

                assert.is_true(itracker.CurrentGroup:IsNew())

                -- we go invited to a 2 player party (so 2 + 1 = 3)
                SetNumGroupMembers(3)
                itracker:OnGroupRosterUpdate()
                assert.spy(PlayerJoinedSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player2-NubVille")
                assert.spy(PlayerJoinedSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player3-NubVille")
                assert.spy(PlayerMetSpy).was_called_with(match.is_ref(itracker), "Player2-NubVille")
                assert.spy(PlayerMetSpy).was_called_with(match.is_ref(itracker), "Player3-NubVille")

                assert.is_false(itracker.CurrentGroup:IsNew())

                -- another person got invited (so 3 + 1 = 4)
                SetNumGroupMembers(4)
                itracker:OnGroupRosterUpdate()
                assert.spy(SyncPlayerSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player2-NubVille")
                assert.spy(SyncPlayerSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player3-NubVille")
                assert.spy(SyncPlayerSpy).was_called_with(match.is_ref(itracker.CurrentGroup), "Player4-NubVille")
                assert.spy(PlayerMetSpy).was_called_with(match.is_ref(itracker), "Player4-NubVille")

                assert.is_false(itracker.CurrentGroup:IsNew())

                -- party disbanded
                SetNumGroupMembers(0)
                itracker:OnGroupRosterUpdate()

                assert.is_true(itracker.CurrentGroup:IsNew())
            end)
        end)

        describe("can track zones", function()
            it("tracks new zones and time spent in zone", function()
                local ZoneEnteredSpy = spy.on(itracker.CurrentGroup, "ZoneEntered")

                -- set first zone
                SetRealZoneText("Ironforge")

                -- check it doesn't track when no group yet
                assert.is_true(itracker.CurrentGroup:IsNew())
                itracker:OnZoneChangedNewArea()
                assert.spy(ZoneEnteredSpy).was_not_called()

                -- init our group
                SetNumGroupMembers(2)
                itracker:OnGroupRosterUpdate()
                assert.is_false(itracker.CurrentGroup:IsNew())

                local history = itracker:GetGroupHistory()
                assert.equals(1, #history)
                local group = history[1]

                -- check that there's no zone registered when the group is formed
                -- @TODO: we want to fix this, for now testing the "expected"
                assert.equals(0, ClassicWoT.table.cnt(group.dbEntry.zones))

                itracker:OnZoneChangedNewArea()
                assert.spy(ZoneEnteredSpy).was_called()

                assert.equals(1, ClassicWoT.table.cnt(group.dbEntry.zones))
                assert.equals(time, group.dbEntry.zones["Ironforge"].joined)

                -- check that nothing changes if we have another OnZoneChangedNewArea without the GetRealZoneText changing
                itracker:OnZoneChangedNewArea()
                assert.spy(ZoneEnteredSpy).was_called()

                assert.equals(1, ClassicWoT.table.cnt(group.dbEntry.zones))
                assert.equals(time, group.dbEntry.zones["Ironforge"].joined)

                -- advance time
                time = time + 100

                -- change zone
                SetRealZoneText("Stormwind")
                itracker:OnZoneChangedNewArea()
                assert.spy(ZoneEnteredSpy).was_called()

                assert.equals(2, ClassicWoT.table.cnt(group.dbEntry.zones))
                assert.is_nil(group.dbEntry.zones["Ironforge"].joined)
                assert.equals(time, group.dbEntry.zones["Stormwind"].joined)
                assert.equals(100, group.dbEntry.zones["Ironforge"].totalTime)
                assert.equals(0, group.dbEntry.zones["Stormwind"].totalTime)

                -- advance time
                time = time + 100

                -- change zone back
                SetRealZoneText("Ironforge")
                itracker:OnZoneChangedNewArea()
                assert.spy(ZoneEnteredSpy).was_called()

                assert.equals(2, ClassicWoT.table.cnt(group.dbEntry.zones))
                assert.is_nil(group.dbEntry.zones["Stormwind"].joined)
                assert.equals(time, group.dbEntry.zones["Ironforge"].joined)
                assert.equals(100, group.dbEntry.zones["Stormwind"].totalTime)
                assert.equals(100, group.dbEntry.zones["Ironforge"].totalTime)

                -- advance time
                time = time + 100

                -- change zone back
                SetRealZoneText("Stormwind")
                itracker:OnZoneChangedNewArea()
                assert.spy(ZoneEnteredSpy).was_called()

                assert.equals(2, ClassicWoT.table.cnt(group.dbEntry.zones))
                assert.is_nil(group.dbEntry.zones["Ironforge"].joined)
                assert.equals(time, group.dbEntry.zones["Stormwind"].joined)
                assert.equals(100, group.dbEntry.zones["Stormwind"].totalTime)
                assert.equals(200, group.dbEntry.zones["Ironforge"].totalTime)
            end)
        end)
    end)
end)