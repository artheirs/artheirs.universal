-- ===========================================================
--  ARTHEIRS UNIVERSAL — HWID Probe (buyer onboarding)
-- ===========================================================
--  Cara pakai (buyer paste di executor):
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/artheirs/artheirs.universal/refs/heads/main/probe_hwid.lua?v="))()
--
--  Output:
--    - Notification UI dengan HWID 64-char
--    - HWID auto-copy ke clipboard (setclipboard)
--    - Print di executor console (fallback)
--    Buyer share HWID ke admin via Discord ticket → admin add ke whitelist.lua.
-- ===========================================================

local Players     = game:GetService("Players")
local StarterGui  = game:GetService("StarterGui")
local LP          = Players.LocalPlayer

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

    -- Generate persistent UUID kalau executor ga support gethwid
    local seed = tostring(os.time())
        .. tostring(math.random(1, 1e9))
        .. tostring((LP and LP.UserId) or 0)
        .. tostring((LP and LP.Name) or "?")
    local hash = 0
    for i = 1, #seed do
        hash = (hash * 31 + string.byte(seed, i)) % 2147483647
    end
    local uuid = string.format("%x-%x-%x", hash, math.random(1e8, 9e8), os.time())
    if writefile then pcall(writefile, fname, uuid) end
    return uuid
end

local HWID = getHWID()

-- Normalize ke 64-char prefix (sama dengan format whitelist)
local function hwidPrefix(s)
    if type(s) ~= "string" then return "" end
    s = s:gsub("[%c%s]", "")
    if #s > 64 then s = s:sub(1, 64) end
    return s
end

local HWID_SHORT = hwidPrefix(HWID)

-- Print di console
print("================================================================")
print("[ARTHEIRS] Your HWID (share ke admin via ticket Discord):")
print(HWID_SHORT)
print("Length:", #HWID_SHORT)
print("================================================================")

-- Auto-copy ke clipboard
local copyOk = false
if setclipboard then
    copyOk = pcall(setclipboard, HWID_SHORT)
elseif toclipboard then
    copyOk = pcall(toclipboard, HWID_SHORT)
end

-- Notification UI
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title    = "Artheirs — Your HWID",
        Text     = (copyOk and "Copied to clipboard. Paste ke ticket Discord."
                              or "Lihat console: Tab \"Output\" / F9. Copy manual."),
        Duration = 12,
    })
end)

-- Optional: tampilkan modal sederhana dengan ScreenGui (kalau notif terlalu cepat lewat)
pcall(function()
    local pg = LP:WaitForChild("PlayerGui", 2)
    if not pg then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ArtheirsHWIDProbe"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 520, 0, 180)
    frame.Position = UDim2.new(0.5, -260, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 11)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(212, 162, 76)  -- gold
    stroke.Thickness = 2
    stroke.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "ARTHEIRS — Your HWID"
    title.TextColor3 = Color3.fromRGB(212, 162, 76)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local hwidBox = Instance.new("TextBox")
    hwidBox.Size = UDim2.new(1, -20, 0, 40)
    hwidBox.Position = UDim2.new(0, 10, 0, 44)
    hwidBox.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    hwidBox.Text = HWID_SHORT
    hwidBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    hwidBox.Font = Enum.Font.Code
    hwidBox.TextSize = 14
    hwidBox.TextEditable = false
    hwidBox.ClearTextOnFocus = false
    hwidBox.BorderSizePixel = 0
    hwidBox.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 36)
    info.Position = UDim2.new(0, 10, 0, 92)
    info.BackgroundTransparency = 1
    info.Text = (copyOk and "Sudah auto-copy ke clipboard. Paste ke ticket Discord."
                          or "Klik HWID di atas → CTRL+A → CTRL+C → paste ke ticket.")
    info.TextColor3 = Color3.fromRGB(180, 180, 180)
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextWrapped = true
    info.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 100, 0, 28)
    closeBtn.Position = UDim2.new(1, -110, 1, -38)
    closeBtn.BackgroundColor3 = Color3.fromRGB(212, 162, 76)
    closeBtn.Text = "CLOSE"
    closeBtn.TextColor3 = Color3.fromRGB(10, 10, 11)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end)
