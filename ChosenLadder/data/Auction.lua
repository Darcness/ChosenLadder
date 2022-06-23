local CL, NS = ...

local D = NS.Data
local F = NS.Functions

D.Auction = {
    auctionItem = nil,
    currentBid = 0,
    currentWinner = nil,
    history = {}
}
local Auction = D.Auction

local function clearAuction(obj)
    obj.auctionItem = nil
    obj.currentBid = 0
    obj.currentWinnter = nil
end

function Auction:GetItemLink()
    local itemNum = tonumber(self.auctionItem)
    if itemNum ~= nil then
        return D.lootMasterItems[itemNum]
    end

    return self.auctionItem
end

function Auction:Complete(forceCancel)
    if not D.isLootMaster then
        self:Print("You're not the loot master!")
        return
    end

    local item = self:GetItemLink()

    if item == nil then
        ChosenLadder:Print("You're not running an auction!")
        return
    end

    if self.currentBid == 0 or forceCancel then
        SendChatMessage("Auction Canceled by " .. UnitName("player") .. "!", "RAID")
        clearAuction(self)
        return
    end

    SendChatMessage(string.format("Auction Complete! %s wins %s for %d gold!", Ambiguate(self.currentWinner, "all"),
        self:GetItemLink(), self.currentBid), "RAID")

    table.insert(
        self.history,
        {
            name = self.currentWinner,
            bid = self.currentBid,
            item = item
        }
    )

    clearAuction(self)
end

function Auction:Start(auctionItem)
    if not D.isLootMaster then
        self:Print("You're not the loot master!")
        return
    end

    if self.auctionItem ~= nil then
        self:Print("You're still running an auction for " .. self:GetItemLink())
        return
    end

    clearAuction(self)
    self.auctionItem = auctionItem
    SendChatMessage(string.format("Beginning auction for %s, please whisper %s your bids.", self:GetItemLink(),
        UnitName("player")), "RAID")
end

function Auction:GetMinimumBid()
    local currentBid = self.currentBid

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

function Auction:Bid(name, bid)
    self.currentWinner = name
    self.currentBid = bid
end