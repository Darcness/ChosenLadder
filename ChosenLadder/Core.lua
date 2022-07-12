---@diagnostic disable: undefined-field
local A, NS = ...

---@type UI
local UI = NS.UI
---@type Functions
local F = NS.Functions
---@type Data
local D = NS.Data

---@class DatabasePlayer
---@field id string
---@field name string
---@field guid string
---@field present boolean
---@field log string

---@class Database
---@field char DatabaseChar
---@field profile DatabaseProfile
---@field factionrealm DatabaseFactionRealm
local defaultDB = {
    ---@class DatabaseChar
    ---@field minimap MinimapOptions
    ---@field ouputChannel number
    char = {
        ---@class MinimapOptions
        ---@field hide boolean
        minimap = {
            hide = false
        },
        outputChannel = 1
    },
    ---@class DatabaseProfile
    ---@field ladderType number
    profile = {
        ladderType = D.Constants.LadderType.SKSSimple
    },
    ---@class DatabaseFactionRealm
    ---@field ladder DatabaseLadder
    ---@field bidSteps DatabaseBidStep[]
    factionrealm = {
        ---@class DatabaseLadder
        ---@field lastModified number
        ---@field players DatabasePlayer[]
        ladder = {
            lastModified = 0,
            players = {}
        },
        bidSteps = {
            [1] = {
                start = 50,
                step = 10
            },
            [2] = {
                start = 300,
                step = 50
            },
            [3] = {
                start = 1000,
                step = 100
            }
        }
    }
}

---@return Database
function ChosenLadder:Database()
    return self.db
end

function ChosenLadder:OnInitialize()
    -- Set up the base Addon options
    local clLDB = LibStub("LibDataBroker-1.1"):NewDataObject(A, {
        type = "data source",
        text = A,
        icon = "Interface\\Icons\\INV_Box_04",
        OnClick = function(_, button) ChosenLadder:MinimapClick(button) end,
        OnEnter = function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(A)
            GameTooltip:AddLine("Left-Click to toggle ChosenLadder window", 1, 1, 1, false)
            GameTooltip:AddLine("Right-Click to open Interface Options", 1, 1, 1, false)
            GameTooltip:Show()
        end,
        OnLeave = function() GameTooltip:Hide() end
    })

    -- Register the Database
    self.db = LibStub("AceDB-3.0"):New("ChosenLadderDB", defaultDB)
    NS.Icon:Register(A, clLDB, ChosenLadder:Database().char.minimap)

    local newPlayers = {}
    -- Do a little data validation on the ladder, just in case.
    for _, player in ipairs(ChosenLadder:Database().factionrealm.ladder.players or {}) do
        if player.id ~= nil then
            -- Initialize them as not present.
            player.present = false
            table.insert(newPlayers, player)
        else
            -- no id? They're bad data.
            ChosenLadder:PrintToWindow("User missing ID. Ignoring...")
        end
    end

    ChosenLadder:Database().factionrealm.ladder.players = newPlayers
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
    self:RegisterEvent("BAG_UPDATE_DELAYED", ChosenLadder:BAG_UPDATE_DELAYED())

    UI.InterfaceOptions:CreatePanel()
end

function ChosenLadder:MinimapClick(button)
    if button == "RightButton" then
        InterfaceOptionsFrame_OpenToCategory(UI.InterfaceOptions.ioPanel)
    elseif button == "LeftButton" then
        UI:ToggleMainWindowFrame()
    end
end

function ChosenLadder:SetMinimapHidden(hidden)
    self.db.profile.minimap.hide = hidden
    if self.db.profile.minimap.hide then
        NS.Icon:Hide(A)
    else
        NS.Icon:Show(A)
    end
end

function ChosenLadder:ToggleLadder()
    -- If someone is trying to run this command with the import open, then we close it.
    if UI.importFrame ~= nil and UI.importFrame:IsShown() then
        UI.importFrame:Hide()
    end

    UI:ToggleMainWindowFrame()
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
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local arg1 = self:GetArgs(input, 1)
    if arg1 == nil then
        ChosenLadder:PrintToWindow("Usage: /cldunk <itemLink/stop>")
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
        ChosenLadder:PrintToWindow("Usage: /cldunk <itemLink/stop>")
    end
end

function ChosenLadder:Auction(input)
    if not D.isLootMaster then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local arg1, arg2 = self:GetArgs(input, 2)
    if arg1 == nil then
        ChosenLadder:PrintToWindow("Usage: /clauction <start/stop> [itemLink]")
        return
    end

    if string.lower(arg1) == "start" then
        local itemParts = F.Split(arg2, "|")
        if F.StartsWith(itemParts[2], "Hitem:") then
            -- We have an item link!
            D.Auction:Start(arg2)
        else
            ChosenLadder:PrintToWindow("Usage: /clauction <start/stop> [itemLink]")
        end
    elseif string.lower(arg1) == "stop" then
        D.Auction:Complete()
    else
        ChosenLadder:PrintToWindow("Usage: /clauction <start/stop> [itemLink]")
    end
end

function ChosenLadder:PrintHistory(input)
    local type = self:GetArgs(input, 1)
    if type == nil then
        ChosenLadder:PrintToWindow("Usage: /cllog <auction/ladder>")
        return
    end

    type = string.lower(type)
    if type == "auction" then
        ChosenLadder:PrintToWindow("Auction History")
        for k, v in pairs(D.Auction.history) do
            ChosenLadder:PrintToWindow(string.format("%s to %s for %d", v.item, Ambiguate(v.name, "all"), v.bid))
        end
    elseif type == "ladder" then
        ChosenLadder:PrintToWindow("Ladder History")
        for k, v in pairs(D.Dunk.history) do
            ChosenLadder:PrintToWindow(
                string.format("%s moved to position %d from position %d",
                    Ambiguate(select(6, GetPlayerInfoByGUID(v.player.guid)), "all"), v.to, v.from)
            )
        end
    else
        ChosenLadder:PrintToWindow("Usage: /cllog <auction/ladder>")
    end
end

function ChosenLadder:Help()
    ChosenLadder:PrintToWindow("ChosenLadder Help")
    ChosenLadder:PrintToWindow("/cl, /clhelp - Displays this list")
    ChosenLadder:PrintToWindow("/clladder - Toggles the main ladder window")
    ChosenLadder:PrintToWindow(
        "/clauction <start/stop> [<itemLink>] - Starts an auction (for the linked item) or stops the current auction"
    )
    ChosenLadder:PrintToWindow(
        "/cldunk <itemLink/stop> - Starts an dunk session (for the linked item) or stops the current auction"
    )
    ChosenLadder:PrintToWindow("/cllog <auction/ladder> - Displays the list of completed auctions or ladder dunks")
end

function ChosenLadder:Whisper(text, target)
    local myName = UnitName("player")
    if myName == Ambiguate(target, "all") then
        ChosenLadder:PrintToWindow(text)
    else
        SendChatMessage(text, "WHISPER", nil, target)
    end
end

---@param text string
function ChosenLadder:PrintToWindow(text)
    local chatFrame = _G["ChatFrame" .. ChosenLadderOutputChannel] or DEFAULT_CHAT_FRAME
    ChosenLadder:Print(chatFrame, text)
end

function ChosenLadder:GetLadderPlayers()
    return ChosenLadder:Database().factionrealm.ladder.players
end