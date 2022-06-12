local A, NS = ...

local UI = NS.UI
local D = NS.Data

local StreamFlag = NS.Data.Constants.StreamFlag

function ChosenLadder:GROUP_ROSTER_UPDATE(...)
    UI.PopulatePlayerList()
end

function ChosenLadder:CHAT_MSG_WHISPER(self, text, playerName, ...)
    if D.auctionItem ~= nil then
        local bid = tonumber(text)
        local currentBid = D.currentBid or 0
        if bid ~= nil then
            bid = math.floor(bid)
            if bid > currentBid then
                D.currentBid = bid
                D.currentWinner = playerName
                SendChatMessage("Current Bid: " .. bid, "RAID" )
            else
                SendChatMessage(A .. ": The current bid is " .. currentBid .. ", please bid higher.", "WHISPER", nil, playerName)
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
            self:Print("Incoming Sync request from " .. sender .. ": " .. timestamp .. " - Local: " .. D.lastModified)
            if timestamp > D.lastModified then
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
