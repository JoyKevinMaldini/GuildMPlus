-- Guild M+ Leaderboard Addon
local addonName, addonTable = ...
local GuildMPlus = CreateFrame("Frame")
local db

-- SavedVariables setup
GuildMPlusDB = GuildMPlusDB or {}
GuildMPlusDB.runs = GuildMPlusDB.runs or {}  -- Ensure runs table exists
db = GuildMPlusDB

-- Event Handling
GuildMPlus:RegisterEvent("PLAYER_LOGIN")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_START")
GuildMPlus:RegisterEvent("ZONE_CHANGED_NEW_AREA")

GuildMPlus:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FFFF[GuildM+] Addon Loaded!|r")
        if not db.runs then db.runs = {} end

    elseif event == "CHALLENGE_MODE_START" then
        print("|cFFFFA500[GuildM+] M+ Timer Started!|r")

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        GuildMPlus:LogRun()

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "party" then
        end
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

    local guildMembersInRun = {}
    C_GuildInfo.GuildRoster()  -- Ensure the guild roster is updated

    for _, memberInfo in ipairs(members) do
        local fullName = memberInfo.name
        local guildName = GetGuildInfo(fullName)
        if guildName == playerGuild then
            table.insert(guildMembersInRun, fullName)
        end
    end

    if #guildMembersInRun == 0 then
        print("|cFFFF0000[GuildM+] No guild members found in the run. Exiting.|r")
        return
    end

    -- Determine points (0 if not in-time)
    local points = onTime and (level * 10) or 0
    if onTime then
        print("|cFF00FF00[GuildM+] Run was completed in time!|r")
    else
        print("|cFFFF0000[GuildM+] Run was NOT in time.|r")
    end

    -- Log the run
    table.insert(db.runs, {
        dungeon = C_ChallengeMode.GetMapUIInfo(mapID),
        level = level,
        time = time,
        date = date("%Y-%m-%d %H:%M:%S"),
        members = guildMembersInRun,
        points = points
    })

    print("|cFF00FF00[GuildM+] Run successfully logged!|r")

    -- Force SavedVariables update for debugging
    if IsAddOnLoaded("Blizzard_DebugTools") then
        print("|cFFFFA500[GuildM+] SavedVariables file updated. You may need to /reload.|r")
    end
end

-- Leaderboard UI
local function ShowLeaderboard()
    local frame = CreateFrame("Frame", "GuildMPlusLeaderboard", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(300, 400)
    frame:SetPoint("CENTER")
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.title:SetText("Guild M+ Leaderboard")

    local sortedRuns = {} -- Sort by points
    for _, run in ipairs(db.runs) do
        table.insert(sortedRuns, run)
    end
    table.sort(sortedRuns, function(a, b) return a.points > b.points end)

    local text = ""
    for i, run in ipairs(sortedRuns) do
        text = text .. i .. ". " .. run.members[1] .. " - " .. run.points .. "pts\n"
    end

    local leaderboardText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leaderboardText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    leaderboardText:SetText(text)
end

SLASH_GMPLUS1 = "/gmplus"
SlashCmdList["GMPLUS"] = ShowLeaderboard