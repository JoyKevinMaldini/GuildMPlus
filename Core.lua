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
        C_Timer.After(2, function()
            GuildMPlus:LogRun() -- Wait 2 seconds for C_ChallengeMode.GetChallengeCompletionInfo() to be populated properly. (Might be a fix for something, might not.)
        end)
    end
end)

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- 🔧 Helper: Normalize realm name (Need to be defined before use. Can't put at the end of file..?)
local function NormalizeRealmName(realm)
    if realm then
        return realm:gsub("[%s%-']", "")
    else
        return nil
    end
end

-- 🔧 Helper: Normalize full name (Name-Realm) (Need to be defined before use. Can't put at the end of file..?)
local function NormalizeFullName(fullName)
    local name, realm = strsplit("-", fullName)
    name = name and string.lower(string.trim(name))
    realm = realm and string.lower(string.trim(NormalizeRealmName(realm)))
    return name .. (realm and ("-" .. realm) or "")
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

    -- Ensure members exist in M+ run data
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
    print("|cFFFFA500[GuildM+] Requesting guild roster...|r")
    C_GuildInfo.GuildRoster()
    local guildRoster = {}

    -- Store all guild members names inside guildRoster array (normalized)
    local numGuildMembers = GetNumGuildMembers()
    if numGuildMembers > 0 then
        print("|cFFAAAAAA[GuildM+] Guild Roster Members: " .. numGuildMembers .. "|r")
        for i = 1, numGuildMembers do
            local fullName = GetGuildRosterInfo(i)
            if fullName then
                local normalizedName = NormalizeFullName(fullName)
                guildRoster[normalizedName] = true
            end
        end
    else
        print("|cFFFF0000[GuildM+] Warning: Guild roster is empty.|r")
        return
    end

    -- Print all members of the M+ run
    print("|cFFAAAAAA[GuildM+] Members in run:|r")
    for _, memberInfo in ipairs(members) do
        print(" - " .. memberInfo.name)
    end

    -- Identify guild members in the run -> Search matches of members (M+ run) with guildRoster
    local guildMembersInRun = {}
    local rosterPrintLimit = 3
    local printedRosterCount = 0

    for _, memberInfo in ipairs(members) do
        local runMemberFullName = NormalizeFullName(memberInfo.name)
        print("|cFFFF8000[GuildM+] Checking Run Member:|r " .. memberInfo.name .. " (Normalized: " .. runMemberFullName .. ")")

        for rosterFullName in pairs(guildRoster) do
            if printedRosterCount < rosterPrintLimit then
                print("|cFF808080[GuildM+] Comparing with Roster Member:|r " .. rosterFullName)
                printedRosterCount = printedRosterCount + 1
            end

            if runMemberFullName == rosterFullName then
                print("|cFF00FF00[GuildM+] Found Match:|r " .. runMemberFullName)
                table.insert(guildMembersInRun, runMemberFullName)
                break -- Exit inner loop once a match is found
            end
        end
    end

    -- ✅ Requirement: At least 3 guild members in the run (including the player)
    if #guildMembersInRun < 3 then
        print("|cFFFF0000[GuildM+] Not enough guild members in the run (" .. #guildMembersInRun .. "). No points awarded.|r")
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

    -- Predefined list of fake player names with optional realms
    local fakePlayersWithRealms = {
        "YourName-" .. GetRealmName(), "Player1-RealmA", "Player2-RealmB", "Player3-" .. GetRealmName(), "Player4-RealmC",
        "Player5", "Player6-RealmA", "Player7", "Player8-RealmB"
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
        local fullPlayerName = getRandomElement(fakePlayersWithRealms)
        if not used[fullPlayerName] then
            local name, realm = strsplit("-", fullPlayerName)
            table.insert(sampleMembers, { name = name, realm = realm })
            used[fullPlayerName] = true
        end
    end

    -- Generate a unique run ID
    local normalizedMemberNames = {}
    for _, member in ipairs(sampleMembers) do
        table.insert(normalizedMemberNames, NormalizeFullName(member.name .. "-" .. (member.realm or GetRealmName())))
    end
    table.sort(normalizedMemberNames)
    local runID = sampleDungeon .. "-" .. sampleLevel .. "-" .. sampleTime .. "-" .. table.concat(normalizedMemberNames, ",")

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
        members = normalizedMemberNames,
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