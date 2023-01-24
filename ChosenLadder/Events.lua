local A, NS = ...

---@type UI
local UI = NS.UI
---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions
---@type Comms
local Comms = NS.Comms

local tip = CreateFrame("GameTooltip", "Tooltip", nil, "GameTooltipTemplate")

---comment
---@param itemLocation ItemLocationMixin
---@return number
local function GetTradeableTime(itemLocation)
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:SetBagItem(itemLocation:GetBagAndSlot())
    for i = 1, tip:NumLines() do
        ---@type string
        local line = _G["TooltipTextLeft" .. i]:GetText()
        if (string.find(line, string.format(BIND_TRADE_TIME_REMAINING, ".*"))) then
            local parts = F.Split(line, " ")
            local timestamp = GetServerTime()
            for idx, linePart in ipairs(parts) do
                if linePart == "hour" or linePart == "hours" then
                    timestamp = timestamp + ((tonumber(parts[idx - 1] or "0") or 0) * 60 * 60)
                elseif linePart == "minute" or linePart == "minutes" then
                    timestamp = timestamp + ((tonumber(parts[idx - 1] or "0") or 0) * 60)
                elseif linePart == "second" or linePart == "seconds" then
                    timestamp = timestamp + (tonumber(parts[idx - 1] or "0") or 0)
                end
            end
            return timestamp
        end
    end

    return 0
end

---Handles Bag Updates -- Loot list is set to match inventory
function ChosenLadder:BAG_UPDATE_DELAYED()
    -- ChosenLadder:Log("Enter: BAG_UPDATE_DELAYED")

    -- We don't want to delete the test items that LMOverride creates, so let's just no-op here.
    if D.isLootMasterOverride then
        return
    end

    ---@type LootItem[]
    local lootItems = {}

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
                local item = Item:CreateFromBagAndSlot(bag, slot)
                local guid = item:GetItemGUID()
                local itemLink = item:GetItemLink()
                local expire = GetTradeableTime(itemLocation)
                if expire > 0 and itemLink ~= nil and guid ~= nil then
                    -- ChosenLadder:Log("BAG_UPDATE_DELAYED: Found item to add: " .. guid)
                    local lootItem = LootItem:new({
                        guid = guid,
                        itemLink = itemLink,
                        sold = false,
                        player = UnitName("player") or "",
                        itemId = itemID,
                        expire = expire
                    })
                    table.insert(lootItems, lootItem)
                end
            end
        end
    end

    D.lootMasterItems:Update(lootItems)

    UI.Loot:PopulateLootList()
    ChosenLadder:SetInventoryOverlays()
    -- ChosenLadder:Log("Exit: BAG_UPDATE_DELAYED")
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
    ChosenLadder:Log("Enter: CHAT_MSG_WHISPER||" .. text .. "||" .. playerName)
    if not (D:GetRaidRoster():IsPlayerInRaid(playerName) or D.isTestMode) then
        -- Nothing to process, this is just whisper chatter.
        ChosenLadder:Log("CHAT_MSG_WHISPER: User not in raid")
        return
    end

    local myName = UnitName("player")
    local auctionItem = D.Auction:GetItemLink()
    local dunkItem = D.Dunk:GetItemLink()

    if auctionItem ~= nil then
        ChosenLadder:Log("CHAT_MSG_WHISPER: Auction Item Found!")
        Comms.Whisper:Bid(text, playerName)

    elseif dunkItem ~= nil then
        ChosenLadder:Log("CHAT_MSG_WHISPER: Dunk Item Found!")
        Comms.Whisper:Dunk(text, playerName)
    end
    ChosenLadder:Log("Exit: CHAT_MSG_WHISPER")
end

---OnCommReceived
---@param prefix string
---@param message string
---@param distribution string
---@param sender string
function ChosenLadder:OnCommReceived(prefix, message, distribution, sender)
    if prefix == A then
        ChosenLadder:Log(string.format("Enter: OnCommReceived||%s||%s||%s||%s", prefix, message, distribution, sender))
        if sender ~= UnitName("player") then
            if F.StartsWith(message, D.Constants.BeginSyncFlag) then
                ChosenLadder:Log("OnCommReceived: Found BeginSyncFlag")
                Comms:LadderSync(message, distribution, sender)

            elseif F.StartsWith(message, D.Constants.RequestSyncFlag) then
                ChosenLadder:Log("OnCommReceived: Found RequestSyncFlag")
                Comms:SyncRequest(message, distribution, sender)

            elseif F.StartsWith(message, D.Constants.AuctionStartFlag) then
                ChosenLadder:Log("OnCommReceived: Found AuctionStartFlag")
                Comms:AuctionStart(message, distribution, sender)

            elseif F.StartsWith(message, D.Constants.AuctionEndFlag) then
                ChosenLadder:Log("OnCommReceived: Found AuctionEndFlag")
                Comms:AuctionEnd(message, distribution, sender)
            elseif F.StartsWith(message, D.Constants.DunkStartFlag) then
                ChosenLadder:Log("OnCommReceived: Found DunkStartFlag")
                Comms:DunkStart(message, distribution, sender)

            elseif F.StartsWith(message, D.Constants.DunkEndFlag) then
                ChosenLadder:Log("OnCommReceived: Found DunkEndFlag")
                Comms:DunkEnd(message, distribution, sender)

            elseif F.StartsWith(message, D.Constants.LootListFlag) then
                ChosenLadder:Log("OnCommReceived: Found LootListFlag")
                Comms:LootList(message, distribution, sender)

            elseif F.StartsWith(message, D.Constants.LootRequestFlag) then
                ChosenLadder:Log("OnCommReceived: Found LootRequestFlag")
                Comms:LootRequest(message, distribution, sender)
            end
        end
    end
    ChosenLadder:Log("Exit: OnCommReceived")
end
