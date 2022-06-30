local A, NS = ...

local UI = NS.UI
local F = NS.Functions
local D = NS.Data

function ChosenLadder:OnInitialize()
    if LootLadder == nil then
        LootLadder = {}
    end

    if LootLadder.lastModified == nil then
        LootLadder.lastModified = 0
    end

    local newPlayers = {}
    -- Do a little data validation, just in case.
    for _, player in ipairs(LootLadder.players) do
        if player.id ~= nil then
            -- Initialize them as not present.
            player.present = false
            table.insert(newPlayers, player)
        else
            -- no id? They're bad data.
            ChosenLadder:Print("User missing ID. Ignoring...")
        end
    end

    LootLadder.players = newPlayers

    D.auctionHistory = {}
    D.currentBid = 0
    D.currentWinner = nil
    D.ladderHistory = {}
end

function YouSoBad(action)
    SendChatMessage(
        string.format("%s: %s has attempted to %s via illegal calls to addon code", A, UnitName("player"), action),
        "RAID"
    )
end

function ChosenLadder:OnEnable()
    hooksecurefunc(MasterLooterFrame, 'Hide', function(self) self:ClearAllPoints() end)
    self:RegisterComm(A, ChosenLadder:OnCommReceived())
    self:RegisterChatCommand("clladder", "ToggleLadder")
    self:RegisterChatCommand("clauction", "Auction")
    self:RegisterChatCommand("cldunk", "Dunk")
    self:RegisterChatCommand("cllog", "PrintHistory")
    self:RegisterChatCommand("cl", "Help")
    self:RegisterChatCommand("clhelp", "Help")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", ChosenLadder:GROUP_ROSTER_UPDATE())
    self:RegisterEvent("CHAT_MSG_WHISPER", ChosenLadder:CHAT_MSG_WHISPER())
    -- self:RegisterEvent("OPEN_MASTER_LOOT_LIST", ChosenLadder:OPEN_MASTER_LOOT_LIST())
    self:RegisterEvent("BAG_UPDATE_DELAYED", ChosenLadder:BAG_UPDATE_DELAYED())
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

function ChosenLadder:Dunk(input)
    if not D.isLootMaster then
        ChosenLadder:Print("You're not the loot master!")
        return
    end

    local arg1 = self:GetArgs(input, 1)
    if arg1 == nil then
        ChosenLadder:Print("Usage: /cldunk <itemLink/stop>")
        return
    end

    if string.lower(arg1) == "stop" then
        D.Dunk:Complete()
        return
    end

    local itemParts = F.Split(arg1, "|")
    if F.StartsWith(itemParts[2], "Hitem:") then
        -- We have an item link!
        D.Dunk:Start(arg1)
    else
        ChosenLadder:Print("Usage: /cldunk <itemLink/stop>")
    end
end

function ChosenLadder:Auction(input)
    if not D.isLootMaster then
        ChosenLadder:Print("You're not the loot master!")
        return
    end

    local arg1, arg2 = self:GetArgs(input, 2)
    if arg1 == nil then
        ChosenLadder:Print("Usage: /clauction <start/stop> [itemLink]")
        return
    end

    if string.lower(arg1) == "start" then
        local itemParts = F.Split(arg2, "|")
        if F.StartsWith(itemParts[2], "Hitem:") then
            -- We have an item link!
            D.Auction:Start(arg2)
        else
            ChosenLadder:Print("Usage: /clauction <start/stop> [itemLink]")
        end
    elseif string.lower(arg1) == "stop" then
        D.Auction:Complete()
    else
        ChosenLadder:Print("Usage: /clauction <start/stop> [itemLink]")
    end
end

function ChosenLadder:PrintHistory(input)
    local type = self:GetArgs(input, 1)
    if type == nil then
        ChosenLadder:Print("Usage: /cllog <auction/ladder>")
        return
    end

    type = string.lower(type)
    if type == "auction" then
        ChosenLadder:Print("Auction History")
        for k, v in pairs(D.Auction.history) do
            ChosenLadder:Print(string.format("%s to %s for %d", v.item, Ambiguate(v.name, "all"), v.bid))
        end
    elseif type == "ladder" then
        ChosenLadder:Print("Ladder History")
        for k, v in pairs(D.Dunk.history) do
            ChosenLadder:Print(
                string.format("%s moved to position %d from position %d",
                    Ambiguate(select(6, GetPlayerInfoByGUID(v.player.guid)), "all"), v.to, v.from)
            )
        end
    else
        ChosenLadder:Print("Usage: /cllog <auction/ladder>")
    end
end

function ChosenLadder:Help()
    ChosenLadder:Print("ChosenLadder Help")
    ChosenLadder:Print("/cl, /clhelp - Displays this list")
    ChosenLadder:Print("/clladder - Toggles the main ladder window")
    ChosenLadder:Print(
        "/clauction <start/stop> [<itemLink>] - Starts an auction (for the linked item) or stops the current auction"
    )
    ChosenLadder:Print(
        "/cldunk <itemLink/stop> - Starts an dunk session (for the linked item) or stops the current auction"
    )
    ChosenLadder:Print("/cllog <auction/ladder> - Displays the list of completed auctions or ladder dunks")
end

function ChosenLadder:Whisper(text, target)
    local myName = UnitName("player")
    if myName == Ambiguate(target, "all") then
        ChosenLadder:Print(text)
    else
        SendChatMessage(text, "WHISPER", nil, target)
    end
end
