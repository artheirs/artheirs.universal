-- ===========================================================
--  ARTHEIRS UNIVERSAL WHITELIST — HWID lock, lifetime, ALL GAMES
-- ===========================================================
--  Single source of truth untuk semua game (VD + Arsenal + DG + future).
--  1 buyer = bundle access (pricing Lifetime Rp 50k single-tier).
--
--  Format per entry: ["HWID"] = { name = "Nama (YYYY-MM-DD)" }
--
--  Workflow onboarding buyer baru:
--    1. Buyer beli → kasih probe 1-liner di #how-to-buy:
--         loadstring(game:HttpGet("https://raw.githubusercontent.com/artheirs/artheirs.universal/refs/heads/main/probe_hwid.lua?v="))()
--       Output → HWID auto-copy ke clipboard. Buyer paste ke admin di Discord.
--    2. Admin add baris: ["<HWID>"] = { name = "Buyer X (YYYY-MM-DD)" }, commit + push.
--    3. Buyer inject loader utama → GRANTED. Bisa pake akun Roblox manapun (HWID yg di-lock).
--    4. Buyer pindah ke game lain di bundle (VD → Arsenal → DG) → auto-GRANTED via token snapshot.
--
--  Reset HWID (buyer ganti device / reinstall executor):
--    Buyer open ticket Discord → admin verify pembelian → admin delete entry HWID lama,
--    minta HWID baru via probe, add entry baru, push. Max reset wajar 2x/bulan.
--
--  Revoke buyer (refund / abuse / banned account):
--    Admin delete entry → push. Buyer langsung Access Denied next inject.
-- ===========================================================

return {
    ["dc9c777230b7e9909ef61dedd3a77b72ce68343409bcfd943953d11431389919"] = { name = "Cio (owner) - PC" },
    ["8ebc75457339951cddfcfc8ced4687ab287d3e580cf53ff23322c72f878dfa21"] = { name = "Cio (owner) - Mobile (Delta post-update 2026-06-16)" },
}
