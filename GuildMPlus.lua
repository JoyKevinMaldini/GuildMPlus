-- Guild M+ Leaderboard Addon
local addonName, addonTable = ...
local GuildMPlus = CreateFrame("Frame")
local db

-- SavedVariables setup
GuildMPlusDB = GuildMPlusDB or {}
db = GuildMPlusDB

-- Event Handling
GuildMPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED")
GuildMPlus:RegisterEvent("PLAYER_LOGIN")

GuildMPlus:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if not db.runs then db.runs = {} end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        GuildMPlus:LogRun()
    end
end)

-- Log M+ Run if criteria met
function GuildMPlus:LogRun()
    local mapID, level, time, onTime, _, _, _, members = C_ChallengeMode.GetCompletionInfo()
    print("M+ Run Detected!")  -- Debug message

    if not onTime then
        print("Run was not in time. Ignoring.")
        return
    end

    local playerGuild = GetGuildInfo("player")
    print("Player's Guild: ", playerGuild)

    if not playerGuild then
        print("Player is not in a guild. Exiting.")
        return
    end

    local guildMembersInRun = {}
    for _, memberInfo in ipairs(members) do
        local fullName = memberInfo.name  -- Includes realm (e.g., "Player-Realm")
        print("Checking party member: ", fullName)

        if C_GuildInfo.IsGuildMember(fullName) then
            print("Guild member detected: ", fullName)
            table.insert(guildMembersInRun, fullName)
        else
            print(fullName .. " is NOT a guild member.")
        end
    end

    if #guildMembersInRun == 0 then
        print("No guild members found in the run. Exiting.")
        return
    end

    print("Logging run to database...")
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
