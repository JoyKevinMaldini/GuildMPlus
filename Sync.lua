-- 📡 Syncing for Guild M+ Leaderboard
local addonName, addonTable = ...
local Sync = {}
addonTable.Sync = Sync
local ADDON_PREFIX = "GuildMPlus"

-- 📡 **Broadcast Leaderboard to Guild**
function Sync:BroadcastLeaderboard()
    if not IsInGuild() then return end
    local encodedData = LibStub("AceSerializer-3.0"):Serialize(GuildMPlusDB.runs)
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, encodedData, "GUILD")
end

-- 🔄 **Handle Sync Requests & Data Reception**
function Sync:OnAddonMessage(_, prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end

    if message == "REQUEST" and sender ~= UnitFullName("player") then
        Sync:BroadcastLeaderboard()
        return
    end

    local success, receivedData = LibStub("AceSerializer-3.0"):Deserialize(message)

    if success and type(receivedData) == "table" then
        local addedRuns = 0

        for _, newRun in ipairs(receivedData) do
            local exists = false
            for _, existingRun in ipairs(GuildMPlusDB.runs) do
                if existingRun.id == newRun.id then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(GuildMPlusDB.runs, newRun)
                addedRuns = addedRuns + 1
            end
        end

        if addedRuns > 0 then
            GuildMPlusDB.lastSynced = date("%Y-%m-%d %H:%M:%S")
            print("|cFF00FF00[GuildM+] Synced " .. addedRuns .. " new runs from " .. sender .. "|r")
        end
    end
end

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
GuildMPlus:RegisterEvent("CHAT_MSG_ADDON")
GuildMPlus:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Sync:OnAddonMessage(...)
    end
end)