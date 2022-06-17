local CL, NS = ...

local D = NS.Data
local F = NS.Functions

D.raidRoster = {}

function BuildPlayerList(names)
    LootLadder.players = {}

    for _, v in ipairs(names) do
        table.insert(
            LootLadder.players,
            {
                name = v,
                present = false,
                log = ""
            }
        )
    end

    LootLadder.lastModified = GetServerTime()
end

D.BuildPlayerList = BuildPlayerList

function RegisterDunkByGUID(guid)
    for k, v in ipairs(LootLadder.players) do
        if v.guid == guid then
            table.insert(
                D.dunkNames,
                {
                    guid = v.guid,
                    name = v.name,
                    pos = k
                }
            )
        end
    end
end

D.RegisterDunkByGUID = RegisterDunkByGUID

function RunDunk(name)
    if D.isLootMaster == nil or D.isLootMaster == false then
        SendChatMessage(
            string.format("%s: %s has attempted to DUNK via illegal calls to addon code", CL, UnitName("player")),
            "RAID_WARNING"
        )
    end
    local newPlayers = {}
    -- Initialize newPlayers with nulls, since we're inserting in weird places.
    for k, v in pairs(LootLadder.players) do
        newPlayers[k] = nil
    end

    local foundPos = 1
    local newPos = 1
    local found = nil
    local len = #LootLadder.players

    for currentPos, v in pairs(LootLadder.players) do
        if name == v.name then
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
            print(found.name .. " moved to position " .. targetPos .. " from position " .. foundPos)
        end
    end

    LootLadder.players = newPlayers
    LootLadder.lastModified = GetServerTime()
    table.insert(
        D.ladderHistory,
        {
            name = found.name,
            from = foundPos,
            to = targetPos
        }
    )
    GenerateSyncData(false)
end

D.RunDunk = RunDunk

function CompleteDunk()
    local winnerPos = 9999
    local winnerName = ""
    self:Print("Registered Dunks:")
    for k, v in ipairs(D.dunkNames) do
        self:Print(string.format("%s - %d", v.name, v.pos))
        if v.pos < winnerPos then
            winnerName = v.name
            winnerPos = v.pos
        end
    end

    D.dunkItem = nil
    D.dunkNames = {}

    RunDunk(winnerName)
end

D.CompleteDunk = CompleteDunk

function TogglePresent(name)
    for _, v in ipairs(LootLadder.players) do
        if name == v.name then
            v.present = not v.present
            return
        end
    end
end

D.TogglePresent = TogglePresent

function GenerateSyncData(localDebug)
    local timeMessage = D.Constants.BeginSyncFlag .. LootLadder.lastModified
    local channel = "RAID"

    local fullMessage = timeMessage .. "|"

    for k, v in ipairs(LootLadder.players) do
        fullMessage = fullMessage .. v.name .. "|"
    end

    local endMessage = D.Constants.EndSyncFlag
    fullMessage = fullMessage .. endMessage

    if localDebug then
        print(fullMessage)
    else
        ChosenLadder:SendMessage(fullMessage, channel)
    end
end

D.GenerateSyncData = GenerateSyncData

function IsPlayerInRaid(playername)
    for k, v in ipairs(D.raidRoster) do
        if v[1] == Ambiguate(playername, "all") then
            return true
        end
    end

    return false
end

D.IsPlayerInRaid = IsPlayerInRaid

function SetPlayerGUIDByPosition(pos, guid)
    -- Might be a string, let's force a cleanup
    local correctPos = nil
    if type(pos) == "string" then
        correctPos = tonumber(pos)
    else
        correctPos = pos
    end

    local player = LootLadder.players[correctPos]
    if player ~= nil then
        player.guid = guid
        print(string.format("SetPlayerGUIDByPosition - %d - %s", correctPos, guid))
    else
        print("It went all fucky")
    end
end

D.SetPlayerGUIDByPosition = SetPlayerGUIDByPosition

function CompleteAuction()
    if D.auctionItem == nil then
        self:Print("No auction has begun!")
        return
    end

    if D.currentWinner == nil then
        SendChatMessage("Auction Canceled by " .. UnitName("player") .. "!", "RAID_WARNING")
        D.auctionItem = nil
        return
    end

    local bid = 0
    if D.currentBid ~= nil and D.currentBid > 0 then
        bid = D.currentBid
    end

    SendChatMessage(
        string.format(
            "Auction Complete! %s wins %s for %d gold!",
            Ambiguate(D.currentWinner, "all"),
            D.auctionItem,
            bid
        ),
        "RAID_WARNING"
    )

    table.insert(
        D.auctionHistory,
        {
            name = D.currentWinner,
            bid = D.currentBid,
            item = D.auctionItem
        }
    )

    D.currentWinner = nil
    D.auctionItem = nil
    D.currentBid = 0
end

D.CompleteAuction = CompleteAuction
