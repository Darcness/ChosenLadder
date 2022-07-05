local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

UI.Loot = {}
local Loot = UI.Loot

local UIC = UI.Constants

-- for i = 1, 16 do
--     local item = Item:CreateFromEquipmentSlot(i)
--     local guid = item:GetItemGUID()
--     local itemLink = item:GetItemLink()

--     table.insert(D.lootMasterItems, {
--         guid = guid,
--         itemLink = itemLink,
--         sold = false
--     })

-- end

local function CreateLootRowItem(parentScrollFrame, item, idx)
    local row = CreateFrame("Frame", UI.UIPrefixes.LootRow .. item.guid, parentScrollFrame, "BackdropTemplate")
    row:SetSize(parentScrollFrame:GetWidth() - 8, 28)
    row:SetPoint("TOPLEFT", parentScrollFrame, 12, (idx - 1) * -28)
    row:SetHyperlinksEnabled(true)
    row:SetScript("OnHyperlinkClick", function(self, link, text, button)
        GameTooltip:SetOwner(row, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(item.itemLink)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local textFont = row:CreateFontString(UI.UIPrefixes.LootItemNameString .. item.guid, nil, "GameFontNormal")
    textFont:SetText(item.itemLink)
    textFont:SetPoint("TOPLEFT", row, 4, -8)

    -- Dunk Button
    local dunkButton = CreateFrame("Button", UI.UIPrefixes.LootDunkButton .. item.guid, row, "UIPanelButtonTemplate")
    dunkButton:SetText(D.Dunk.dunkItem == item.guid and "Cancel Dunk" or "Start Dunk")
    dunkButton:SetWidth(92)
    dunkButton:SetPoint("TOPRIGHT", row, -2, -2)
    dunkButton:SetScript(
        "OnClick",
        function(self, button, down)
            if D.dunkItem == item.guid then
                D.Dunk:CompleteAnnounce()
            else
                D.Dunk:Start(item.guid)
            end
        end
    )

    -- Auction Button
    local auctionButton = CreateFrame("Button", UI.UIPrefixes.LootAuctionButton .. item.guid, row,
        "UIPanelButtonTemplate")
    auctionButton:SetText(D.Auction.auctionItem == item.guid and "Cancel Auction" or "Start Auction")
    auctionButton:SetWidth(102)
    auctionButton:SetPoint("TOPRIGHT", dunkButton, -(dunkButton:GetWidth() + 2), 0)
    auctionButton:SetScript(
        "OnClick",
        function(self, button, down)
            if D.dunkItem == item.guid then
                D.Auction:Complete()
            else
                D.Auction:Start(item.guid)
            end
        end
    )

    local clearButton = CreateFrame("Button", UI.UIPrefixes.LootItemClearButton .. item.guid, row,
        "UIPanelButtonTemplate")
    clearButton:SetText("Clear")
    clearButton:SetWidth(48)
    clearButton:SetPoint("TOPRIGHT", auctionButton, -(auctionButton:GetWidth() + 2), 0)
    clearButton:SetScript("OnClick", function(self, button, down)
        D.RemoveLootItemByGUID(item.guid)
        Loot:PopulateLootList()
    end)

    return row
end

function Loot:CreateMainFrame(mainFrame)
    local actionFrame = CreateFrame("Frame", "ChosenLadderLootActionContentFrame", mainFrame, "BackdropTemplate")
    actionFrame:SetPoint("TOPLEFT", mainFrame, UIC.FrameInset.left, -UIC.FrameInset.top)
    actionFrame:SetPoint("BOTTOMRIGHT", mainFrame, -UIC.LeftFrame.width, UIC.FrameInset.bottom)

    local clearButton = CreateFrame("Button", "ChosenLadderLootClearAllButton", actionFrame, "UIPanelButtonTemplate")
    clearButton:SetWidth(UIC.actionButtonWidth)
    clearButton:SetPoint("TOPLEFT", actionFrame, 6, -6)
    clearButton:SetText("Clear All")
    clearButton:SetScript(
        "OnClick",
        function(self, button, down)
            D.lootMasterItems = {}
            Loot:PopulateLootList()
        end
    )

    local contentFrame = CreateFrame("Frame", "ChosenLadderLootScrollContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, UIC.LeftFrame.width, -UIC.FrameInset.top)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -UIC.FrameInset.right, UIC.FrameInset.bottom)

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

    Loot:PopulateLootList()
end

function Loot:PopulateLootList()
    -- If there's no scrollChild yet, we have nothing to populate.
    if self.scrollChild == nil then
        return
    end

    local children = { self.scrollChild:GetChildren() }
    for _, child in ipairs(children) do
        -- We want to hide the old ones, so they're not on mangling the new ones.
        child:Hide()
    end

    for lootIdx, lootItem in ipairs(D.lootMasterItems) do
        if lootItem ~= nil and lootItem.guid ~= nil then
            -- Store the loot row, since we can't count on the WoW client to garbage collect
            local row = _G[UI.UIPrefixes.LootRow .. lootItem.guid] or
                CreateLootRowItem(self.scrollChild, lootItem, lootIdx)
            row:SetPoint("TOPLEFT", self.scrollChild, 4, (lootIdx - 1) * -28)
            row:Show()


            for _, child in ipairs({ row:GetChildren() }) do
                if F.StartsWith(child:GetName(), UI.UIPrefixes.LootDunkButton) then
                    -- The Dunk button!
                    child:SetEnabled(D.isLootMaster and not lootItem.sold)
                elseif F.StartsWith(child:GetName(), UI.UIPrefixes.LootAuctionButton) then
                    -- The Auction button!
                    child:SetEnabled(D.isLootMaster and not lootItem.sold)
                elseif F.StartsWith(child:GetName(), UI.UIPrefixes.LootItemNameString) then
                    if lootItem.sold then
                        child:SetFontObject("GameFontDisable")
                    else
                        child:SetFontObject("GameFontNormal")
                    end
                end
            end
        end
    end
end
