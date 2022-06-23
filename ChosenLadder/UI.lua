local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

UI.Constants = {
    actionButtonWidth = 102,
    FrameInset = {
        left = 6,
        right = 6,
        top = 24,
        bottom = 3
    },
    LeftFrame = { width = 106 }
}


UI.UIPrefixes = {
    PlayerRow = "ChosenLadderPlayerRow",
    PlayerDunkButton = "ChosenLadderDunkButton",
    PlayerNameString = "ChosenLadderTextString",
    RaidMemberDropDown = "ChosenLadderRaidMemberDropDown",
    LootRow = "ChosenLadderLootRow",
    LootDunkButton = "ChosenLadderLootDunkButton",
    LootAuctionButton = "ChosenLadderLootAuctionButton",
    LootItemNameString = "ChosenLadderLootTextString",
    LootItemClearButton = "ChosenLadderLootClearButton"
}

function CreateMainWindowFrame()
    local mainWidth = 600
    local mainHeight = 400

    local mainFrame = CreateFrame("Frame", "ChosenLadderFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetSize(mainWidth, mainHeight)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    UI.mainFrame = mainFrame
    _G["ChosenLadderFrame"] = mainFrame

    -- Title Text
    local title = mainFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    title:SetPoint("TOPLEFT", 5, -5)
    title:SetText("Chosen Ladder")

    local tabButton1 = CreateFrame("Button", "$parentTab1", mainFrame, "CharacterFrameTabButtonTemplate")
    tabButton1:SetText("Ladder")
    tabButton1:SetPoint("TOPLEFT", mainFrame, 0, -mainFrame:GetHeight())

    local tabButton2 = CreateFrame("Button", "$parentTab2", mainFrame, "CharacterFrameTabButtonTemplate")
    tabButton2:SetText("Loot")
    tabButton2:SetPoint("BOTTOMLEFT", tabButton1, tabButton1:GetWidth() - 12, 0)

    local tabFrame1 = CreateFrame("Frame", "TabPage1", mainFrame)
    tabFrame1:SetPoint("TOPLEFT", mainFrame, 0, 0)
    tabFrame1:SetPoint("BOTTOMRIGHT", mainFrame, 0, 0)

    local tabFrame2 = CreateFrame("Frame", "TabPage2", mainFrame)
    tabFrame2:SetPoint("TOPLEFT", mainFrame, 0, 0)
    tabFrame2:SetPoint("BOTTOMRIGHT", mainFrame, 0, 0)
    tabFrame2:Hide()

    tabButton1:SetScript("OnClick", function(self)
        PlaySound(681);
        PanelTemplates_SetTab(mainFrame, 1)
        tabFrame1:Show()
        tabFrame2:Hide()
    end)

    tabButton2:SetScript("OnClick", function(self)
        PlaySound(681);
        PanelTemplates_SetTab(mainFrame, 2)
        tabFrame2:Show()
        tabFrame1:Hide()
    end)

    PanelTemplates_SetNumTabs(mainFrame, 2)
    PanelTemplates_SetTab(mainFrame, 1)

    UI.Ladder:CreateMainFrame(tabFrame1)
    UI.Loot:CreateMainFrame(tabFrame2)

    UI.Ladder:PopulatePlayerList()
end

UI.CreateMainWindowFrame = CreateMainWindowFrame

function ToggleMainWindowFrame()
    if (UI.mainFrame == nil) then
        CreateMainWindowFrame()
        return
    end

    if UI.mainFrame:IsShown() then
        UI.mainFrame:Hide()
    else
        UI.mainFrame:Show()
    end
end

UI.ToggleMainWindowFrame = ToggleMainWindowFrame

function UpdateElementsByPermission()
    if UI.syncButton ~= nil then
        UI.syncButton:SetEnabled(D.isLootMaster or false)
    end

    if UI.importSaveButton ~= nil then
        UI.importSaveButton:SetEnabled(D.isLootMaster or false)
    end

    UI.Ladder:PopulatePlayerList()
end

UI.UpdateElementsByPermission = UpdateElementsByPermission
