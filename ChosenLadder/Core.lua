local A, NS = ...

local UI = NS.UI
local F = NS.Functions
local D = NS.Data

function ChosenLadder:OnInitialize()
    -- self:Print(A .. " Loaded")
end

function ChosenLadder:OnEnable()
    self:RegisterComm(A, ChosenLadder:OnCommReceived())
    self:RegisterChatCommand("clladder", "ToggleLadder")
    self:RegisterChatCommand("clauction", "Auction")
    self:RegisterChatCommand("clhistory", "AuctionHistory")
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
    self:SendCommMessage(A, message, destination, nil, "BULK")
end

function ChosenLadder:Auction(input)
    local arg1, arg2 = self:GetArgs(input, 2)

    if string.lower(arg1) == "start" then
        local itemParts = F.Split(arg2, "|")
        if F.StartsWith(itemParts[2], "Hitem:") then
            -- We have an item link!
            D.auctionItem = arg2
            D.currentBid = 0
            SendChatMessage("Beginning auction for " .. D.auctionItem .. ", please whisper me your bids", "RAID_WARNING")
        else
            self:Print("Usage: /clauction <start/stop> [itemLink]")
        end
    elseif string.lower(arg1) == "stop" then
        D.CompleteAuction()
    else
        self:Print("Usage: /clauction <start/stop> [itemLink]")
    end
end

function ChosenLadder:AuctionHistory()
    self:Print("Auction History")
    for k, v in pairs(D.auctionHistory) do
        self:Print(v.item .. " to " .. Ambiguate(v.name) .. " for " .. v.bid)
    end
end

function ChosenLadder:Help()
    self:Print("ChosenLadder Help")
    self:Print("/cl, /clhelp - Displays this list")
    self:Print("/clladder - Toggles the main ladder window")
    self:Print("/clauction <start/stop> [<itemLink>] - Starts an auction (for the linked item) or stops the current auction")
    self:Print("/clhistory - Displays the list of completed auctions")

end
