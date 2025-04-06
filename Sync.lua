-- 📡 Syncing for Guild M+ Leaderboard
local addonName, addonTable = ...
local Sync = {}
addonTable.Sync = Sync
local ADDON_PREFIX = "GuildMPlus"

print("|cFF00FFFF[GuildM+] Sync module loaded.|r")

-- 🧩 Get GuildMPlus frame from core
local GuildMPlus = addonTable.GuildMPlus
if not GuildMPlus then
    print("|cFFFF0000[GuildM+] Sync error: Core module not loaded.|r")
    return
end

-- Load LibStub first (this is already automatically available in WoW)
-- 📡 Load AceSerializer-3.0 using LibStub
local AceSerializer = LibStub("AceSerializer-3.0")

-- 📡 Register message prefix and event
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
GuildMPlus:RegisterEvent("CHAT_MSG_ADDON")

GuildMPlus:HookScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Sync:OnAddonMessage(...)
    end
end)

-- 📡 **Broadcast Leaderboard to Guild**
function Sync:BroadcastLeaderboard()
    if not IsInGuild() then return end
    local encodedData = AceSerializer:Serialize(GuildMPlusDB.runs)
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, encodedData, "GUILD")
end

-- 🔄 **Handle Sync Requests & Data Reception**
function Sync:OnAddonMessage(_, prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end

    if message == "REQUEST" and sender ~= UnitFullName("player") then
        Sync:BroadcastLeaderboard()
        return
    end

    local success, receivedData = AceSerializer:Deserialize(message)

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
