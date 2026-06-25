local GAMES = {
    [6739698191] = {
        name      = "Violence District",
        pc        = "https://api.luarmor.net/files/v4/loaders/0061318be4cced3dc9f6e8a69fd87f3d.lua",
        mobile    = "https://api.luarmor.net/files/v4/loaders/dca1106d0ce20b26d23e7747bb3fe124.lua",
    },
    [111958650] = {
        name      = "Arsenal",
        universal = "https://api.luarmor.net/files/v4/loaders/55a3f65db13ca2ce8218d2ff9d07fb09.lua",
    },
    [9051406594] = {
        name      = "Dueling Grounds",
        universal = "https://api.luarmor.net/files/v4/loaders/1e7409c7633df46a08d25a80745ab295.lua",
    },
    [10200395747] = {
        name      = "Grow a Garden 2",
        universal = "https://api.luarmor.net/files/v4/loaders/99286ae1187e6ca234c6f7d16f937e4d.lua",
    },
}

local UIS       = game:GetService("UserInputService")
local IS_MOBILE = UIS.TouchEnabled and not UIS.MouseEnabled
local UNIVERSE  = game.GameId
local PLACE     = game.PlaceId

local gameDef = GAMES[UNIVERSE]
if not gameDef then
    warn(string.format(
        "[ARTHEIRS] Game belum supported.\nUniverseId: %s · PlaceId: %s\nJoin Discord untuk request game baru.",
        tostring(UNIVERSE), tostring(PLACE)
    ))
    return
end

local loaderUrl
if gameDef.universal then
    loaderUrl = gameDef.universal
elseif IS_MOBILE then
    loaderUrl = gameDef.mobile
else
    loaderUrl = gameDef.pc
end

if not loaderUrl then
    warn(string.format(
        "[ARTHEIRS] %s belum support platform %s.\nJoin Discord untuk update info.",
        gameDef.name, IS_MOBILE and "Mobile" or "PC"
    ))
    return
end

loadstring(game:HttpGet(loaderUrl))()
