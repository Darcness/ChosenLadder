local CL, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

D.Dunk = {
    dunkItem = nil,
    dunks = {},
    history = {}
}
local Dunk = D.Dunk

local function clearData(obj)
    obj.dunkItem = nil
    obj.dunks = {}
end

function Dunk:GetItemLink()
    if self.dunkItem == nil then
        return nil
    end

    if F.StartsWith(self.dunkItem.guid, "Item-4648-0-") then
        local item = D.GetLootItemByGUID(self.dunkItem.guid)
        if item == nil or item.itemLink == nil then
            return nil
        end
        return item.itemLink
    end

    return self.dunkItem
end

function Dunk:CompleteAnnounce(forceId)
    if not D.isLootMaster then
        ChosenLadder:Print("You're not the loot master!")
        return
    end

    local item = self:GetDunkItemLink()

    if item == nil then
        ChosenLadder:Print("No current dunk session!")
        return
    end

    if #self.dunks < 1 then
        SendChatMessage("Cancelling dunk session for " .. self:GetDunkItemLink(), "RAID")
    else
        table.sort(self.dunks, function(i1, i2)
            return i1.pos < i2.pos
        end)

        local id = forceId or self.dunks[0].player.id

        local player = D.GetPlayerById(id)

        SendChatMessage(string.format("%s won by %s! Congrats!", item, player.name))
    end
end

function Dunk:CompleteProcess(id)
    ChosenLadder:Print("Registered Dunks:")

    -- We're assuming the list is already sorted by now.
    for _, v in ipairs(self.dunks) do
        ChosenLadder:Print(string.format("%s - %d", v.player.name, v.pos))
    end

    local newPlayers = {}
    -- Initialize newPlayers with nulls, since we're inserting in weird places.
    for k, _ in pairs(LootLadder.players) do
        newPlayers[k] = nil
    end

    local foundPos = 1
    local newPos = 1
    local found = nil
    local len = #LootLadder.players

    for currentPos, v in pairs(LootLadder.players) do
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

    -- There should be one empty spot (probably near the bottom).  Let's find it and put the dunker there.
    for i = 1, len do
        if newPlayers[i] == nil then
            newPlayers[i] = found
            targetPos = i
            ChosenLadder:Print(found.name .. " moved to position " .. targetPos .. " from position " .. foundPos)
        end
    end

    LootLadder.players = newPlayers
    LootLadder.lastModified = GetServerTime()
    table.insert(
        self.history,
        {
            player = found,
            from = foundPos,
            to = targetPos,
            item = D.GetLootItemByGUID(self.dunkItem) or self.dunkItem
        }
    )

    -- This will no-op if self.dunkItem is an itemLink
    D.RemoveLootItemByGUID(self.dunkItem)
    UI.Loot:PopulateLootList()

    clearData(self)

    D.GenerateSyncData(false)
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
    local player, pos = D.GetPlayerByGUID(guid)
    if player ~= nil and pos > 0 then
        table.insert(self.dunks, { player = player, pos = pos })
        return pos
    end

    return 0
end
