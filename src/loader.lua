-- ===========================================================
--  ARTHEIRS UNIVERSAL LOADER — Multi-Game Router
-- ===========================================================
--  Cara pakai (buyer paste di executor):
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/artheirs/artheirs.universal/refs/heads/main/src/loader.lua"))()
--
--  Flow:
--    1. Detect UniverseId (game.GameId) + platform (PC / Mobile)
--    2. Lookup GAMES routing table → fetch per-game main script
--    3. loadstring + run
-- ===========================================================

-- ===========================================================
--  GAME ROUTING TABLE
--  Key  = UniverseId (game.GameId). Resolve via `print(game.GameId)` di Roblox.
--  Value = { name, pc, mobile } atau { name, universal }
--    - Pakai `pc`/`mobile` kalau game punya 2 script berbeda per platform (VD)
--    - Pakai `universal` kalau game punya 1 script untuk semua platform (Arsenal, DG, GG2)
-- ===========================================================
local GAMES = {
    [6739698191] = {  -- Violence District
        name   = "Violence District",
        pc     = "https://raw.githubusercontent.com/artheirs/artheirs.vd/refs/heads/main/src/ArtheirsVD.lua",
        mobile = "https://raw.githubusercontent.com/artheirs/artheirs.vd/refs/heads/main/src/mobile.lua",
    },
    [111958650] = {  -- Arsenal
        name      = "Arsenal",
        universal = "https://raw.githubusercontent.com/artheirs/artheirs.arsenal/refs/heads/main/src/Arsenal.lua",
    },
    [9051406594] = {  -- Dueling Grounds
        name      = "Dueling Grounds",
        universal = "https://raw.githubusercontent.com/artheirs/artheirs.dg/refs/heads/main/src/DuelingGrounds.lua",
    },
    [10200395747] = {  -- Grow a Garden 2
        name      = "Grow a Garden 2",
        universal = "https://raw.githubusercontent.com/artheirs/artheirs.gag/refs/heads/main/src/Gg.lua",
    },
}

-- ===========================================================
--  Routing
-- ===========================================================
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

local platLabel = IS_MOBILE and "mobile" or "pc"
local mainURL   = gameDef.universal or (IS_MOBILE and gameDef.mobile) or gameDef.pc
if not mainURL then
    warn("[ARTHEIRS] " .. tostring(gameDef.name) .. " — main script for " .. platLabel .. " belum di-config.")
    return
end

-- Cache-bust query agar GitHub raw CDN (5 menit) selalu serve versi terbaru.
local bust = "?nocache_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9)) .. "=1"

local ok, mainSrc = pcall(game.HttpGet, game, mainURL .. bust)
if not ok or type(mainSrc) ~= "string" or #mainSrc < 1 then
    warn("[ARTHEIRS] Gagal fetch main script: " .. tostring(mainSrc))
    return
end

local mFn, mErr = loadstring(mainSrc)
if not mFn then
    warn("[ARTHEIRS] Main syntax error: " .. tostring(mErr))
    return
end

local sok, serr = pcall(mFn)
if not sok then
    warn("[ARTHEIRS] Main runtime error: " .. tostring(serr))
end
