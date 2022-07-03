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
    if self.auctionItem == nil then
        return nil
    end

    if F.StartsWith(self.auctionItem, "Item-4648-0-") then
        local item = D.GetLootItemByGUID(self.auctionItem)
        if item == nil or item.itemLink == nil then
            return nil
        end
        return item.itemLink
    end

    return self.auctionItem
end

function Auction:Complete(forceCancel)
    if not D.isLootMaster then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local item = self:GetItemLink()

    if item == nil then
        ChosenLadder:PrintToWindow("You're not running an auction!")
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
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    if self.auctionItem ~= nil then
        ChosenLadder:PrintToWindow("You're still running an auction for " .. self:GetItemLink())
        return
    end

    clearAuction(self)
    self.auctionItem = auctionItem
    SendChatMessage(string.format("Beginning auction for %s, please whisper %s your bids.", self:GetItemLink(),
        UnitName("player")), "RAID")
end

function Auction:GetMinimumBid()
    local currentBid = tonumber(self.currentBid) or 0
    
    local mySteps = F.Filter(ChosenLadderBidSteps, function(step) return currentBid >= (tonumber(step.start) or 0) end)

    if #mySteps == 0 then -- Do minimum bid
        return ChosenLadderBidSteps[1].start
    else -- Return most recent step
        return tonumber(mySteps[#mySteps].step) + currentBid
    end
end

function Auction:Bid(name, bid)
    local bidNum = tonumber(bid)

    self.currentWinner = name
    self.currentBid = bidNum
end
