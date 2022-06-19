local CL, NS = ...

local D = NS.Data
local F = NS.Functions

D.raidRoster = {}
D.dunks = {}

function BuildPlayerList(rows)
    LootLadder.players = {}

    for _, v in ipairs(rows) do
        local nameParts = F.Split(v, ":")
        if #nameParts >= 2 then
            table.insert(
                LootLadder.players,
                {
                    id = nameParts[1],
                    name = nameParts[2],
                    guid = nameParts[3],
                    log = ""
                }
            )
        else
            ChosenLadder:Print("Invalid Import Data: " .. v)
        end
    end

    LootLadder.lastModified = GetServerTime()
end

D.BuildPlayerList = BuildPlayerList

function RegisterDunkByGUID(guid)
    local player, pos = GetPlayerByGUID(guid)
    if player ~= nil and pos > 0 then
        table.insert(D.dunks, { player = player, pos = pos })
        return pos
    end

    return 0
end

D.RegisterDunkByGUID = RegisterDunkByGUID

function RunDunk(id)
    if D.isLootMaster == nil or D.isLootMaster == false then
        SendChatMessage(
            string.format("%s: %s has attempted to DUNK via illegal calls to addon code", CL, UnitName("player")),
            "RAID_WARNING"
        )
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
        D.ladderHistory,
        {
            player = found,
            from = foundPos,
            to = targetPos
        }
    )
    GenerateSyncData(false)
end

D.RunDunk = RunDunk

function CompleteDunk(id)
    self:Print("Registered Dunks:")

    table.sort(D.dunks, function(i1, i2)
        return i1.pos > i2.pos
    end)

    for _, v in ipairs(D.dunks) do
        self:Print(string.format("%s - %d", v.player.name, v.pos))
    end

    D.dunkItem = nil
    D.dunks = {}

    RunDunk(id)
end

D.CompleteDunk = CompleteDunk

function GenerateSyncData(localDebug)
    local timeMessage = D.Constants.BeginSyncFlag .. LootLadder.lastModified
    local channel = "RAID"

    local fullMessage = timeMessage .. "|"

    for _, player in ipairs(LootLadder.players) do
        fullMessage = fullMessage .. player.name .. "|"
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

function SetPlayerGUIDByID(id, guid)
    -- Might be a string, let's force a cleanup
    local correctID = nil
    if type(id) == "string" then
        correctID = tonumber(id)
    else
        correctID = id
    end

    local player = GetPlayerByID(id)
    if player ~= nil then
        player.guid = guid
    else
        print("It went all fucky")
    end
end

D.SetPlayerGUIDByID = SetPlayerGUIDByID

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

function ShortenGuid(guid)
    return string.gsub(guid, "Player%-4648%-", "")
end

D.ShortenGuid = ShortenGuid

function GetPlayerByID(id)
    for k, v in ipairs(LootLadder.players) do
        if v.id == id then
            return v, k
        end
    end

    return nil, 0
end

D.GetPlayerByID = GetPlayerByID

function GetPlayerByGUID(guid)
    guid = ShortenGuid(guid)
    for k, v in ipairs(LootLadder.players) do
        if v.guid == guid then
            return v, k
        end
    end

    return nil, 0
end

D.GetPlayerByGUID = GetPlayerByGUID
