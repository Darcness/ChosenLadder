local CL, NS = ...

---@type Data
local D = NS.Data
---@type UI
local UI = NS.UI
---@type Functions
local F = NS.Functions

---@class Whisper
local Whisper = {}

---@class Comms
---@field Whisper Whisper
local Comms = {
    Whisper = Whisper
}
NS.Comms = Comms

---Process a Ladder Sync Comm
---@param message string
---@param distribution string
---@param sender string
function Comms:LadderSync(message, distribution, sender)
    ChosenLadder:Log("Enter: Comms:ProcessLadder")

    local vars = F.Split(message, "|")
    ---@type string[]
    local players = {}

    local lastModified = ChosenLadder:Database().factionrealm.ladder.lastModified
    local timestampStr = vars[1]:gsub(D.Constants.BeginSyncFlag, "")
    local timestamp = tonumber(timestampStr) or 0
    if timestamp > lastModified then
        -- Begin Sync
        D.syncing = D.Constants.StreamFlag.Started
    else
        ChosenLadder:PrintToWindow("Sync Request Denied from " .. sender)
    end

    if D.syncing == D.Constants.StreamFlag.Started then
        for k, v in ipairs(vars) do
            if F.StartsWith(v, D.Constants.BeginSyncFlag) then
                ChosenLadder:Log("ProcessLadder: Found extraneous BeginSyncFlag")
            elseif v == D.Constants.EndSyncFlag then
                ChosenLadder:Log("ProcessLadder: Found EndSyncFlag")
                D.syncing = D.Constants.StreamFlag.Complete
            else
                ChosenLadder:Log("ProcessLadder: Found player: " .. v)
                table.insert(players, v)
            end
        end

        if D.syncing == D.Constants.StreamFlag.Complete then
            ChosenLadder:GetLadder():BuildFromPlayerList(players, D)
            UI.Ladder:PopulatePlayerList()
            D.syncing = D.Constants.StreamFlag.Empty
            ChosenLadder:Log("ProcessLadder: Updated Player List")
        end
    end

    ChosenLadder:Log("Exit: Comms:ProcessLadder")
end

---@param message string
---@param distribution string
---@param sender string
function Comms:AuctionStart(message, distribution, sender)
    ChosenLadder:Log("Enter: Comms:AuctionStart")

    local vars = F.Split(message, "||")

    if F.IsItemLink(vars[1]) then
        D.Auction.auctionItem = vars[1]
        UI.Loot:PopulateLootList()
    end

    ChosenLadder:Log("Exit: Comms:AuctionStart")
end

---@param message string
---@param distribution string
---@param sender string
function Comms:AuctionEnd(message, distribution, sender)
    ChosenLadder:Log("Enter: Comms:AuctionEnd")

    D.Auction:ClearAuction()
    UI.Loot:PopulateLootList()

    ChosenLadder:Log("Exit: Comms:AuctionEnd")
end

---@param message string
---@param distribution string
---@param sender string
function Comms:DunkStart(message, distribution, sender)
    ChosenLadder:Log("Enter: Comms:DunkStart")

    local vars = F.Split(message, "||")
    if F.IsItemLink(vars[1]) then
        D.Dunk.dunkItem = vars[1]
        UI.Loot:PopulateLootList()
    end

    ChosenLadder:Log("Exit: Comms:DunkStart")
end

---@param message string
---@param distribution string
---@param sender string
function Comms:DunkEnd(message, distribution, sender)
    ChosenLadder:Log("Enter: Comms:DunkEnd")

    D.Dunk:ClearDunk()
    UI.Loot:PopulateLootList()

    ChosenLadder:Log("Exit: Comms:DunkEnd")
end

---@param message string
---@param distribution string
---@param sender string
function Comms:LootList(message, distribution, sender)
    ChosenLadder:Log("Enter: Comms:LootList")

    local newMessage = message:gsub(D.Constants.LootListFlag .. "||", "")
    print(newMessage)
    local items = D.lootMasterItems:Deserialize(newMessage)
    D.lootMasterItems.items = items
    UI.Loot:PopulateLootList()

    ChosenLadder:Log("Exit: Comms:LootList")
end

---Handles a potential Bid whisper
---@param text string
---@param playerName string
function Whisper:Bid(text, playerName)
    ChosenLadder:Log("Enter: Whisper:Bid")

    local myName = UnitName("player")
    text = string.gsub(text, ",", "")
    local bid = tonumber(text)
    local minBid = D.Auction:GetMinimumBid()

    if bid == nil then
        ChosenLadder:Whisper(string.format("[%s]: Invalid Bid! To bid on the item, type: /whisper %s %d", CL, myName,
            minBid), playerName)
        return
    end

    bid = math.floor(bid)
    if bid < minBid then
        ChosenLadder:Whisper(string.format("[%s]: Invalid Bid! The minimum bid is %d", CL, minBid), playerName)
        return
    end

    D.Auction:Bid(playerName, bid)
    ChosenLadder:PutOnBlast("Current Bid: " .. bid, ChosenLadder:Database().char.announcements.auctionUpdate)

    ChosenLadder:Log("Exit: Whisper:Bid")
end

---Handles a potential Dunk whisper
---@param text string
---@param playerName string
function Whisper:Dunk(text, playerName)
    ChosenLadder:Log("Enter: Whisper:Dunk")

    local myName = UnitName("player")
    text = string.lower(text)
    ---@param word string
    local dunkWord = F.Find(D.Constants.AsheosWords, function(word) return text == word end)

    if dunkWord == nil then
        ChosenLadder:Whisper(
            string.format(
                "[%s]: %s is currently running a Dunk session for loot.  If you'd like to dunk for it, type: /whisper %s DUNK"
                , CL, myName, myName),
            playerName)
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
        ChosenLadder:Whisper(string.format("[%s]: We couldn't find you in the raid list! Contact the loot master.", CL),
            playerName)
        return
    end

    ChosenLadder:Whisper(string.format("[%s]: Dunk registered! Current position: %d", CL, pos), playerName)

    UI.Ladder:PopulatePlayerList()

    ChosenLadder:Log("Exit: Whisper:Dunk")
end
