-- 📌 Core Logic for Guild M+ Leaderboard
local addonName, addonTable = ...
local GuildMPlus = CreateFrame("Frame")
addonTable.GuildMPlus = GuildMPlus
local ADDON_PREFIX = "GuildMPlus"

-- ✅ Initialize database
if not GuildMPlusDB then
    GuildMPlusDB = { runs = {}, lastSynced = "Never" }
end

-- 📡 Register events
GuildMPlus:RegisterEvent("PLAYER_LOGIN")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED")
GuildMPlus:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FFFF[GuildM+] Addon Loaded!|r")
        print("|cFFFFA500[GuildM+] Last Sync:|r " .. GuildMPlusDB.lastSynced)
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "REQUEST", "GUILD") -- Auto-sync on login
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        GuildMPlus:LogRun()
    end
end)

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- 🏆 **Log M+ Run**
function GuildMPlus:LogRun()
    local runData = C_ChallengeMode.GetChallengeCompletionInfo()
    if type(runData) ~= "table" then return end

    local mapID = runData.mapChallengeModeID
    local level = runData.level
    local time = runData.time
    local members = runData.members

    if not members or type(members) ~= "table" then return end

    -- ✅ Ensure player is in a guild
    local playerGuild = GetGuildInfo("player")
    if not playerGuild then return end

    -- ✅ Identify guild members in the run
    local playerName = UnitFullName("player")
    local guildMembersInRun = {}
    C_GuildInfo.GuildRoster()

    for _, memberInfo in ipairs(members) do
        local fullName = memberInfo.name
        if GetGuildInfo(fullName) == playerGuild then
            table.insert(guildMembersInRun, fullName)
        end
    end

    if not tContains(guildMembersInRun, playerName) then
        table.insert(guildMembersInRun, playerName)
    end

    if #guildMembersInRun < 3 then return end

    -- ✅ Generate Unique Run ID
    table.sort(guildMembersInRun)
    local runID = mapID .. "-" .. level .. "-" .. time .. "-" .. table.concat(guildMembersInRun, ",")

    -- ✅ Check if run is already logged
    for _, existingRun in ipairs(GuildMPlusDB.runs) do
        if existingRun.id == runID then return end
    end

    -- ✅ Store new run
    table.insert(GuildMPlusDB.runs, {
        id = runID,
        dungeon = C_ChallengeMode.GetMapUIInfo(mapID),
        level = level,
        time = time,
        date = date("%Y-%m-%d %H:%M:%S"),
        members = guildMembersInRun,
        points = level * #guildMembersInRun
    })

    -- ✅ Update last synced time & broadcast
    GuildMPlusDB.lastSynced = date("%Y-%m-%d %H:%M:%S")
    addonTable.Sync:BroadcastLeaderboard()
end