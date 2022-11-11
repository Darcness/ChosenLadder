local A, NS = ...

---@type UI
local UI = NS.UI
---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

local StreamFlag = D.Constants.StreamFlag

local tip = CreateFrame("GameTooltip", "Tooltip", nil, "GameTooltipTemplate")

local function isTradable(itemLocation)
    local itemLink = C_Item.GetItemLink(itemLocation)
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:SetBagItem(itemLocation:GetBagAndSlot())
    for i = 1, tip:NumLines() do
        if (string.find(_G["TooltipTextLeft" .. i]:GetText(), string.format(BIND_TRADE_TIME_REMAINING, ".*"))) then
            return true
        end
    end
end

function ChosenLadder:BAG_UPDATE_DELAYED()
    ChosenLadder:Log("Enter: BAG_UPDATE_DELAYED")
    if D.lootMasterItems == nil then
        D.lootMasterItems = {}
    end

    for bag = 0, 4 do
        local slotCount = GetContainerNumSlots(bag)
        for slot = 1, slotCount do
            local slotFrameNum = slotCount - (slot - 1)
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
                local item = Item:CreateFromBagAndSlot(bag, slot)
                local guid = item:GetItemGUID()
                local itemLink = item:GetItemLink()
                if isTradable(itemLocation) and itemLink ~= nil and guid ~= nil then
                    local current = F.Find(D.lootMasterItems, function(i) return i.guid == guid end)
                    if current == nil then
                        ---@class LootItem
                        ---@field guid string
                        ---@field itemLink string
                        ---@field sold boolean
                        local lootItem = {
                            guid = guid,
                            itemLink = itemLink,
                            sold = false
                        }
                        table.insert(D.lootMasterItems, lootItem)
                    end
                end
            end
        end
    end
    UI.Loot:PopulateLootList()
    ChosenLadder:SetInventoryOverlays()
    ChosenLadder:Log("Exit: BAG_UPDATE_DELAYED")
end

function ChosenLadder:GROUP_ROSTER_UPDATE()
    ChosenLadder:Log("Enter: GROUP_ROSTER_UPDATE")
    local requiresUIUpdate = D:UpdateRaidData()

    UI:UpdateElementsByPermission()

    if requiresUIUpdate then
        UI.Ladder:PopulatePlayerList()
    end

    ChosenLadder:Log("Exit: GROUP_ROSTER_UPDATE")
end

function ChosenLadder:CHAT_MSG_WHISPER(self, text, playerName, ...)
    ChosenLadder:Log("Enter: CHAT_MSG_WHISPER ||" .. text .. "||" .. playerName)
    if not D:GetRaidRoster():IsPlayerInRaid(playerName) then
        -- Nothing to process, this is just whisper chatter.
        ChosenLadder:Log("CHAT_MSG_WHISPER: User not in raid")
        return
    end

    local myName = UnitName("player")
    local auctionItem = D.Auction:GetItemLink()
    local dunkItem = D.Dunk:GetItemLink()

    if auctionItem ~= nil then
        ChosenLadder:Log("CHAT_MSG_WHISPER: Auction Item Found!")
        text = string.gsub(text, ",", "")
        local bid = tonumber(text)
        local minBid = D.Auction:GetMinimumBid()

        if bid == nil then
            ChosenLadder:Whisper(string.format("[%s]: Invalid Bid! To bid on the item, type: /whisper %s %d", A, myName,
                minBid), playerName)
            return
        end

        bid = math.floor(bid)
        if bid < minBid then
            ChosenLadder:Whisper(string.format("[%s]: Invalid Bid! The minimum bid is %d", A, minBid), playerName)
            return
        end

        D.Auction:Bid(playerName, bid)
        SendChatMessage("Current Bid: " .. bid, "RAID")
        return
    elseif dunkItem ~= nil then
        ChosenLadder:Log("CHAT_MSG_WHISPER: Dunk Item Found!")
        text = string.lower(text)
        local dunkWord = F.Find(D.Constants.AsheosWords,
            ---@param word string
            function(word) return text == word end)

        if dunkWord == nil then
            ChosenLadder:Whisper(string.format("[%s]: %s is currently running a Dunk session for loot.  If you'd like to dunk for it, type: /whisper %s DUNK"
                , A, myName, myName), playerName)
            return
        end

        local guid = F.ShortenPlayerGuid(UnitGUID(Ambiguate(playerName, "all")))
        if guid == nil then
            -- Couldn't get a guid?  Something is off here.
            ChosenLadder:PrintToWindow(
                string.format("Unable to find a GUID for player %s! Please select them from a dropdown.",
                    Ambiguate(playerName, "all")))
            return
        end

        local pos = D.Dunk:RegisterByGUID(guid)
        if pos <= 0 then
            -- In the raid, but not in the ChosenLadderLootLadder?
            ChosenLadder:Whisper(string.format("[%s]: We couldn't find you in the raid list! Contact the loot master."
                , A), playerName)
            return
        end

        ChosenLadder:Whisper(string.format("[%s]: Dunk registered! Current position: %d", A, pos), playerName)

        UI.Ladder:PopulatePlayerList()

        return
    end
    ChosenLadder:Log("Exit: CHAT_MSG_WHISPER")
end

function ChosenLadder:OnCommReceived(prefix, message, distribution, sender)
    if prefix == A then
        ChosenLadder:Log(string.format("Enter: OnCommReceived ||%s||%s||%s||%s", prefix, message, distribution, sender))

        if distribution == "RAID" and sender ~= UnitName("player") then
            local beginSyncFlag = D.Constants.BeginSyncFlag
            local endSyncFlag = D.Constants.EndSyncFlag

            if F.StartsWith(message, beginSyncFlag) then
                ChosenLadder:Log("OnCommReceived: Found BeginSyncFlag")
                local vars = F.Split(message, "|")
                ---@type string[]
                local players = {}

                local lastModified = ChosenLadder:Database().factionrealm.ladder.lastModified
                local timestampStr = vars[1]:gsub(beginSyncFlag, "")
                local timestamp = tonumber(timestampStr)
                ChosenLadder:PrintToWindow(string.format("Incoming Sync request from %s: %s - Local: %s", sender,
                    timestamp, lastModified))
                if timestamp > lastModified then
                    -- Begin Sync
                    D.syncing = StreamFlag.Started
                else
                    ChosenLadder:PrintToWindow("Sync Request Denied from " .. sender)
                end

                if D.syncing == StreamFlag.Started then
                    for k, v in ipairs(vars) do
                        if F.StartsWith(v, beginSyncFlag) then
                            ChosenLadder:Log("OnCommReceived: Found extraneous BeginSyncFlag")
                        elseif v == endSyncFlag then
                            ChosenLadder:Log("OnCommReceived: Found EndSyncFlag")
                            D.syncing = StreamFlag.Complete
                        else
                            ChosenLadder:Log("OnCommReceived: Found player: " .. v)
                            table.insert(players, v)
                        end
                    end

                    if D.syncing == StreamFlag.Complete then
                        ChosenLadder:GetLadder():BuildFromPlayerList(players, D)
                        UI.Ladder:PopulatePlayerList()
                        D.syncing = StreamFlag.Empty
                        ChosenLadder:Log("OnCommReceived: Updated Player List")
                    end
                end
            end
        end
        ChosenLadder:Log("Exit: OnCommReceived")
    end
end
