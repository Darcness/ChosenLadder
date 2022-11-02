local CL, NS = ...

---@type Functions
local F = NS.Functions

---@class Data
---@field Constants DataConstants
---@field isLootMaster boolean
---@field lootMasterItems LootItem[]
---@field Auction Auction
---@field Dunk Dunk
---@field syncing number
---@field raidMembers RaidRoster
local Data = {
    ---@class DataConstants
    ---@field BeginSyncFlag string
    ---@field EndSyncFlag string
    ---@field AsheosWords string[]
    ---@field StreamFlag table<string, number>
    ---@field LadderType table<string, number>
    Constants = {
        BeginSyncFlag = "BEGIN SYNC:",
        EndSyncFlag = "END SYNC",
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
            "drunk"
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
    lootMasterItems = {},
    syncing = 1,
    raidMembers = RaidRoster:new()
}
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

---@param guid string
function Data:GetLootItemByGUID(guid)
    ---@param item LootItem
    local loot, lootloc = F.Find(Data.lootMasterItems, function(item) return item.guid == guid end)
    return loot, lootloc
end

---@param guid string
function Data:RemoveLootItemByGUID(guid)
    local newItems = {}
    for _, item in pairs(Data.lootMasterItems) do
        if item.guid ~= guid then
            table.insert(newItems, item)
        end
    end
    Data.lootMasterItems = newItems
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

function Data:UpdateRaidData()
    local lootMethod, masterLooterPartyId, _ = GetLootMethod()
    Data.isLootMaster = (lootMethod == "master" and masterLooterPartyId == 0)

    local raidMembers = Data:GetRaidRoster();
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
            if myPlayer ~= nil then
                myPlayer:SetGuid(rosterInfo.shortGuid)
            end
        end
        i = i + 1
    end
end
