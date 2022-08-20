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

    local fullMessage = string.format("%s|%s|%s", timeMessage, string.gsub(Data:FormatNames(), "\n", "|"),
        Data.Constants.EndSyncFlag)

    if localDebug then
        print(fullMessage)
    else
        ChosenLadder:SendMessage(fullMessage, channel)
    end
end

---@return RaidRoster
function Data:GetRaidRoster()
    if(self.raidMembers == nil) or (self.raidMembers.members == nil) then
        self.raidMembers = RaidRoster:new()
    end
    return self.raidMembers
end

---@param id string
---@param guid string
function Data:SetPlayerGUIDByID(id, guid)
    local player = Data:GetPlayerByID(id)
    if player ~= nil then
        player:AddGuid(guid)
    else
        ChosenLadder:PrintToWindow(string.format("Selected Player unable to be found! %s - %s", player, guid))
    end
end

---@param id string
function Data:GetPlayerByID(id)
    ---@param player LadderPlayer
    local player, playerloc = F.Find(ChosenLadder:GetLadder().players, function(player) return player.id == id end)
    return player, playerloc
end

---@param guid string
---@return LadderPlayer|nil
---@return integer|nil
function Data:GetPlayerByGUID(guid)
    guid = F.ShortenPlayerGuid(guid)
    local player, playerloc = F.Find(ChosenLadder:GetLadder().players,
        ---@param player LadderPlayer
        function(player) return player:CurrentGuid() == guid end)
    return player, playerloc
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

---Formats the Ladder names for backup/restore
---@return string
function Data:FormatNames()
    local names = {}
    for k, v in pairs(ChosenLadder:GetLadder().players) do
        table.insert(names, string.format("%s:%s:%s", v.id, v.name, table.concat(v.guids, "-")))
    end
    return table.concat(names, "\n")
end
