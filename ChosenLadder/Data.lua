local CL, NS = ...

---@type Functions
local F = NS.Functions

---@class Data
---@field Constants DataConstants
---@field raidRoster RaidRosterInfo[]
---@field isLootMaster boolean
---@field lootMasterItems LootItem[]
---@field Auction Auction
---@field Dunk Dunk
---@field syncing number
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
    raidRoster = {},
    isLootMaster = false,
    lootMasterItems = {},
    syncing = 1
}
NS.Data = Data

---@param rows string[]
function Data:BuildPlayerList(rows)
    ---@type DatabasePlayer[]
    local newPlayers = {}

    for _, v in ipairs(rows) do
        local nameParts = F.Split(v, ":")
        if #nameParts >= 2 then
            ---@class DatabasePlayer
            ---@field id string
            ---@field name string
            ---@field guid string
            ---@field present boolean
            ---@field log string
            local player = {
                id = nameParts[1],
                name = nameParts[2],
                guid = nameParts[3] or "",
                present = false,
                log = ""
            }
            table.insert(newPlayers, player)
        else
            ChosenLadder:PrintToWindow("Invalid Import Data: " .. v)
        end
    end

    ChosenLadder:Database().factionrealm.ladder.players = newPlayers
    ChosenLadder:Database().factionrealm.ladder.lastModified = GetServerTime()
end

---@param localDebug? boolean
function Data:GenerateSyncData(localDebug)
    local timeMessage = Data.Constants.BeginSyncFlag .. ChosenLadder:Database().factionrealm.ladder.lastModified
    local channel = "RAID"

    local fullMessage = timeMessage .. "|"

    for _, player in ipairs(ChosenLadder:GetLadderPlayers()) do
        fullMessage = fullMessage .. player.name .. "|"
    end

    local endMessage = Data.Constants.EndSyncFlag
    fullMessage = fullMessage .. endMessage

    if localDebug then
        print(fullMessage)
    else
        ChosenLadder:SendMessage(fullMessage, channel)
    end
end

---@param playername string
---@return boolean
function Data:IsPlayerInRaid(playername)
    if playername ~= nil then
        for _, v in ipairs(Data.raidRoster) do
            if v.name == Ambiguate(playername, "all") then
                return true
            end
        end
    end

    return false
end

---@param id string
---@param guid string
function Data:SetPlayerGUIDByID(id, guid)
    local player = Data:GetPlayerByID(id)
    if player ~= nil then
        player.guid = guid
    else
        ChosenLadder:PrintToWindow(string.format("Selected Player unable to be found! %s - %s", player, guid))
    end
end

---@param id string
function Data:GetPlayerByID(id)
    ---@param player DatabasePlayer
    local player, playerloc = F.Find(ChosenLadder:GetLadderPlayers(), function(player) return player.id == id end)
    return player, playerloc
end

---@param guid string
---@return DatabasePlayer|nil
---@return integer|nil
function Data:GetPlayerByGUID(guid)
    guid = F.ShortenPlayerGuid(guid)
    ---@param player DatabasePlayer
    local player, playerloc = F.Find(ChosenLadder:GetLadderPlayers(), function(player) return player.guid == guid end)
    return player, playerloc
end

---@param id string
---@param present boolean
function Data:SetPresentById(id, present)
    local player = Data:GetPlayerByID(id)
    if player ~= nil then
        player.present = present
    end
end

---@param guid string
function Data:GetLootItemByGUID(guid)
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
