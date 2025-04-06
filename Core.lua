-- 📌 Core Logic for Guild M+ Leaderboard
local addonName, addonTable = ...
local GuildMPlus = CreateFrame("Frame")
addonTable.GuildMPlus = GuildMPlus
local ADDON_PREFIX = "GuildMPlus"

print("|cFF00FFFF[GuildM+] Core module loaded.|r")

-- ✅ Initialize database
if not GuildMPlusDB then
    GuildMPlusDB = { runs = {}, lastSynced = "Never" }
end

-- 📡 Register events
GuildMPlus:RegisterEvent("PLAYER_LOGIN")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED")

GuildMPlus:HookScript("OnEvent", function(self, event, ...)
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
    print("|cFF00FFFF[GuildM+] Attempting to log run...|r")

    local runData = C_ChallengeMode.GetCompletionInfo()
    if type(runData) ~= "table" then
        print("|cFFFF0000[GuildM+] Error: Unexpected return type from API.|r")
        return
    end

    local mapID = runData.mapChallengeModeID
    local level = runData.level
    local time = runData.time
    local members = runData.members

    -- Ensure members exist
    if not members or type(members) ~= "table" then
        print("|cFFFF0000[GuildM+] Error: Unable to retrieve run members.|r")
        return
    end

    -- Get player's guild name
    local playerGuild = GetGuildInfo("player")
    if not playerGuild then
        print("|cFFFF0000[GuildM+] Player is not in a guild. Exiting.|r")
        return
    end

    -- Ensure the guild roster is updated
    C_GuildInfo.GuildRoster()
    local guildRoster = {}

    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        guildRoster[name] = true
    end

    -- Identify guild members in the run
    local guildMembersInRun = {}
    for _, memberInfo in ipairs(members) do
        local fullName = memberInfo.name
        if guildRoster[fullName] then
            table.insert(guildMembersInRun, fullName)
        end
    end

    -- ✅ Requirement: At least 3 guild members in the run (including the player)
    if #guildMembersInRun < 3 then
        print("|cFFFF0000[GuildM+] Not enough guild members in the run. No points awarded.|r")
        return
    end

    -- Generate Unique Run ID based on Map, Level, Time, and Members
    table.sort(guildMembersInRun) -- Ensure consistent order
    local runID = mapID .. "-" .. level .. "-" .. time .. "-" .. table.concat(guildMembersInRun, ",")

    -- Check if run is already logged
    for _, existingRun in ipairs(GuildMPlusDB.runs) do
        if existingRun.id == runID then
            print("|cFFFFA500[GuildM+] Run already logged.|r")
            return
        end
    end

    -- ✅ Points calculation: Key Level * Number of Guild Members in the run
    local points = level * #guildMembersInRun
    print("|cFF00FF00[GuildM+] Points Awarded: " .. points .. " (Key Level: " .. level .. " * Guild Members: " .. #guildMembersInRun .. ")|r")

    -- Log the run
    table.insert(GuildMPlusDB.runs, {
        id = runID,
        dungeon = C_ChallengeMode.GetMapUIInfo(mapID),
        level = level,
        time = time,
        date = date("%Y-%m-%d %H:%M:%S"),
        members = guildMembersInRun,
        points = points
    })

    -- ✅ Update last synced time & broadcast
    GuildMPlusDB.lastSynced = date("%Y-%m-%d %H:%M:%S")
    addonTable.Sync:BroadcastLeaderboard()

    print("|cFF00FF00[GuildM+] Run successfully logged!|r")
end
