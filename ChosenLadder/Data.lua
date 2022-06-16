local CL, NS = ...

local D = NS.Data

function BuildPlayerList(names)
    LootLadder.players = {}

    for _, v in ipairs(names) do
        table.insert(LootLadder.players, {
            name = v,
            present = false,
            log = ""
        })
    end
end

D.BuildPlayerList = BuildPlayerList

function RunDunk(name)
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

    -- There should be one empty spot (probably near the bottom).  Let's find it and put the dunker there.
    for i = 1, len do
        if newPlayers[i] == nil then
            newPlayers[i] = found
            print(found.name .. " moved to position " .. i .. " from position " .. foundPos)
        end
    end

    LootLadder.players = newPlayers
    D.lastModified = GetServerTime()
    GenerateSyncData(false)
end

D.RunDunk = RunDunk

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
    local timeMessage = D.Constants.BeginSyncFlag .. D.lastModified
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
        ChosenLadder:Print("Submitting Sync Request")
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

function CompleteAuction()
    table.insert(D.auctionHistory, {
        name = D.currentWinner,
        bid = D.currentBid,
        item = D.auctionItem
    })

    SendChatMessage("Auction Complete! " .. Ambiguate(D.currentWinner, "all") .. " wins " .. D.auctionItem .. " for " .. D.currentBid .. " gold!", "RAID_WARNING")
    D.auctionItem = nil
    D.currentBid = 0
end

D.CompleteAuction = CompleteAuction
