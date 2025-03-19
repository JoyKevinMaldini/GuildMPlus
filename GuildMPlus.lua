-- Guild M+ Leaderboard Addon
local addonName, addonTable = ...
local GuildMPlus = CreateFrame("Frame")

-- Ensure SavedVariables persist properly
if not GuildMPlusDB then
    GuildMPlusDB = { runs = {} }
end
if not GuildMPlusDB.runs then
    GuildMPlusDB.runs = {}
end

-- Event Handling
GuildMPlus:RegisterEvent("PLAYER_LOGIN")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_START")
GuildMPlus:RegisterEvent("ZONE_CHANGED_NEW_AREA")

GuildMPlus:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FFFF[GuildM+] Addon Loaded!|r")
        print("|cFFFFA500[GuildM+] Stored Runs:|r", #GuildMPlusDB.runs) -- Debugging persistence
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        GuildMPlus:LogRun()
    end
end)

-- Log M+ Run
function GuildMPlus:LogRun()
    print("|cFF00FFFF[GuildM+] Attempting to log run...|r")

    local runData = C_ChallengeMode.GetChallengeCompletionInfo()

    if type(runData) ~= "table" then
        print("|cFFFF0000[GuildM+] Error: Unexpected return type from API.|r")
        return
    end

    -- Extract values
    local mapID = runData.mapChallengeModeID
    local level = runData.level
    local time = runData.time
    local onTime = runData.onTime
    local members = runData.members

    -- Ensure members exist
    if not members or type(members) ~= "table" then
        print("|cFFFF0000[GuildM+] Error: Unable to retrieve run members.|r")
        return
    end

    -- Guild check
    local playerGuild = GetGuildInfo("player")
    if not playerGuild then
        print("|cFFFF0000[GuildM+] Player is not in a guild. Exiting.|r")
        return
    end

    local playerName = UnitFullName("player") -- Get the player's full name
    local guildMembersInRun = {}
    C_GuildInfo.GuildRoster()  -- Ensure the guild roster is updated

    for _, memberInfo in ipairs(members) do
        local fullName = memberInfo.name
        local guildName = GetGuildInfo(fullName)
        if guildName == playerGuild then
            table.insert(guildMembersInRun, fullName)
        end
    end

    -- Ensure the player is in the list
    if not tContains(guildMembersInRun, playerName) then
        table.insert(guildMembersInRun, playerName)
    end

    -- ✅ Requirement: At least 3 guild members in the run (including the player)
    if #guildMembersInRun < 3 then
        print("|cFFFF0000[GuildM+] Not enough guild members in the run. No points awarded.|r")
        return
    end

    -- ✅ Points calculation: Key Level * Number of Guild Members in the run
    local points = level * #guildMembersInRun
    print("|cFF00FF00[GuildM+] Points Awarded: " .. points .. " (Key Level: " .. level .. " * Guild Members: " .. #guildMembersInRun .. ")|r")

    -- Log the run
    table.insert(GuildMPlusDB.runs, {
        dungeon = C_ChallengeMode.GetMapUIInfo(mapID),
        level = level,
        time = time,
        date = date("%Y-%m-%d %H:%M:%S"),
        members = guildMembersInRun,
        points = points
    })

    print("|cFF00FF00[GuildM+] Run successfully logged!|r")
end

-- Leaderboard UI
local function ShowLeaderboard()
    local frame = CreateFrame("Frame", "GuildMPlusLeaderboard", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(300, 400)
    frame:SetPoint("CENTER")
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.title:SetText("Guild M+ Leaderboard")

    -- Aggregate points per player
    local playerPoints = {}

    for _, run in ipairs(GuildMPlusDB.runs) do
        for _, player in ipairs(run.members) do
            playerPoints[player] = (playerPoints[player] or 0) + run.points
        end
    end

    -- Convert to sortable table
    local sortedPlayers = {}
    for player, points in pairs(playerPoints) do
        table.insert(sortedPlayers, { name = player, points = points })
    end

    -- Sort by points (descending)
    table.sort(sortedPlayers, function(a, b) return a.points > b.points end)

    -- Build leaderboard text
    local text = ""
    for i, entry in ipairs(sortedPlayers) do
        text = text .. i .. ". " .. entry.name .. " - " .. entry.points .. "pts\n"
    end

    local leaderboardText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leaderboardText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    leaderboardText:SetText(text)
end


SLASH_GMPLUS1 = "/gmplus"
SlashCmdList["GMPLUS"] = ShowLeaderboard