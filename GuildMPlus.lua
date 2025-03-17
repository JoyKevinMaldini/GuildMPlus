-- Guild M+ Leaderboard Addon
local addonName, addonTable = ...
local GuildMPlus = CreateFrame("Frame")
local db

-- SavedVariables setup
GuildMPlusDB = GuildMPlusDB or {}
db = GuildMPlusDB

-- Event Handling
GuildMPlus:RegisterEvent("PLAYER_LOGIN")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED")
GuildMPlus:RegisterEvent("CHALLENGE_MODE_START")
GuildMPlus:RegisterEvent("ZONE_CHANGED_NEW_AREA")

GuildMPlus:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FF00[GuildM+] Addon Loaded!|r")  -- Green message to confirm addon load
        if not db.runs then db.runs = {} end

    elseif event == "CHALLENGE_MODE_START" then
        print("|cFFFFA500[GuildM+] M+ Timer Started!|r")  -- Orange message when M+ starts

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        GuildMPlus:LogRun()

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "party" then
            print("|cFFFFA500[GuildM+] Entered Dungeon.|r")
        end
    end
end)

-- Log M+ Run if criteria met
function GuildMPlus:LogRun()
    local runData = C_ChallengeMode.GetChallengeCompletionInfo()  -- Now returns a table

    if type(runData) ~= "table" then
        print("|cFFFF0000[GuildM+] Error: Unexpected return type from API. Exiting.|r")
        return
    end

    -- Extract values from the returned table
    local mapID = runData.mapChallengeModeID
    local level = runData.level
    local time = runData.time
    local onTime = runData.onTime  -- New field for in-time completion
    local members = runData.members

    print("M+ Run Detected!")
    print("mapID:", mapID)
    print("level:", level)
    print("time:", time)
    print("onTime:", onTime)
    print("members:", members)

    -- Check if the run was completed in time
    if not onTime then
        print("|cFFFF0000[GuildM+] Run was NOT in time according to API.|r")
        return
    end

    print("|cFF00FF00[GuildM+] Run was completed in time!|r")

    -- Ensure members exist
    if not members or type(members) ~= "table" then
        print("Error: Unable to retrieve run members. Exiting.")
        return
    end

    -- Guild check
    local playerGuild = GetGuildInfo("player")
    if not playerGuild then
        print("Player is not in a guild. Exiting.")
        return
    end

    local guildMembersInRun = {}
    for _, memberInfo in ipairs(members) do
        local fullName = memberInfo.name
        if C_GuildInfo.IsGuildMember(fullName) then
            table.insert(guildMembersInRun, fullName)
        end
    end

    if #guildMembersInRun == 0 then
        print("No guild members found in the run. Exiting.")
        return
    end

    -- Log the run
    table.insert(GuildMPlusDB.runs, {
        dungeon = C_ChallengeMode.GetMapUIInfo(mapID),
        level = level,
        time = time,
        date = date("%Y-%m-%d %H:%M:%S"),
        members = guildMembersInRun,
        points = level * 10
    })

    print("Run successfully logged!")
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
