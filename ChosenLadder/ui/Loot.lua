local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

UI.Loot = {}
local Loot = UI.Loot

for i = 1, 16 do
    table.insert(D.lootMasterItems, GetInventoryItemLink("player", i))
end

local function CreateLootRowItem(parentScrollFrame, item, idx)
    local row = CreateFrame("Frame", UI.UIPrefixes.LootRow .. idx, parentScrollFrame, "BackdropTemplate")
    row:SetSize(parentScrollFrame:GetWidth() - 8, 28)
    row:SetPoint("TOPLEFT", parentScrollFrame, 12, (idx - 1) * -28)

    local textFont = row:CreateFontString(UI.UIPrefixes.LootItemNameString .. idx, nil, "GameFontNormal")
    textFont:SetText(item)
    textFont:SetPoint("TOPLEFT", row, 4, -8)

    -- Dunk Button
    local dunkButton = CreateFrame("Button", UI.UIPrefixes.LootDunkButton .. idx, row, "UIPanelButtonTemplate")
    dunkButton:SetText(D.Dunk.dunkItem == idx and "Cancel Dunk" or "Start Dunk")
    dunkButton:SetWidth(92)
    dunkButton:SetPoint("TOPRIGHT", row, -2, -2)
    dunkButton:SetScript(
        "OnClick",
        function(self, button, down)
            if D.dunkItem == idx then
                D.Dunk:CompleteAnnounce()
            else
                D.Dunk:Start(idx)
            end
        end
    )

    -- Auction Button
    local auctionButton = CreateFrame("Button", UI.UIPrefixes.LootAuctionButton .. idx, row, "UIPanelButtonTemplate")
    auctionButton:SetText(D.Auction.auctionItem == idx and "Cancel Auction" or "Start Auction")
    auctionButton:SetWidth(102)
    auctionButton:SetPoint("TOPRIGHT", dunkButton, -(dunkButton:GetWidth() + 2), 0)
    auctionButton:SetScript(
        "OnClick",
        function(self, button, down)
            if D.dunkItem == idx then
                D.Auction:Complete()
            else
                D.Auction:Start(idx)
            end
        end
    )

    return row
end

function Loot:CreateMainFrame(mainFrame)
    local contentFrame = CreateFrame("Frame", "ChosenLadderLootScrollContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, -5, -24)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -5, 3)

    local scrollFrame = CreateFrame("ScrollFrame", "ChosenLadderLootScrollFrame", contentFrame,
        "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, 3, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, -27, 4)
    scrollFrame:EnableMouse(true)

    contentFrame.scroll = scrollFrame
    contentFrame.scrollbar = ChosenLadderLootScrollFrameScrollBar

    -- Create the scrolling child frame, set its width to fit
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild

    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(scrollFrame:GetHeight())
    scrollChild:SetScript(
        "OnShow",
        function(self)
            Loot:PopulateLootList()
        end
    )

    self:PopulateLootList()
end

function Loot:PopulateLootList()
    if self.scrollChild ~= nil then
        for lootIdx, lootItem in ipairs(D.lootMasterItems) do
            -- Store the loot row, since we can't count on the WoW client to garbage collect
            local row = _G[UI.UIPrefixes.LootRow .. lootIdx] or CreateLootRowItem(self.scrollChild, lootItem, lootIdx)

            for _, child in ipairs({ row:GetChildren() }) do
                if F.StartsWith(child:GetName(), UI.UIPrefixes.LootDunkButton) then
                    -- The Dunk button!
                    child:SetEnabled(D.isLootMaster)
                elseif F.StartsWith(child:GetName(), UI.UIPrefixes.LootAuctionButton) then
                    -- The Auction button!
                    child:SetEnabled(D.isLootMaster)
                end
            end
        end
    end
end
