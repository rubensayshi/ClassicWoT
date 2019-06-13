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
require("core.event-bus")
require("core.interaction-tracker")
require("core.current-group")
require("core.historical-group")
require("networking.network")

return ClassicWoT
