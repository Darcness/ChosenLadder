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
    UI.PopulatePlayerList()

    D.raidRoster = {}
    for i = 1, MAX_RAID_MEMBERS do
        local rosterInfo = { GetRaidRosterInfo(i) }
        -- Break early if we hit a nil (this means we've reached the full number of players)
        if rosterInfo[1] == nil then
            return
        end

        table.insert(D.raidRoster, { GetRaidRosterInfo(i) })
    end
end

function ChosenLadder:CHAT_MSG_WHISPER(self, text, playerName, ...)
    if D.auctionItem ~= nil then
        local bid = tonumber(text)
        if bid ~= nil and D.IsPlayerInRaid(playerName) then
            bid = math.floor(bid)
            local minBid = GetMinimumBid()
            if bid >= minBid then
                D.currentBid = bid
                D.currentWinner = playerName
                SendChatMessage("Current Bid: " .. bid, "RAID")
            else
                SendChatMessage(A .. ": The current minimum bid is " .. minBid, "WHISPER", nil, playerName)
            end
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
            self:Print("Incoming Sync request from " .. sender .. ": " .. timestamp .. " - Local: " .. LootLadder.lastModified)
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
