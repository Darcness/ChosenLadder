local CL, NS = ...

---@type Data
local D = NS.Data
---@type UI
local UI = NS.UI
---@type Functions
local F = NS.Functions

---@class Dunk
---@field dunkItem? string
---@field dunks DunkAttempt[]
---@field history DunkHistoryItem[]
local Dunk = {
    dunkItem = nil,
    dunks = {},
    history = {}
}
D.Dunk = Dunk

local function clearData(obj)
    obj.dunkItem = nil
    obj.dunks = {}
end

function Dunk:GetItemLink()
    if self.dunkItem ~= nil and F.StartsWith(self.dunkItem, "Item-4648-0-") then
        -- It's a guid, get the link
        local item = D:GetLootItemByGUID(self.dunkItem)
        if item == nil or item.itemLink == nil then
            return nil
        end
        return item.itemLink
    end

    return self.dunkItem
end

---@param forceId? string
function Dunk:CompleteAnnounce(forceId)
    if not D.isLootMaster then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local item = self:GetItemLink()

    if item == nil then
        ChosenLadder:PrintToWindow("No current dunk session!")
        return
    end

    if #self.dunks < 1 then
        SendChatMessage("Cancelling dunk session for " .. self:GetItemLink(), "RAID")
    else
        table.sort(self.dunks, function(i1, i2)
            return i1.pos < i2.pos
        end)

        local id = forceId or self.dunks[0].player.id
        local player = D:GetPlayerByID(id)

        if player ~= nil then
            SendChatMessage(string.format("%s won by %s! Congrats!", item, player.name), "RAID")
        else
            SendChatMessage("ERROR: Missing player. Dunk Session Cancelled", "RAID")
            ChosenLadder:PrintToWindow("Unable to find player by id: " .. id)
        end
    end
end

---Forces the found player to the end of the list.
---@param id string
---@return DatabasePlayer[]
---@return DatabasePlayer|nil
---@return integer|nil
---@return integer
local function ProcessStandardDunk(id)
    local newPlayers = { unpack(ChosenLadder:GetLadderPlayers()) }

    local found, foundPos = F.Find(newPlayers, function(p) return p.id == id end)

    if found ~= nil and foundPos ~= nil then
        table.remove(newPlayers, foundPos)
        table.insert(newPlayers, found)
    end

    return newPlayers, found, foundPos, #newPlayers
end

---Processes a 'Freezing' dunk, which means that players where 'present = false' are frozen into their current ladder spot.
---@param id string
---@return DatabasePlayer[]
---@return DatabasePlayer|nil
---@return integer|nil
---@return integer
local function ProcessFreezingDunk(id)
    local newPlayers = {}
    ---@type integer|nil
    local foundPos = nil
    local newPos = 1
    ---@type DatabasePlayer|nil
    local found = nil
    local len = #ChosenLadder:GetLadderPlayers()

    -- Initialize newPlayers with nulls, since we're inserting in weird places.
    for k = 1, len do
        newPlayers[k] = nil
    end

    for currentPos, v in pairs(ChosenLadder:GetLadderPlayers()) do
        if id == v.id then
            -- Let's save this guy for later.
            found = v
            foundPos = currentPos
        else
            -- If we're not to the found player yet, just copy them straight over.
            if found == nil then
                newPlayers[newPos] = v
                newPos = newPos + 1
            elseif not v.present then -- We've found a player, so we need to contend with players not present.
                -- Not present player, shove them into their current slot
                newPlayers[currentPos] = v
            else
                -- This is where it gets hinky.
                -- insert into the current spot UNLESS an object is already there. If it is, push forward and try again.
                while newPlayers[newPos] ~= nil do
                    newPos = newPos + 1
                end
                -- Finally found an empty spot! Insert, move the pointer, and continue.
                newPlayers[newPos] = v
                newPos = newPos + 1
            end
        end
    end

    local targetPos = 0

    if found ~= nil then
        -- There should be one empty spot (probably near the bottom).  Let's find it and put the dunker there.
        for i = 1, len do
            if newPlayers[i] == nil then
                newPlayers[i] = found
                targetPos = i
                break
            end
        end
    end

    return newPlayers, found, foundPos, targetPos
end

function Dunk:CompleteProcess(id)
    ChosenLadder:PrintToWindow("Registered Dunks:")

    -- We're assuming the list is already sorted by now.
    for _, v in ipairs(self.dunks) do
        ChosenLadder:PrintToWindow(string.format("%s - %d", v.player.name, v.pos))
    end

    local newPlayers, found, foundPos, targetPos = {}, nil, nil, nil

    if ChosenLadder:Database().profile.ladderType == D.Constants.LadderType["SK w/ Freezing"] then
        newPlayers, found, foundPos, targetPos = ProcessFreezingDunk(id)
    else
        newPlayers, found, foundPos, targetPos = ProcessStandardDunk(id)
    end

    if found == nil or foundPos == nil then
        error("Unable to find player by id " .. id)
    end

    ChosenLadder:PrintToWindow(string.format("%s moved to position %d from position %d",
        found.name, targetPos, foundPos))

    ChosenLadder:Database().factionrealm.ladder.players = newPlayers
    ChosenLadder:Database().factionrealm.ladder.lastModified = GetServerTime()

    local item = D:GetLootItemByGUID(self.dunkItem) or { guid = self.dunkItem }
    ---@class DunkHistoryItem
    ---@field player DatabasePlayer
    ---@field from number
    ---@field to number
    ---@field item string
    local historyItem = {
        player = found,
        from = foundPos,
        to = targetPos,
        item = item.guid or self.dunkItem
    }

    table.insert(self.history, historyItem)

    -- This will no-op if self.dunkItem is an itemLink
    D:RemoveLootItemByGUID(self.dunkItem)
    UI.Loot:PopulateLootList()

    clearData(self)

    D:GenerateSyncData(false)
end

function Dunk:Start(dunkItem)
    clearData(self)
    self.dunkItem = dunkItem
    SendChatMessage(
        string.format("Beginning Dunks for %s, please whisper DUNK to %s", self:GetItemLink(), UnitName("player")),
        "RAID_WARNING"
    )
end

function Dunk:RegisterByGUID(guid)
    local player, pos = D:GetPlayerByGUID(guid)
    if player ~= nil and pos ~= nil then
        ---@class DunkAttempt
        ---@field player DatabasePlayer
        ---@field pos integer
        local dunkAttempt = { player = player, pos = pos }
        table.insert(self.dunks, dunkAttempt)
        return pos
    end

    return 0
end
