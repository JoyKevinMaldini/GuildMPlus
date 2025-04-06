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
    end

    frame.syncInfo:SetText("Last Synced: " .. (GuildMPlusDB.lastSynced or "Never"))
    frame:Show()
end
