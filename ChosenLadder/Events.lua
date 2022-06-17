local A, NS = ...

local UI = NS.UI
local D = NS.Data

local StreamFlag = NS.Data.Constants.StreamFlag

function GetMinimumBid()
    local currentBid = D.currentBid or 0
    if currentBid < 50 then
        return 50
    elseif currentBid < 300 then
        return currentBid + 10
    elseif currentBid < 1000 then
        return currentBid + 50
    else
        return currentBid + 100
    end
end

function ChosenLadder:GROUP_ROSTER_UPDATE(...)
    local lootMethod, masterLooterPartyId, _ = GetLootMethod()
    D.isLootMaster = lootMethod == "master" and masterLooterPartyId == 0

    UI.UpdateElementsByPermission()

    D.raidRoster = {}
    for i = 1, MAX_RAID_MEMBERS do
        local rosterInfo = {GetRaidRosterInfo(i)}
        -- Break early if we hit a nil (this means we've reached the full number of players)
        if rosterInfo[1] == nil then
            return
        end

        table.insert(D.raidRoster, {GetRaidRosterInfo(i)})
    end
end

function ChosenLadder:CHAT_MSG_WHISPER(self, text, playerName, ...)
    if D.auctionItem ~= nil then
        if D.IsPlayerInRaid(playerName) then
            local bid = tonumber(text)
            local minBid = GetMinimumBid()

            if bid == nil then
                SendChatMessage(
                    string.format(
                        "[%s]: Invalid Bid! To bid on the item, type: /whisper %s %d",
                        A,
                        UnitName("player"),
                        minBid
                    ),
                    "WHISPER",
                    nil,
                    playerName
                )
                return
            elseif bid ~= nil then
                bid = math.floor(bid)
                if bid >= minBid then
                    D.currentBid = bid
                    D.currentWinner = playerName
                    SendChatMessage("Current Bid: " .. bid, "RAID")
                else
                    SendChatMessage(
                        string.format("[%s]: Invalid Bid! The minimum bid is %d", A, minBid),
                        "WHISPER",
                        nil,
                        playerName
                    )
                    return
                end
            end
        end
    elseif D.dunkItem ~= nil then
        if D.IsPlayerInRaid(playerName) then
            text = string.lower(text)
            print(text)
            for k, v in ipairs(D.Constants.AsheosWords) do
                -- This is a valid dunk attempt
                if text == v then
                    local guid = UnitGUID(Ambiguate(playerName, "all"))
                    print("Player Attempting - " .. guid )
                    if guid ~= nil then
                        for lk, lv in ipairs(LootLadder.players) do
                            print("Comparing " .. guid .. " to " .. lv.guid)
                            -- Found the right player!
                            if guid == lv.guid then
                                -- Register their Dunk attempt
                                table.insert(
                                    D.dunkNames,
                                    {
                                        guid = lv.guid,
                                        name = lv.name,
                                        pos = lk
                                    }
                                )
                                SendChatMessage(
                                    string.format("[%s]: Dunk registered! Current position: %s", A, lk),
                                    "WHISPER",
                                    nil,
                                    playerName
                                )
                                return
                            end
                        end
                        SendChatMessage(
                            string.format("[%s]: We couldn't find you in the raid list! Contact the loot master.", A),
                            "WHISPER",
                            nil,
                            playerName
                        )
                        return
                    end
                    -- Couldn't get a guid?  Something is off here.  Bail.
                    return
                end
            end

            SendChatMessage(
                string.format(
                    "[%s]: %s is currently running a Dunk session for loot.  If you'd like to dunk for it, type: /whisper %s DUNK",
                    A,
                    UnitName("player"),
                    UnitName("player")
                ),
                "WHISPER",
                nil,
                playerName
            )
        end
    end
end

function ChosenLadder:OnCommReceived(prefix, message, distribution, sender)
    if prefix == A and distribution == "RAID" and sender ~= UnitName("player") then
        local beginSyncFlag = D.Constants.BeginSyncFlag
        local endSyncFlag = D.Constants.EndSyncFlag

        if StartsWith(message, beginSyncFlag) then
            local vars = {}
            local players = {}

            -- carve it up
            for str in string.gmatch(message, "([^\\|]+)") do
                table.insert(vars, str)
            end

            local timestampStr = vars[1]:gsub(beginSyncFlag, "")
            local timestamp = tonumber(timestampStr)
            self:Print(
                "Incoming Sync request from " .. sender .. ": " .. timestamp .. " - Local: " .. LootLadder.lastModified
            )
            if timestamp > LootLadder.lastModified then
                -- Begin Sync
                D.syncing = StreamFlag.Started
            else
                self:Print("Sync Request Denied")
            end

            if D.syncing == StreamFlag.Started then
                for k, v in ipairs(vars) do
                    if StartsWith(v, beginSyncFlag) then
                    elseif v == endSyncFlag then
                        D.syncing = StreamFlag.Complete
                    else
                        table.insert(players, v)
                    end
                end

                if D.syncing == StreamFlag.Complete then
                    self:Print("Sync Completed from " .. sender)
                    D.BuildPlayerList(players)
                    UI.PopulatePlayerList()
                    D.syncing = StreamFlag.Empty
                end
            end
        end
    end
end
