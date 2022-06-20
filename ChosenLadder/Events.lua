local A, NS = ...

local UI = NS.UI
local D = NS.Data
local F = NS.Functions

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
    D.isLootMaster = (lootMethod == "master" and masterLooterPartyId == 0)

    UI.UpdateElementsByPermission()

    D.raidRoster = {}
    for i = 1, MAX_RAID_MEMBERS do
        local rosterInfo = { GetRaidRosterInfo(i) }
        -- Break early if we hit a nil (this means we've reached the full number of players)
        if rosterInfo[1] == nil then
            return
        end

        table.insert(D.raidRoster, rosterInfo)
    end

    UI.PopulatePlayerList()
end

function ChosenLadder:CHAT_MSG_WHISPER(self, text, playerName, ...)
    local myName = UnitName("player")
    if D.auctionItem ~= nil then
        if not D.IsPlayerInRaid(playerName) then
            -- Nothing to process, this is just whisper chatter.
            return
        end

        local bid = tonumber(text)
        if bid == nil then
            ChosenLadder:Whisper(string.format("[%s]: Invalid Bid! To bid on the item, type: /whisper %s %d", A, myName,
                minBid), playerName)

            return
        end

        bid = math.floor(bid)
        local minBid = GetMinimumBid()
        if bid < minBid then
            ChosenLadder:Whisper(string.format("[%s]: Invalid Bid! The minimum bid is %d", A, minBid), playerName)
            return
        end

        D.currentBid = bid
        D.currentWinner = playerName
        SendChatMessage("Current Bid: " .. bid, "RAID")
        return
    end

    if D.dunkItem ~= nil then
        if not D.IsPlayerInRaid(playerName) then
            -- Nothing to process, this is just whisper chatter.
            return
        end

        text = string.lower(text)
        local dunkWord = F.Find(D.Constants.AsheosWords,
            function(word) return text == word end)

        if dunkWord == nil then
            ChosenLadder:Whisper(string.format("[%s]: %s is currently running a Dunk session for loot.  If you'd like to dunk for it, type: /whisper %s DUNK"
                , A, playerName, playerName), playerName)
            return
        end

        local guid = D.ShortenGuid(UnitGUID(Ambiguate(playerName, "all")))
        if guid == nil then
            -- Couldn't get a guid?  Something is off here.
            self:Print(string.format("Unable to find a GUID for player %s! Please select them from a dropdown.",
                Ambiguate(playerName, "all")))
            return
        end

        local pos = D.RegisterDunkByGUID(guid)
        if pos <= 0 then
            -- In the raid, but not in the LootLadder?
            ChosenLadder:Whisper(string.format("[%s]: We couldn't find you in the raid list! Contact the loot master."
                , A), playerName)
            return
        end

        ChosenLadder:Whisper(string.format("[%s]: Dunk registered! Current position: %d", A, pos), playerName)

        UI.PopulatePlayerList()

        return
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
                self:Print("Sync Request Denied from " .. sender)
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
                    D.BuildPlayerList(players)
                    UI.PopulatePlayerList()
                    D.syncing = StreamFlag.Empty
                end
            end
        end
    end
end
