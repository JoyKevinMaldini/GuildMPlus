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

-- 🔧 Helper: Normalize realm name (Need to be defined before use. Can't put at the end of file..?)
local function NormalizeRealmName(realm)
    return realm:gsub("[%s%-']", "")
end

-- 🔧 Helper: Normalize full name (Name-Realm) (Need to be defined before use. Can't put at the end of file..?)
local function NormalizeFullName(fullName)
    local name, realm = strsplit("-", fullName)
    name = name or fullName
    realm = realm or NormalizeRealmName(GetRealmName())
    return name .. "-" .. NormalizeRealmName(realm)
end

-- 🏆 **Log M+ Run**
function GuildMPlus:LogRun()
    print("|cFF00FFFF[GuildM+] Attempting to log run...|r")

    local runData = C_ChallengeMode.GetChallengeCompletionInfo()

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
        if name then
            guildRoster[NormalizeFullName(name)] = true
        end
    end

    print("|cFFAAAAAA[GuildM+] Members in run:|r")
    for _, memberInfo in ipairs(members) do
        print(" - " .. memberInfo.name)
    end

    print("|cFFAAAAAA[GuildM+] Guild Roster:|r")
    for name in pairs(guildRoster) do
        print(" - " .. name)
    end

    -- Identify guild members in the run
    local guildMembersInRun = {}
    for _, memberInfo in ipairs(members) do
        local fullName = NormalizeFullName(memberInfo.name)
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

-- 🏆 Add Sample Run for Testing (with Randomization)
function GuildMPlus:AddSampleRun()
    print("|cFF00FFFF[GuildM+] Adding sample run for testing...|r")

    -- Predefined list of fake player names
    local fakePlayerNames = {
        UnitName("player"), "Player1", "Player2", "Player3", "Player4", "Player5", "Player6", "Player7", "Player8"
    }

    -- Predefined list of dungeon names
    local dungeons = {
        "De Other Side", "Spire of Ascension", "Sanguine Depths", "The Necrotic Wake", "Theater of Pain"
    }

    -- Randomizing helper functions
    local function getRandomElement(list)
        return list[math.random(#list)]
    end

    local function getRandomTime()
        return math.random(10000000, 20000000) -- Simulated run time
    end

    local function getRandomLevel()
        return math.random(10, 25) -- Random key level between 10 and 25
    end

    local function getRandomDate()
        -- Get the current server time
        local currentTime = GetServerTime()

        -- Generate a random time within the last 30 days
        local randomTime = currentTime - math.random(1, 30) * 86400 -- 86400 is the number of seconds in a day

        -- Convert it to a readable date string (like: "2025-04-06 13:40:25")
        return date("%Y-%m-%d %H:%M:%S", randomTime)
    end

    -- Randomize the run data
    local sampleDungeon = getRandomElement(dungeons)
    local sampleLevel = getRandomLevel()
    local sampleTime = getRandomTime()
    local sampleMembers = {}

    local used = {}
    while #sampleMembers < 5 do
        local name = getRandomElement(fakePlayerNames)
        if not used[name] then
            table.insert(sampleMembers, name)
            used[name] = true
        end
    end

    -- Generate a unique run ID
    local runID = sampleDungeon .. "-" .. sampleLevel .. "-" .. sampleTime .. "-" .. table.concat(sampleMembers, ",")
    for _, existingRun in ipairs(GuildMPlusDB.runs) do
        if existingRun.id == runID then
            print("|cFFFFA500[GuildM+] Sample run already logged (ID: " .. runID .. ").|r")
            return
        end
    end

    -- Points calculation (simulating based on level and number of members)
    local points = sampleLevel * #sampleMembers
    print("|cFF00FF00[GuildM+] Points Awarded: " .. points .. " (Level: " .. sampleLevel .. " * Members: " .. #sampleMembers .. ")|r")

    -- Log the sample run
    table.insert(GuildMPlusDB.runs, {
        id = runID,
        dungeon = sampleDungeon,
        level = sampleLevel,
        time = sampleTime,
        date = getRandomDate(),
        members = sampleMembers,
        points = points
    })

    -- Update last synced time & broadcast
    GuildMPlusDB.lastSynced = date("%Y-%m-%d %H:%M:%S")
    addonTable.Sync:BroadcastLeaderboard()

    -- Optional: Refresh UI after adding a sample run
    if addonTable.UI and addonTable.UI.ShowLeaderboard then
        addonTable.UI:ShowLeaderboard()
    end

    print("|cFF00FF00[GuildM+] Sample run successfully logged!|r")
end

-- Slash command for testing
SLASH_ADDTESTRUN1 = "/addtestrun"
SlashCmdList["ADDTESTRUN"] = function()
    GuildMPlus:AddSampleRun()
end