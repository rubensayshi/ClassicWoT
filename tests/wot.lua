-- stubs
require("stubs.misc")
require("stubs.player")
require("stubs.createframe")
require("stubs.chatinfo")
-- libs
require("LibStub")
require("AceDB-3dot0.AceDB-3dot0")
require("AceSerializer-3dot0.AceSerializer-3dot0")
-- addon
ClassicWoT = {}
_G.ClassicWoT = ClassicWoT
require("config")
require("defaultdb")
require("util.chat")
require("util.util")
require("util.list-helpers")
require("util.table-helpers")
require("core.core")
require("core.wot")
require("networking.network")
require("core.event-bus")

describe("ClassicWoT.Network", function()
    it("can be initialized", function()
        db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
        ClassicWoT.WoT(ClassicWoT.Core("Nub", "Nubville"), db, ClassicWoT.Network(), ClassicWoT.EventBus())
    end)

    describe("setting scores", function()
        local db
        local core
        local network
        local eventbus
        local wot

        before_each(function()
            db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
            db:ResetDB()
            core = ClassicWoT.Core("Nub", "Nubville")
            eventbus = ClassicWoT.EventBus()
            network = ClassicWoT.Network(core, eventbus)
            wot = ClassicWoT.WoT(core, db, network, eventbus)
        end)

        it("can set and retrieve scores", function()
            local SendObjectSpy = spy.on(network, "SendObject")

            wot:SetPlayerScore("roobs", 1)
            assert.spy(SendObjectSpy).was_called()

            assert.equals(wot:GetPlayerInfo("roobs").score, 1)
            assert.is_false(wot:IsTrusted("roobs"))

            wot:SetPlayerScore("roobs", 4)
            assert.spy(SendObjectSpy).was_called()
            assert.spy(SendObjectSpy).was_called()

            assert.equals(wot:GetPlayerInfo("roobs").score, 4)
            assert.is_true(wot:IsTrusted("roobs"))
        end)
    end)

    describe("receiving scores", function()
        local db
        local core
        local network
        local eventbus
        local wot

        before_each(function()
            db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
            db:ResetDB()
            core = ClassicWoT.Core("Nub", "Nubville")
            eventbus = ClassicWoT.EventBus()
            network = ClassicWoT.Network(core, eventbus)
            wot = ClassicWoT.WoT(core, db, network, eventbus)
        end)

        it("can receive scores from WoT", function()
            wot:SetPlayerScore("roobs", 4)
            assert.is_true(wot:IsTrusted("roobs"))

            wot:OnReceiveScore({name = "bennie", score = 4}, "roobs")

            assert.equals(wot:GetPlayerInfo("bennie").name, "bennie")
            assert.equals(wot:GetPlayerInfo("bennie").score, nil)
            assert.equals(wot:GetPlayerInfo("bennie").opinions["roobs"].score, 4)
        end)

        it("won't accept scores from outside WoT", function()
            assert.is_false(wot:IsTrusted("roobs"))

            wot:OnReceiveScore({name = "bennie", score = 4}, "roobs")

            assert.equals(wot:GetPlayerInfo("bennie"), nil)
        end)
    end)

    describe("requesting scores", function()
        local db
        local core
        local network
        local eventbus
        local wot

        before_each(function()
            db = LibStub("AceDB-3.0"):New("ClassicWoT_DB", ClassicWoT.DefaultDB, true)
            db:ResetDB()
            core = ClassicWoT.Core("Nub", "Nubville")
            eventbus = ClassicWoT.EventBus()
            network = ClassicWoT.Network(core, eventbus)
            wot = ClassicWoT.WoT(core, db, network, eventbus)
        end)

        it("can provide scores to WoT when requested", function()
            local SendObjectSpy = spy.on(network, "SendObject")

            wot:SetPlayerScore("roobs", 4)
            assert.is_true(wot:IsTrusted("roobs"))

            wot:OnScoresRequested(true, "roobs")
            assert.spy(SendObjectSpy).was_called()
        end)

        it("won't provide scores to outside WoT when requested", function()
            local SendObjectSpy = spy.on(network, "SendObject")
            assert.is_false(wot:IsTrusted("roobs"))

            wot:OnScoresRequested(true, "roobs")
            assert.spy(SendObjectSpy).was_not_called()
        end)
    end)
end)