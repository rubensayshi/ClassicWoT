_G.strmatch = string.match

local servertime = 1000000000
_G.SetServerTime = function(_servertime)
    servertime = _servertime
end

_G.GetServerTime = function()
    return servertime
end