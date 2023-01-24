local CL, NS = ...

---@type Functions
local F = NS.Functions

---@class Data
---@field Constants DataConstants
---@field isLootMaster boolean
---@field isLootMasterOverride boolean
---@field lootMasterItems LootList
---@field isTestMode boolean
---@field Auction Auction
---@field Dunk Dunk
---@field syncing number
---@field raidMembers RaidRoster
local Data = {
    ---@class DataConstants
    ---@field AsheosWords string[]
    ---@field StreamFlag table<string, number>
    ---@field LadderType table<string, number>
    Constants = {
        BeginSyncFlag = "BEGIN SYNC:",
        EndSyncFlag = "END SYNC",
        AuctionStartFlag = "AUCTION START",
        AuctionEndFlag = "AUCTION END",
        DunkStartFlag = "DUNK START",
        DunkEndFlag = "DUNK END",
        LootListFlag = "LOOT LIST",
        AsheosWords = {
            "dunk",
            "sunk",
            "funk",
            "dink",
            "dynk",
            "dumk",
            "dubk",
            "dunl",
            "duni",
            "dunm",
            "dlunk",
            "drunk",
            "dukn"
        },
        StreamFlag = {
            Empty = 1,
            Started = 2,
            Complete = 3
        },
        LadderType = {
            ["SK Simple"] = 1,
            ["SK w/ Freezing"] = 2
        }
    },
    isLootMaster = false,
    isLootMasterOverride = false,
    isTestMode = false,
    syncing = 1,
    raidMembers = RaidRoster:new()
}
Data.lootMasterItems = LootList:new(Data)
NS.Data = Data

---@param localDebug? boolean
function Data:GenerateSyncData(localDebug)
    local timeMessage = Data.Constants.BeginSyncFlag .. ChosenLadder:Database().factionrealm.ladder.lastModified
    local channel = "RAID"

    local fullMessage = string.format("%s|%s|%s", timeMessage,
        string.gsub(ChosenLadder:GetLadder():FormatNames(), "\n", "|"),
        Data.Constants.EndSyncFlag)

    if localDebug then
        print(fullMessage)
    else
        ChosenLadder:SendMessage(fullMessage, channel)
    end
end

---@return RaidRoster
function Data:GetRaidRoster()
    if (Data.raidMembers == nil) or (Data.raidMembers.members == nil) then
        Data.raidMembers = RaidRoster:new()
    end
    return Data.raidMembers
end

---@return string
function Data:GetPrintableBidSteps()
    local stepLabels = {}
    for i, stepData in ipairs(ChosenLadder:Database().factionrealm.bidSteps) do
        table.insert(stepLabels, string.format("%d:%d", stepData.start, stepData.step))
    end

    return table.concat(stepLabels, "|")
end

---@param input string
function Data:SetBidSteps(input)
    ---@type DatabaseBidStep[]
    local newSteps = {}
    for _, group in ipairs(F.Split(input, "|")) do
        local values = F.Split(group, ":")
        local start = tonumber(values[1])
        local step = tonumber(values[2])
        if #values == 2 and start ~= nil and step ~= nil then
            ---@class DatabaseBidStep
            ---@field start number
            ---@field step number
            local bidStep = {
                start = start,
                step = step
            }
            table.insert(newSteps, bidStep)
        end
    end

    ChosenLadder:Database().factionrealm.bidSteps = newSteps
end

---Updates the Raid Data
---@return boolean shouldUpdateUI
function Data:UpdateRaidData()
    local lootMethod, masterLooterPartyId, _ = GetLootMethod()
    Data.isLootMaster = (lootMethod == "master" and masterLooterPartyId == 0)

    local raidMembers = Data:GetRaidRoster()
    local oldRaidCount = 0
    for _ in pairs(raidMembers) do oldRaidCount = oldRaidCount + 1 end
    raidMembers:Clear();

    local i = 1
    local done = false
    while i <= MAX_RAID_MEMBERS and not done do
        local rosterInfo = RaidMember:CreateByRaidIndex(i)
        -- Break early if we hit a nil (this means we've reached the full number of players)
        if rosterInfo == nil then
            done = true
        else
            raidMembers.members[rosterInfo.shortGuid] = rosterInfo
            ---@param a LadderPlayer
            local myPlayer = F.Find(ChosenLadder:GetLadder().players, function(a) a:HasGuid(rosterInfo.shortGuid) end)
            if myPlayer ~= nil and myPlayer:CurrentGuid() ~= rosterInfo.shortGuid then
                myPlayer:SetCurrentGuid(rosterInfo.shortGuid)
            end
        end
        i = i + 1
    end

    return oldRaidCount ~= GetNumGroupMembers()
end

function Data:IsLootMaster()
    return Data.isLootMaster or Data.isLootMasterOverride or false
end
