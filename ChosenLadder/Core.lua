---@diagnostic disable: undefined-field
local A, NS = ...

---@type UI
local UI = NS.UI
---@type Functions
local F = NS.Functions
---@type Data
local D = NS.Data

---@class Database
---@field char DatabaseChar
---@field profile DatabaseProfile
---@field factionrealm DatabaseFactionRealm
local defaultDB = {
    ---@class DatabaseChar
    ---@field announcements AnnouncementSettings
    ---@field log string[]
    ---@field minimap MinimapOptions
    ---@field ouputChannel number
    char = {
        ---@class AnnouncementSettings
        ---@field auctionStart boolean
        ---@field auctionCancel boolean
        ---@field auctionComplete boolean
        ---@field auctionUpdate boolean
        ---@field dunkStart boolean
        ---@field dunkComplete boolean
        ---@field dunkCancel boolean
        announcements = {
            auctionStart = true,
            auctionCancel = true,
            auctionComplete = true,
            auctionUpdate = false,
            dunkStart = true,
            dunkComplete = true,
            dunkCancel = true,
        },
        log = {},
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
    ---@field ladder LadderList
    ---@field bidSteps DatabaseBidStep[]
    factionrealm = {
        ladder = LadderList:new({
            lastModified = 0,
            players = {}
        }),
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
    ---@diagnostic disable-next-line: return-type-mismatch
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
    ChosenLadder:Log("Enter: ChosenLadder:OnInitialize")
    NS.Icon:Register(A, clLDB, ChosenLadder:Database().char.minimap)

    local newPlayers = {}
    -- Do a little data validation on the ladder, just in case.
    for _, player in ipairs(ChosenLadder:GetLadder().players or {}) do
        if player.id ~= nil then
            -- Massaging the data since we migrated data types.
            local guids = player.guids or {}
            if type(guids) == "string" then
                guids = F.Split(guids, "-")
                player.guids = guids
            end
            table.insert(newPlayers, DatabasePlayer:new(player))
        else
            -- no id? They're bad data.
            ChosenLadder:PrintToWindow("User missing ID. Ignoring...")
        end
    end

    ChosenLadder:Database().factionrealm.ladder = LadderList:new({
        players = newPlayers,
        lastModified = ChosenLadder:Database().factionrealm.ladder.lastModified or GetServerTime()
    })

    ChosenLadder:Log("Exit: ChosenLadder:OnInitialize")
end

function YouSoBad(action)
    return
    -- SendChatMessage(
    --     string.format("%s: %s has attempted to %s via illegal calls to addon code", A, UnitName("player"), action),
    --     "RAID"
    -- )
end

---Fetches the Overlay objects for a particular inventory item Frame, builds if they don't exist.
---@param bagName string
---@param slotFrameNum number
---@return BackdropTemplate|Frame
---@return FontString
local function GetOverlayForBagFrame(bagName, slotFrameNum)
    local overlayFrameName = bagName .. "Item" .. slotFrameNum .. "Overlay"
    local slotFrame = _G[bagName .. "Item" .. slotFrameNum]
    local overlayFrame = _G[overlayFrameName] or
        CreateFrame("Frame", overlayFrameName, slotFrame, "BackdropTemplate")
    overlayFrame:SetAllPoints(slotFrame)
    overlayFrame:SetFrameLevel(slotFrame:GetFrameLevel() + 1)
    overlayFrame:SetBackdrop({
        tile = true,
        tileEdge = true,
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
    })
    local text = _G[overlayFrameName .. "Font"] or
        overlayFrame:CreateFontString(overlayFrameName .. "Font", "OVERLAY", "GameFontNormal")
    ---@diagnostic disable-next-line: param-type-mismatch
    text:SetPoint("LEFT", overlayFrame, 0, 0)

    return overlayFrame, text
end

local function GenerateBagFrameOverlays(frame)
    local name = frame:GetName();
    local bagstr = string.gsub(name, "ContainerFrame", "")
    local bag = (tonumber(bagstr) or 1) - 1
    local slotCount = C_Container.GetContainerNumSlots(bag)
    for slot = 1, slotCount do
        local slotFrameNum = slotCount - (slot - 1)
        -- Clear the overlay first, we'll re-colorize if necessary.
        local overlayFrame, text = GetOverlayForBagFrame(name, slotFrameNum)
        overlayFrame:SetBackdropColor(0, 0, 0, 0)
        text:SetText("")

        local itemID = C_Container.GetContainerItemID(bag, slot)
        if itemID then
            local item = Item:CreateFromBagAndSlot(bag, slot)
            local guid = item:GetItemGUID()
            local itemData = D.lootMasterItems:GetByGUID(guid)
            if itemData ~= nil and itemData.sold then
                local overlayFrame, text = GetOverlayForBagFrame(name, slotFrameNum)
                overlayFrame:SetBackdropColor(1, 0, 0, 0.4)
                text:SetText("SOLD")
            end
        end
    end
end

function ChosenLadder:SetInventoryOverlays()
    for bag = 1, 5 do
        GenerateBagFrameOverlays(_G["ContainerFrame" .. bag])
    end
end

function ChosenLadder:OnEnable()
    ChosenLadder:Log("Enter: ChosenLadder:OnEnable")
    hooksecurefunc(MasterLooterFrame, 'Hide', function(self) self:ClearAllPoints() end)
    hooksecurefunc("ContainerFrame_GenerateFrame", GenerateBagFrameOverlays)
    ChosenLadder:SetInventoryOverlays()
    self:RegisterComm(A, "OnCommReceived")
    self:RegisterChatCommand("cl", "ToggleLadder")
    self:RegisterChatCommand("clauction", "Auction")
    self:RegisterChatCommand("cldunk", "Dunk")
    self:RegisterChatCommand("cllog", "PrintHistory")
    self:RegisterChatCommand("clhelp", "Help")
    self:RegisterChatCommand("iamthecaptainnow", "IAmTheCaptainNow")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("BAG_UPDATE_DELAYED")

    UI.InterfaceOptions:CreatePanel()

    UI.Loot:UpdateTimerDisplays()

    D:UpdateRaidData()
    ChosenLadder:Log("Exit: ChosenLadder:OnEnable")
end

function ChosenLadder:IAmTheCaptainNow()
    local name, _ = UnitName("player")
    if name == "Fastandan" or name == "Foladocus" or name == "Firannor" or name == "Yanagi" or name == "Foghli" then
        if D.isLootMasterOverride then
            D.isLootMasterOverride = false
            D.isTestMode = false
            ChosenLadder:PrintToWindow("You've been demoted!")
        else
            D.isLootMasterOverride = true
            D.isTestMode = true
            ChosenLadder:PrintToWindow("Aye Aye, Captain!")
            ---@type LootItem[]
            local items = {}
            for bag = 0, 4 do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local itemID = C_Container.GetContainerItemID(bag, slot)
                    if itemID then
                        local item = Item:CreateFromBagAndSlot(bag, slot)
                        local guid = item:GetItemGUID()
                        local itemLink = item:GetItemLink()

                        table.insert(items, LootItem:new({
                            guid = guid,
                            itemLink = itemLink,
                            sold = false,
                            player = UnitName("player") or "",
                            itemId = itemID,
                            expire = GetServerTime() + (60 * 60)
                        }))
                    end
                end
            end

            D.lootMasterItems:Update(items);
        end
        UI:UpdateElementsByPermission()
        UI.Loot:PopulateLootList()
    end
end

function ChosenLadder:MinimapClick(button)
    if button == "RightButton" then
        InterfaceOptionsFrame_OpenToCategory(UI.InterfaceOptions.ioPanel)
    elseif button == "LeftButton" then
        UI:ToggleMainWindowFrame()
    end
end

---Sends out a big message to the entire raid.
---@param message string
---@param raidWarning boolean
function ChosenLadder:PutOnBlast(message, raidWarning)
    local channel = "RAID"
    if raidWarning and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
        channel = "RAID_WARNING"
    end

    if D.isTestMode then
        ChosenLadder:PrintToWindow(message)
    else
        SendChatMessage(message, channel)
    end

end

function ChosenLadder:SetMinimapHidden(hidden)
    ChosenLadder:Database().char.minimap.hide = hidden
    if ChosenLadder:Database().char.minimap.hide then
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

---@param message string
---@param destination string
---@param allowClient boolean?
---@param target string?
function ChosenLadder:SendMessage(message, destination, allowClient, target)
    local debug = false
    ChosenLadder:Log("Sending Message: " .. message)
    if not (allowClient or D:IsLootMaster() or D.isTestMode) then
        YouSoBad("Send Addon Communications")
        return
    end

    self:SendCommMessage(A, message, destination, target, "NORMAL", function(a, b, c)
        if debug then print("a:" .. (a or "") .. " b:" .. b .. " c:" .. c) end
    end)
end

function ChosenLadder:Dunk(input)
    if not D:IsLootMaster() then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local arg1 = self:GetArgs(input, 1)
    if arg1 == nil then
        ChosenLadder:PrintToWindow("Usage: /cldunk <itemLink>|cancel")
    elseif F.IsItemLink(arg1) then
        -- starting a dunk session
        D.Dunk:Start(arg1)
    elseif string.lower(arg1) == "cancel" then
        D.Dunk:Cancel()
    else
        ChosenLadder:PrintToWindow("Usage: /cldunk <itemLink>|cancel")
    end
end

function ChosenLadder:Auction(input)
    if not D:IsLootMaster() then
        ChosenLadder:PrintToWindow("You're not the loot master!")
        return
    end

    local arg1 = self:GetArgs(input, 1)
    if arg1 == nil then
        ChosenLadder:PrintToWindow("Usage: /clauction <itemLink>|stop")
    elseif F.IsItemLink(arg1) then
        -- starting an auction
        D.Auction:Start(arg1)
    elseif string.lower(arg1) == "stop" then
        D.Auction:Complete()
    elseif string.lower(arg1) == "cancel" then
        D.Auction:Complete(true)
    else
        ChosenLadder:PrintToWindow("Usage: /clauction <itemLink>|stop")
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
                string.format("%s moved from position %d to position %d",
                    Ambiguate(v.playerName, "all"), v.from, v.to)
            )
        end
    else
        ChosenLadder:PrintToWindow("Usage: /cllog <auction/ladder>")
    end
end

function ChosenLadder:Help()
    ChosenLadder:PrintToWindow("ChosenLadder Help")
    ChosenLadder:PrintToWindow("/clhelp - Displays this list")
    ChosenLadder:PrintToWindow("/cl - Toggles the main ladder window")
    ChosenLadder:PrintToWindow(
        "/clauction <itemLink>|stop|cancel - Starts an auction for the linked item OR stops and auction and announces a winner OR cancels an auction"
    )
    ChosenLadder:PrintToWindow(
        "/cldunk <itemLink>|cancel - Starts an dunk session for the linked item OR cancels the current dunk session"
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
    local chatFrame = _G["ChatFrame" .. ChosenLadder:Database().char.outputChannel] or DEFAULT_CHAT_FRAME
    ChosenLadder:Print(chatFrame, text)
end

---@return LadderList
function ChosenLadder:GetLadder()
    return ChosenLadder:Database().factionrealm.ladder
end

---@return string[]
function ChosenLadder:GetLog()
    return ChosenLadder:Database().char.log
end

---@param message string
function ChosenLadder:Log(message)
    local logMaxSize = 2000
    local log = ChosenLadder:GetLog()

    if #log >= logMaxSize then
        local newLog = {}
        for i, v in ipairs(log) do
            if i ~= 0 then
                newLog[i - 1] = v
            end
        end
        log = newLog
    end

    table.insert(log, GetServerTime() .. "||" .. message)
    ChosenLadder:Database().char.log = log

    local localDebug = false
    if localDebug then
        ChosenLadder:PrintToWindow(message)
    end
end
