---@diagnostic disable: param-type-mismatch
local A, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

-- UI Container
---@class UI
---@field UIPrefixes UIPrefixes
---@field Constants UIConstants
---@field Loot Loot
---@field Ladder Ladder
---@field InterfaceOptions InterfaceOptions
---@field scrollChild? Frame
---@field importFrame? Frame
---@field syncButton? Button
---@field importSaveButton? Button
local UI = {
    ---@class UIConstants
    ---@field actionButtonWidth number
    ---@field FrameInset UIConstantFrameInset
    ---@field LeftFrame UIConstantLeftFrame
    ---@field DevBackdrop backdropInfo
    Constants = {
        actionButtonWidth = 112,
        ---@class UIConstantFrameInset
        ---@field left number
        ---@field right number
        ---@field top number
        ---@field bottom number
        FrameInset = {
            left = 6,
            right = 6,
            top = 24,
            bottom = 3
        },
        ---@class UIConstantLeftFrame
        ---@field width number
        LeftFrame = { width = 116 },
        DevBackdrop = {
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tileEdge = true,
            edgeSize = 8
        }
    },
    ---@class UIPrefixes
    UIPrefixes = {
        PlayerRow = "ChosenLadderPlayerRow",
        PlayerDunkButton = "ChosenLadderDunkButton",
        PlayerNameString = "ChosenLadderTextString",
        PlayerClearAltsButton = "ChosenLadderClearAltsButton",
        RaidMemberDropDown = "ChosenLadderRaidMemberDropDown",
        LootRow = "ChosenLadderLootRow",
        LootDunkButton = "ChosenLadderLootDunkButton",
        LootAuctionButton = "ChosenLadderLootAuctionButton",
        LootItemNameString = "ChosenLadderLootTextString",
        LootItemClearButton = "ChosenLadderLootClearButton",
        OptionsPanel = "ChosenLadderOptionsMainFrame",
        OptionsToggleMainWindowButton = "ChosenLadderOptionsMainWindowButton",
        OptionsBidSteps = "ChosenLadderOptionsBidSteps",
        OptionsOutputDropdown = "ChosenLadderOptionsOutputDropdown",
        OptionsLadderDropdown = "ChosenLadderOptionsLadderTypeDropdown"
    }
}
NS.UI = UI

function CreateMainWindowFrame()
    local mainWidth = 650
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

function UI:ToggleMainWindowFrame()
    if (self.mainFrame == nil) then
        CreateMainWindowFrame()
        return
    end

    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
    end
end

function UI:UpdateElementsByPermission()
    if UI.syncButton ~= nil then
        UI.syncButton:SetEnabled(D:IsLootMaster())
    end

    if UI.importSaveButton ~= nil then
        UI.importSaveButton:SetEnabled(D:IsLootMaster())
    end

    self.Ladder:PopulatePlayerList()
end
