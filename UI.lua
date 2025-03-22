-- 🏆 UI for Guild M+ Leaderboard
local addonName, addonTable = ...
local UI = {}
addonTable.UI = UI

-- 🏆 **Leaderboard UI**
function UI:ShowLeaderboard()
    local frame = CreateFrame("Frame", "GuildMPlusLeaderboard", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(300, 400)
    frame:SetPoint("CENTER")

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.title:SetText("Guild M+ Leaderboard")

    frame.syncInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.syncInfo:SetPoint("TOP", frame, "TOP", 0, -30)
    frame.syncInfo:SetText("Last Synced: " .. (GuildMPlusDB.lastSynced or "Never"))

    local syncButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    syncButton:SetSize(100, 25)
    syncButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    syncButton:SetText("Sync Now")
    syncButton:SetScript("OnClick", function()
        C_ChatInfo.SendAddonMessage("GuildMPlus", "REQUEST", "GUILD")
    end)
end

SLASH_GMPLUS1 = "/gmplus"
SlashCmdList["GMPLUS"] = function() UI:ShowLeaderboard() end