-- 🏆 UI for Guild M+ Leaderboard
local addonName, addonTable = ...
local UI = {}
addonTable.UI = UI

print("|cFF00FFFF[GuildM+] UI module loaded.|r")

-- === 🖼️ Persistent Frame ===
local frame

-- Slash command
SLASH_GMPLUS1 = "/gmplus"
SlashCmdList["GMPLUS"] = function()
    UI:ShowLeaderboard()
end

-- === 🏆 Leaderboard UI ===
function UI:ShowLeaderboard()
    if not frame then
        frame = CreateFrame("Frame", "GuildMPlusLeaderboard", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(320, 420)
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:SetClampedToScreen(true)

        -- Title
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
        frame.title:SetText("Guild M+ Leaderboard")

        -- Last Sync Info
        frame.syncInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.syncInfo:SetPoint("TOP", frame, "TOP", 0, -30)

        -- Sync Button
        local syncButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        syncButton:SetSize(100, 25)
        syncButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
        syncButton:SetText("Sync Now")
        syncButton:SetScript("OnClick", function()
            print("|cFF00FFFF[GuildM+] Sending sync request...|r")
            C_ChatInfo.SendAddonMessage("GuildMPlus", "REQUEST", "GUILD")
        end)

        -- ScrollFrame for leaderboard
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(280, 300)
        scrollFrame:SetPoint("TOP", frame, "TOP", 0, -60)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(260, 1) -- initially small, will expand as needed
        scrollFrame:SetScrollChild(content)

        -- Populate the leaderboard
        local leaderboard = UI:GetLeaderboard()
        if #leaderboard == 0 then
            local noDataMessage = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noDataMessage:SetPoint("TOP", content, "TOP", 0, -5)
            noDataMessage:SetText("No data logged yet.")
        else
            local yOffset = -5
            for _, member in ipairs(leaderboard) do
                local entry = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                entry:SetPoint("TOP", content, "TOP", 0, yOffset)
                entry:SetText(member.name .. " - " .. member.points .. " Points")
                yOffset = yOffset - 20
            end
        end
    end

    frame.syncInfo:SetText("Last Synced: " .. (GuildMPlusDB.lastSynced or "Never"))
    frame:Show()
end

-- Function to retrieve sorted leaderboard data
function UI:GetLeaderboard()
    -- Initialize the leaderboard table
    local leaderboard = {}

    -- Calculate the points for each member based on the logged runs
    for _, run in ipairs(GuildMPlusDB.runs) do
        local points = run.points  -- Points for this run
        for _, member in ipairs(run.members) do
            if not leaderboard[member] then
                leaderboard[member] = 0  -- Initialize the player's points if not already done
            end
            leaderboard[member] = leaderboard[member] + points  -- Add the points from this run to the player's total
        end
    end

    -- Sort the leaderboard by points (descending)
    local sortedLeaderboard = {}
    for member, points in pairs(leaderboard) do
        table.insert(sortedLeaderboard, { name = member, points = points })
    end

    table.sort(sortedLeaderboard, function(a, b) return a.points > b.points end)

    return sortedLeaderboard
end
