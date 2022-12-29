local CL, NS = ...

---@type Data
local D = NS.Data
---@type UI
local UI = NS.UI
---@type Functions
local F = NS.Functions

local Loot = UI.Loot

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

function Dunk:ClearDunk()
    Dunk.dunkItem = nil
    Dunk.dunks = {}
end

function Dunk:GetItemLink()
    if Dunk.dunkItem == nil then
        return nil
    end

    if F.IsItemLink(Dunk.dunkItem) then
        return Dunk.dunkItem
    end

    -- It's a guid, get the link
    local item = D:GetLootItemByGUID(Dunk.dunkItem)
    if item == nil or item.itemLink == nil then
        return nil
    end
    return item.itemLink
end

function Dunk:Cancel()
    if not D:IsLootMaster() then
        ChosenLadder:PrintToWindow("Error: Not the loot master!")
        return
    end

    local item = Dunk:GetItemLink()

    if item == nil then
        ChosenLadder:PrintToWindow("No current dunk session!")
        return
    end

    ChosenLadder:PutOnBlast("Cancelling dunk session for " .. Dunk:GetItemLink(),
        ChosenLadder:Database().char.announcements.dunkCancel)
    Dunk:ClearDunk()

    ChosenLadder:SendMessage(D.Constants.DunkEndFlag, "RAID")
end

---Forces the found player to the end of the list.
---@param id string
---@return LadderPlayer[]
---@return LadderPlayer|nil
---@return integer|nil
---@return integer
local function ProcessStandardDunk(id)
    local newPlayers = { unpack(ChosenLadder:GetLadder().players) }

    local found, foundPos =
    F.Find(
        newPlayers,
        function(p)
            return p.id == id
        end
    )

    if found ~= nil and foundPos ~= nil then
        table.remove(newPlayers, foundPos)
        table.insert(newPlayers, found)
    end

    return newPlayers, found, foundPos, #newPlayers
end

---Processes a 'Freezing' dunk, which means that players where 'present = false' are frozen into their current ladder spot.
---@param id string
---@return LadderPlayer[]
---@return LadderPlayer|nil
---@return integer|nil
---@return integer
local function ProcessFreezingDunk(id)
    local newPlayers = {}
    ---@type integer|nil
    local foundPos = nil
    local newPos = 1
    ---@type LadderPlayer|nil
    local found = nil
    local len = #ChosenLadder:GetLadder().players

    -- Initialize newPlayers with nulls, since we're inserting in weird places.
    for k = 1, len do
        newPlayers[k] = nil
    end

    for currentPos, v in pairs(ChosenLadder:GetLadder().players) do
        if id == v.id then
            -- Let's save this guy for later.
            found = v
            foundPos = currentPos
        else
            -- If we're not to the found player yet, just copy them straight over.
            if found == nil then
                newPlayers[newPos] = v
                newPos = newPos + 1
            elseif not v:IsPresent() then -- We've found a player, so we need to contend with players not present.
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

---Sorts Dunks by position
---@param dunks? DunkAttempt[]
function Dunk:Sort(dunks)
    dunks = dunks or Dunk.dunks
    ChosenLadder:Log("Dunk:Sort")
    ChosenLadder:Log(F.Dump(dunks))

    -- Strip out any nils (how did that happen in the first place?)
    local tempDumps = {}
    for i = 1, #dunks do
        if dunks[i] ~= nil then
            table.insert(tempDumps, dunks[i])
        end
    end
    dunks = tempDumps

    ---@param a DunkAttempt
    ---@param b DunkAttempt
    ---@return integer
    table.sort(dunks, function(a, b)
        local left = (a or { pos = 0 })
        local right = (b or { pos = 0 })

        return left.pos - right.pos
    end)
end

---Processes a Dunk
---@param id string ID of the player who wins
function Dunk:Complete(id)
    if not D:IsLootMaster() then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local item = Dunk:GetItemLink()

    if item == nil then
        ChosenLadder:PrintToWindow("No current dunk session!")
        return
    end

    local player = ChosenLadder:GetLadder():GetPlayerByID(id)

    if player == nil then
        ChosenLadder:PutOnBlast("ERROR: Missing player. Dunk Session Cancelled", false)
        ChosenLadder:PrintToWindow("Unable to find player by id: " .. id)
        return
    end

    local preprocessedDunks = { unpack(Dunk.dunks) }

    ChosenLadder:PutOnBlast(string.format("%s won by %s! Congrats!", item, player.name),
        ChosenLadder:Database().char.announcements.dunkComplete)

    local newPlayers, found, foundPos, targetPos = {}, nil, nil, nil
    if ChosenLadder:Database().profile.ladderType == D.Constants.LadderType["SK w/ Freezing"] then
        newPlayers, found, foundPos, targetPos = ProcessFreezingDunk(id)
    else
        newPlayers, found, foundPos, targetPos = ProcessStandardDunk(id)
    end

    if found == nil or foundPos == nil then
        error("Dunk:Complete found the player id initially, but could not after Processing.  HOW?!")
    end

    ChosenLadder:PrintToWindow(
        string.format("%s moved to position %d from position %d", found.name, targetPos, foundPos)
    )

    ChosenLadder:Database().factionrealm.ladder.players = newPlayers
    ChosenLadder:Database().factionrealm.ladder.lastModified = GetServerTime()

    local item = D:GetLootItemByGUID(Dunk.dunkItem) or { guid = Dunk.dunkItem }
    ---@class DunkHistoryItem
    ---@field playerName string
    ---@field from number
    ---@field to number
    ---@field item string
    local historyItem = {
        playerName = found.name,
        from = foundPos,
        to = targetPos,
        item = item.guid or Dunk.dunkItem
    }

    table.insert(Dunk.history, historyItem)

    local lootItem = D:GetLootItemByGUID(Dunk.dunkItem)
    if lootItem ~= nil then
        lootItem.sold = true
    end

    Dunk:ClearDunk()

    ChosenLadder:PrintToWindow("Registered Dunks:")
    Dunk:Sort(preprocessedDunks)
    for _, v in ipairs(preprocessedDunks) do
        ChosenLadder:PrintToWindow(string.format("%s - %d", v.player.name, v.pos))
    end

    UI.Loot:PopulateLootList()
    ChosenLadder:SetInventoryOverlays()

    D:GenerateSyncData(false)
    ChosenLadder:SendMessage(D.Constants.DunkEndFlag, "RAID")
end

---@param dunkItem string Item link or GUID
function Dunk:Start(dunkItem)
    if not D:IsLootMaster() then
        ChosenLadder:PrintToWindow("Error: Not the loot master!")
        return
    end

    if Dunk.dunkItem ~= nil then
        local itemLink = Dunk:GetItemLink()
        ChosenLadder:PrintToWindow("Error: Still running a dunk session for " .. (itemLink or "UNKNOWN"))
        return
    end

    if D.Auction.auctionItem ~= nil then
        local itemLink = D.Auction:GetItemLink();
        ChosenLadder:PrintToWindow("Error: Still running an auction for " .. (itemLink or "UNKNOWN"))
    end

    Dunk:ClearDunk()
    Dunk.dunkItem = dunkItem
    local itemLink = Dunk:GetItemLink() or "UNKNOWN"
    ChosenLadder:SendMessage(D.Constants.DunkStartFlag .. "|" .. itemLink, "RAID")
    ChosenLadder:PutOnBlast(string.format("Beginning Dunks for %s, please whisper DUNK to %s", itemLink,
        UnitName("player")), ChosenLadder:Database().char.announcements.dunkStart)
    UI.Loot:PopulateLootList()
end

---Registers a dunk by a player's guid, returns their position in the list (0 if none)
---@param guid string
---@return integer
function Dunk:RegisterByGUID(guid)
    local player, pos = ChosenLadder:GetLadder():GetPlayerByGUID(guid)
    if player ~= nil and pos ~= nil then
        ---@class DunkAttempt
        ---@field player LadderPlayer
        ---@field pos integer
        local dunkAttempt = { player = player, pos = pos }
        table.insert(Dunk.dunks, dunkAttempt)
        return pos
    end

    return 0
end
