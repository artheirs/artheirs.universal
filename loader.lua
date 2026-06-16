-- ===========================================================
--  ARTHEIRS UNIVERSAL LOADER — HWID Lock + Multi-Game Router
-- ===========================================================
--  Cara pakai (buyer paste di executor):
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/artheirs/artheirs.universal/refs/heads/main/loader.lua?v="))()
--
--  Flow:
--    1. Fetch whitelist (cache-bypass via request() no-cache)
--    2. HWID check: token snapshot primary → live gethwid() fallback
--    3. Granted → detect game via UniverseId → fetch per-game main script
--    4. Loop log: GRANTED / FIRST_BIND / DENIED ke #universal-loader-log
-- ===========================================================

local REPO   = "artheirs/artheirs.universal"
local BRANCH = "main"
local BASE   = "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH

-- Discord webhook untuk log auth (GRANTED / FIRST_BIND / DENIED / WL-DEBUG)
-- → channel #universal-loader-log
local WEBHOOK = "https://discord.com/api/webhooks/1516430012192915496/yA9gmMf3X6nqfxJ3tDkvzNsR0Vdk7CWYSWGEteh4fWre3Np28xvMVsqdEfnSy43Ha8TH"

-- ===========================================================
--  GAME ROUTING TABLE
--  Key  = UniverseId (game.GameId). Resolve via `print(game.GameId)` di Roblox.
--  Value = { name, pc, mobile } atau { name, universal }
--    - Pakai `pc`/`mobile` kalau game punya 2 script berbeda per platform (VD)
--    - Pakai `universal` kalau game punya 1 script untuk semua platform (Arsenal, DG)
-- ===========================================================
local GAMES = {
    [6739698191] = {  -- Violence District
        name   = "Violence District",
        pc     = "https://raw.githubusercontent.com/artheirs/artheirs.vd/refs/heads/main/src/ArtheirsVD.lua",
        mobile = "https://raw.githubusercontent.com/artheirs/artheirs.vd/refs/heads/main/src/mobile.lua",
    },
    -- [<ARSENAL_UNIVERSE_ID>] = {
    --     name      = "Arsenal",
    --     universal = "https://raw.githubusercontent.com/artheirs/artheirs.arsenal/refs/heads/main/src/Arsenal.lua",
    -- },
    -- [<DUELING_UNIVERSE_ID>] = {
    --     name      = "Dueling Grounds",
    --     universal = "https://raw.githubusercontent.com/artheirs/artheirs.dueling/refs/heads/main/src/DuelingGrounds.lua",
    -- },
}

-- ===========================================================
--  Setup
-- ===========================================================

local function bust()
    return "?nocache_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 1e9)) .. "=1"
end

-- CACHE-BYPASS FETCH: request() dengan Cache-Control no-cache headers.
local function fetchNoCache(url)
    local req = (syn and syn.request)
            or (http and http.request)
            or http_request
            or request
            or (fluxus and fluxus.request)
    if req then
        local ok, res = pcall(req, {
            Url     = url,
            Method  = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache, no-store, must-revalidate, max-age=0",
                ["Pragma"]        = "no-cache",
                ["Expires"]       = "0",
            },
        })
        if ok and res and res.Body then
            return true, res.Body
        end
    end
    return pcall(game.HttpGet, game, url)
end

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS         = game:GetService("UserInputService")
local LP          = Players.LocalPlayer

local IS_MOBILE   = UIS.TouchEnabled and not UIS.MouseEnabled
local UID         = (LP and LP.UserId) or 0
local NAME        = (LP and LP.Name)   or "?"
local UNIVERSE    = game.GameId
local PLACE       = game.PlaceId
local JOBID       = game.JobId or "?"

-- HWID detection: native gethwid() bila ada, fallback persistent UUID via writefile.
local function getHWID()
    local ok, hw = pcall(function()
        if type(gethwid) == "function" then return gethwid() end
        return nil
    end)
    if ok and type(hw) == "string" and #hw > 0 then
        return hw
    end

    local fname = "artheirs_hwid.txt"
    if isfile and readfile and isfile(fname) then
        local r, content = pcall(readfile, fname)
        if r and type(content) == "string" and #content > 8 then
            return content
        end
    end

    local seed = tostring(os.time()) .. tostring(math.random(1, 1e9)) .. tostring(UID) .. tostring(NAME)
    local hash = 0
    for i = 1, #seed do
        hash = (hash * 31 + string.byte(seed, i)) % 2147483647
    end
    local uuid = string.format("%x-%x-%x", hash, math.random(1e8, 9e8), os.time())
    if writefile then pcall(writefile, fname, uuid) end
    return uuid
end

local function httpPost(url, jsonBody)
    local fn = (syn and syn.request)
            or (http and http.request)
            or http_request
            or request
            or (fluxus and fluxus.request)
    if not fn then return false, "no request impl" end
    return pcall(fn, {
        Url     = url,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = jsonBody,
    })
end

local function discordLog(status, hwid, gameName, extra)
    if not WEBHOOK or WEBHOOK:find("REPLACE_") then return end
    local color =
        (status == "GRANTED"    and 5763719)  or  -- green
        (status == "FIRST_BIND" and 15844367) or  -- yellow
        (status == "DENIED"     and 15548997) or  -- red
        9807270                                     -- gray (UNSUPPORTED dll)
    local tsOk, ts = pcall(os.date, "!%Y-%m-%dT%H:%M:%SZ")
    local payload = {
        username = "Artheirs Universal Guard",
        embeds = {{
            title = "[" .. status .. "] " .. tostring(NAME) .. " (" .. tostring(UID) .. ")",
            color = color,
            fields = {
                { name = "UserId",     value = tostring(UID),                            inline = true  },
                { name = "Name",       value = tostring(NAME),                           inline = true  },
                { name = "Game",       value = tostring(gameName or "?"),                inline = true  },
                { name = "HWID",       value = "`" .. tostring(hwid):sub(1, 64) .. "`",  inline = false },
                { name = "UniverseId", value = tostring(UNIVERSE),                       inline = true  },
                { name = "PlaceId",    value = tostring(PLACE),                          inline = true  },
                { name = "JobId",      value = tostring(JOBID):sub(1, 32),               inline = true  },
                { name = "Info",       value = tostring(extra or "-"),                   inline = false },
            },
            timestamp = tsOk and ts or os.date(),
        }},
    }
    local ok, body = pcall(HttpService.JSONEncode, HttpService, payload)
    if ok then pcall(httpPost, WEBHOOK, body) end
end

local function denied(reason, hwid, gameName)
    discordLog("DENIED", hwid or "?", gameName, reason)
    local short = tostring(hwid):sub(1, 24) .. "..."
    local msg = string.format(
        "[ARTHEIRS] Access Denied (%s)\nHWID: %s\nHubungi @cio di Discord untuk beli akses.",
        reason, short
    )
    warn(msg)
    pcall(function()
        if LP and LP.Kick then LP:Kick(msg) end
    end)
end

-- ===========================================================
--  Main flow
-- ===========================================================

local HWID = getHWID()

-- Persistent HWID snapshot: token saved post-FIRST_BIND, immune ke executor update.
-- SHARED ANTAR GAME — buyer FIRST_BIND di VD, next inject di Arsenal langsung GRANTED.
local BIND_FILE = "artheirs_bind.token"

local function readBoundHwid()
    if not (isfile and readfile and isfile(BIND_FILE)) then return nil end
    local okR, content = pcall(readfile, BIND_FILE)
    if okR and type(content) == "string" and #content >= 8 then
        return content
    end
    return nil
end

local function writeBoundHwid(hw)
    if not writefile then return end
    pcall(writefile, BIND_FILE, hw)
end

-- 1. Fetch whitelist
local ok, wlSrc = fetchNoCache(BASE .. "/whitelist.lua" .. bust())
if not ok or type(wlSrc) ~= "string" or #wlSrc < 1 then
    return denied("whitelist fetch fail", HWID, "?")
end

local wlFn, wlErr = loadstring(wlSrc)
if not wlFn then
    return denied("whitelist syntax: " .. tostring(wlErr), HWID, "?")
end

local okRun, wl = pcall(wlFn)
if not okRun or type(wl) ~= "table" then
    return denied("whitelist invalid format", HWID, "?")
end

-- 2. HWID lookup helpers
local function cleanHwid(s)
    if type(s) ~= "string" then return "" end
    s = s:gsub("[%c%s]", "")
    return s
end

local function hwidPrefix(s)
    s = cleanHwid(s)
    if #s > 64 then s = s:sub(1, 64) end
    return s
end

local function lookupEntry(hw)
    if type(hw) ~= "string" or #hw < 8 then return nil end
    local clean = cleanHwid(hw)
    local short = hwidPrefix(hw)
    local found = wl[hw] or wl[clean] or wl[short]
    if type(found) == "table" then return found end
    for k, v in pairs(wl) do
        if type(k) == "string" and hwidPrefix(k) == short then
            return v
        end
    end
    return nil
end

local boundHwid   = readBoundHwid()
local entry       = nil
local matchedHwid = nil
local bindStatus  = "GRANTED"

-- Strategy 1: token snapshot
if boundHwid then
    entry = lookupEntry(boundHwid)
    if entry then matchedHwid = boundHwid end
end

-- Strategy 2: live gethwid() fallback
if not entry then
    entry = lookupEntry(HWID)
    if entry then
        matchedHwid = HWID
        bindStatus  = "FIRST_BIND"
        writeBoundHwid(HWID)
    end
end

if type(entry) ~= "table" then
    -- Diagnostic embed (port dari VD client.lua)
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then return end
        local keysList, keyLens = {}, {}
        local keyType = type(next(wl))
        for k, _ in pairs(wl) do
            if type(k) == "string" then
                table.insert(keysList, k)
                table.insert(keyLens,  tostring(#k))
            else
                table.insert(keysList, tostring(k))
                table.insert(keyLens,  "?")
            end
            if #keysList >= 3 then break end
        end
        local diagBody = HttpService:JSONEncode({
            username = "Artheirs Universal Debug",
            embeds = {{
                title = "[WL-DEBUG] " .. tostring(NAME) .. " (" .. tostring(UID) .. ")",
                color = 16776960,
                fields = {
                    { name = "HWID live",       value = "`" .. tostring(HWID) .. "`",                 inline = false },
                    { name = "HWID live len",   value = tostring(#HWID),                              inline = true  },
                    { name = "Bound token",     value = "`" .. tostring(boundHwid or "-") .. "`",     inline = false },
                    { name = "Bound token len", value = tostring(boundHwid and #boundHwid or 0),      inline = true  },
                    { name = "WL key type",     value = tostring(keyType),                            inline = true  },
                    { name = "WL key 1",        value = "`" .. (keysList[1] or "-") .. "`",           inline = false },
                    { name = "WL key 1 len",    value = (keyLens[1] or "?"),                          inline = true  },
                    { name = "WL key 2",        value = "`" .. (keysList[2] or "-") .. "`",           inline = false },
                    { name = "WL key 2 len",    value = (keyLens[2] or "?"),                          inline = true  },
                    { name = "WL src length",   value = tostring(#wlSrc),                             inline = true  },
                },
            }},
        })
        pcall(req, { Url = WEBHOOK, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = diagBody })
    end)
    return denied("HWID tidak terdaftar", HWID, "?")
end

-- 3. HWID granted → route ke per-game main script
local gameDef = GAMES[UNIVERSE]
local gameName

if not gameDef then
    gameName = "Unsupported (UID=" .. tostring(UNIVERSE) .. ")"
    discordLog("DENIED", matchedHwid, gameName, "Game tidak supported. UniverseId belum di-route.")
    local msg = string.format(
        "[ARTHEIRS] HWID kamu valid, tapi game ini belum supported.\nUniverseId: %s · PlaceId: %s\nJoin Discord untuk request game baru.",
        tostring(UNIVERSE), tostring(PLACE)
    )
    warn(msg)
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", { Title = "Artheirs", Text = "Game belum supported", Duration = 10 })
    end)
    return
end

gameName = gameDef.name or "?"
local platLabel = IS_MOBILE and "mobile" or "pc"
local mainURL   = gameDef.universal or (IS_MOBILE and gameDef.mobile) or gameDef.pc

if not mainURL then
    return denied("no main URL for platform=" .. platLabel, matchedHwid, gameName)
end

local extraInfo = "Buyer: " .. tostring(entry.name or "?") .. " | platform: " .. platLabel
if bindStatus == "GRANTED" and matchedHwid ~= HWID then
    extraInfo = extraInfo .. " | live: " .. tostring(HWID):sub(1, 16) .. "..."
end
discordLog(bindStatus, matchedHwid, gameName, extraInfo)

-- 4. Fetch + run per-game main script
local mok, mainSrc = fetchNoCache(mainURL .. bust())
if not mok or type(mainSrc) ~= "string" or #mainSrc < 1 then
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
