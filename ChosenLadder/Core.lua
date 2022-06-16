local A, NS = ...

local UI = NS.UI
local F = NS.Functions
local D = NS.Data

function ChosenLadder:OnInitialize()
    if LootLadder == nil then
        LootLadder = {}
    end

    if LootLadder.players == nil then
        local players = {}
        for i = 1, 50 do
            if i == 1 then
                table.insert(players, {
                    name = "WWWWWWWWWWWW",
                    present = false,
                    log = ""
                })
            else
                table.insert(players, {
                    name = "Player " .. i,
                    present = false,
                    log = ""
                })
            end
        end

        LootLadder.players = players
    end

    if LootLadder.lastModified == nil then
        LootLadder.lastModified = 0
    end

    D.auctionHistory = {}
    D.currentBid = 0
    D.currentWinner = nil
    D.ladderHistory = {}
end

function YouSoBad(action)
    SendChatMessage(string.format("%s: %s has attempted to %s via illegal calls to addon code"
        , A, UnitName("player"), action),
        "RAID")
end

function ChosenLadder:OnEnable()
    self:RegisterComm(A, ChosenLadder:OnCommReceived())
    self:RegisterChatCommand("clladder", "ToggleLadder")
    self:RegisterChatCommand("clauction", "Auction")
    self:RegisterChatCommand("cllog", "PrintHistory")
    self:RegisterChatCommand("cl", "Help")
    self:RegisterChatCommand("clhelp", "Help")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", ChosenLadder:GROUP_ROSTER_UPDATE())
    self:RegisterEvent("CHAT_MSG_WHISPER", ChosenLadder:CHAT_MSG_WHISPER())
end

function ChosenLadder:ToggleLadder()
    -- If someone is trying to run this command with the import open, then we close it.
    if UI.importFrame ~= nil and UI.importFrame:IsShown() then
        UI.importFrame:Hide()
    end

    UI.ToggleMainWindowFrame()
end

function ChosenLadder:SendMessage(message, destination)
    if D.isLootMaster == nil or D.isLootMaster == false then
        YouSoBad("Send Addon Communications")
        return
    end
    self:SendCommMessage(A, message, destination, nil, "BULK")
end

function ChosenLadder:Auction(input)
    if D.isLootMaster == nil or D.isLootMaster == false then
        YouSoBad("Start or Stop an Auction")
        return
    end

    local arg1, arg2 = self:GetArgs(input, 2)
    if arg1 == nil then
        self:Print("Usage: /clauction <start/stop> [itemLink]")
        return
    end

    if string.lower(arg1) == "start" then
        if D.auctionItem ~= nil then
            self:Print("You're still running an auction for " .. D.auctionItem)
            return
        end

        local itemParts = F.Split(arg2, "|")
        if F.StartsWith(itemParts[2], "Hitem:") then
            -- We have an item link!
            D.auctionItem = arg2
            D.currentBid = 0
            SendChatMessage("Beginning auction for " .. D.auctionItem ..
                ", please whisper " .. UnitName("player") .. " your bids",
                "RAID_WARNING")
        else
            self:Print("Usage: /clauction <start/stop> [itemLink]")
        end
    elseif string.lower(arg1) == "stop" then
        D.CompleteAuction()
    else
        self:Print("Usage: /clauction <start/stop> [itemLink]")
    end
end

function ChosenLadder:PrintHistory(input)
    local type = self:GetArgs(input, 1)
    if type == nil then
        self:Print("Usage: /cllog <auction/ladder>")
        return
    end

    type = string.lower(type)
    if type == "auction" then
        self:Print("Auction History")
        for k, v in pairs(D.auctionHistory) do
            self:Print(string.format("%s to %s for %d", v.item, Ambiguate(v.name, "all"), v.bid))
        end
    elseif type == "ladder" then
        self:Print("Ladder History")
        for k, v in pairs(D.ladderHistory) do
            self:Print(string.format("%s moved to position %d from position %d", Ambiguate(v.name, "all"), v.to, v.from))
        end
    else
        self:Print("Usage: /cllog <auction/ladder>")
    end
end

function ChosenLadder:Help()
    self:Print("ChosenLadder Help")
    self:Print("/cl, /clhelp - Displays this list")
    self:Print("/clladder - Toggles the main ladder window")
    self:Print("/clauction <start/stop> [<itemLink>] - Starts an auction (for the linked item) or stops the current auction")
    self:Print("/cllog <auction/ladder> - Displays the list of completed auctions or ladder dunks")
end
