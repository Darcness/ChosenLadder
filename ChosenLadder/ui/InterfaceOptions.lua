local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

UI.InterfaceOptions = {}
local IO = UI.InterfaceOptions
local UIC = UI.Constants

function IO:CreatePanel()
    local panel = CreateFrame("Frame", UI.UIPrefixes.InterfaceOptionsPanel)
    panel.name = A
    InterfaceOptions_AddCategory(panel)
    InterfaceAddOnsList_Update()

    local fontTitle = panel:CreateFontString("ChosenLadderInterfaceOptionsTitleString", nil, "GameFontNormal")
    fontTitle:SetPoint("TOPLEFT", panel, 8, -8)
    fontTitle:SetText(A)

    local toggleButton = CreateFrame("Button", UI.UIPrefixes.InterfaceOptionsToggleMainWindowButton, panel,
        "UIPanelButtonTemplate")
    toggleButton:SetPoint("TOPLEFT", fontTitle, -2, -(fontTitle:GetHeight() + 4))
    toggleButton:SetWidth(102)
    toggleButton:SetText("Toggle Ladder")
    toggleButton:SetScript("OnClick", function()
        UI.ToggleMainWindowFrame()
    end)

    local bidFontContainer = CreateFrame("Frame", "ChosenLadderInterfaceOptionsBiddingStepsFontContainer", panel,
        "BackdropTemplate")
    bidFontContainer:SetPoint("TOPLEFT", toggleButton, 2, -(toggleButton:GetHeight() + 4))
    bidFontContainer:SetWidth(300)
    bidFontContainer:SetHeight(36)
    bidFontContainer:SetBackdropBorderColor(1, 1, 1, 1)
    bidFontContainer:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Auction Bidding Steps")
        GameTooltip:AddLine("Sets the Bidding Steps for an auction, starting with the minimum bid and including how much bids must increase."
            , 1, 1, 1, true)
        GameTooltip:AddLine("\n\r")
        GameTooltip:AddLine("Format: <Step1Start>:<Step1Size>|<Step2Start>:<Step2Size>|...<StepNStart>:<StepNSize>", 1, 1
            , 1, false)
        GameTooltip:AddLine("\n\r")
        GameTooltip:AddLine("For example, 50:10|300:50|1000:1000 is the default Bidding steps.  This means that the minimum bid is 50. Bids must increase by 10 until the bid reaches 300.  From there, they must increase by 50 until they reach 1000, and from then on they must increase by 100."
            , 1, 1, 1, true)
        GameTooltip:Show()
    end)
    bidFontContainer:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local fontSteps = bidFontContainer:CreateFontString("ChosenLadderInterfaceOptionsFontStepsString", nil,
        "GameFontNormal")
    fontSteps:SetPoint("TOPLEFT", bidFontContainer, 0, 0)
    fontSteps:SetText("Bidding Steps")

    local editBox = CreateFrame("EditBox", "ChosenLadderInterfaceOptionsBidSteps", bidFontContainer, "InputBoxTemplate")
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(false)
    editBox:SetWidth(200)
    editBox:SetHeight(36)
    editBox:SetPoint("TOPLEFT", bidFontContainer, fontSteps:GetWidth() + 8, 10)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetText(D.GetPrintableBidSteps())

    function panel.refresh()
        xpcall(function()
            editBox:SetCursorPosition(0)
        end, geterrorhandler())
    end

    self.ioPanel = panel
end
