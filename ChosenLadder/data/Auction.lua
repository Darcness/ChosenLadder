local CL, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions
---@type UI
local UI = NS.UI

---@class Auction
---@field auctionItem? string
---@field currentBid number
---@field currentWinner? string
---@field history AuctionHistoryItem[]
local Auction = {
    auctionItem = nil,
    currentBid = 0,
    currentWinner = nil,
    history = {}
}

D.Auction = Auction

local function clearAuction(obj)
    obj.auctionItem = nil
    obj.currentBid = 0
    obj.currentWinnter = nil
end

function Auction:GetItemLink()
    if Auction.auctionItem == nil then
        return nil
    end

    if F.IsItemLink(Auction.auctionItem) then
        return Auction.auctionItem
    end

    local item = D:GetLootItemByGUID(Auction.auctionItem)
    if item == nil or item.itemLink == nil then
        return nil
    end
    return item.itemLink
end

---@param forceCancel? boolean
function Auction:Complete(forceCancel)
    if not D.isLootMaster then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local item = Auction:GetItemLink()

    if item == nil then
        ChosenLadder:PrintToWindow("You're not running an auction!")
        return
    end

    if Auction.currentBid == 0 or forceCancel then
        ChosenLadder:PutOnBlast("Auction Canceled by " .. UnitName("player") .. "!")
        clearAuction(Auction)
        return
    end

    ChosenLadder:PutOnBlast(
        string.format(
            "Auction Complete! %s wins %s for %d gold!",
            Ambiguate(Auction.currentWinner, "all"),
            Auction:GetItemLink(),
            Auction.currentBid
        )
    )

    ---@class AuctionHistoryItem
    ---@field name string
    ---@field bid number
    ---@field item string
    local historyItem = {
        name = Auction.currentWinner,
        bid = Auction.currentBid,
        item = item
    }
    table.insert(Auction.history, historyItem)

    local lootItem = D:GetLootItemByGUID(Auction.auctionItem)
    if lootItem ~= nil then
        lootItem.sold = true
    end

    clearAuction(Auction)
    UI.Loot:PopulateLootList()
    ChosenLadder:SetInventoryOverlays()
end

---@param auctionItem string
function Auction:Start(auctionItem)
    if not D.isLootMaster then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    if Auction.auctionItem ~= nil then
        ChosenLadder:PrintToWindow("You're still running an auction for " .. (Auction:GetItemLink() or "UKNOWN"))
        return
    end

    clearAuction(Auction)
    Auction.auctionItem = auctionItem
    local itemLink = Auction:GetItemLink() or "UNKNOWN"
    ChosenLadder:PutOnBlast(string.format("Beginning auction for %s, please whisper %s your bids.", itemLink,
        UnitName("player")))
end

function Auction:GetMinimumBid()
    local currentBid = tonumber(Auction.currentBid) or 0
    local bidSteps = ChosenLadder:Database().factionrealm.bidSteps

    local mySteps = F.Filter(bidSteps,
        function(step) return currentBid >= (tonumber(step.start) or 0) end)

    if #mySteps == 0 then -- Do minimum bid
        return bidSteps[1].start
    else -- Return most recent step
        return tonumber(mySteps[#mySteps].step) + currentBid
    end
end

function Auction:Bid(name, bid)
    local bidNum = tonumber(bid)

    Auction.currentWinner = name
    Auction.currentBid = bidNum or 0
end
