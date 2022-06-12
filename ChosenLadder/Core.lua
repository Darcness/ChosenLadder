local A, NS = ...

local UI = NS.UI
local F = NS.Functions
local D = NS.Data

function ChosenLadder:OnInitialize()
    self:Print(A .. " Loaded")
end

function ChosenLadder:OnEnable()
    self:RegisterComm(A, ChosenLadder:OnCommReceived())
    self:RegisterChatCommand("ladder", "ToggleLadder")
    self:RegisterChatCommand("clauction", "StartAuction")
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

function ChosenLadder:StartAuction(input)
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
        SendChatMessage("Auction Complete! " .. Ambiguate(D.currentWinner, "all") .. " wins " .. D.auctionItem .. " for " .. D.currentBid .. " gold!", "RAID_WARNING")
        D.auctionItem = nil
        D.currentBid = 0
    else
        self:Print("Usage: /clauction <start/stop> [itemLink]")
    end
end
