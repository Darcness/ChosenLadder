local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

UI.InterfaceOptions = {}
local IO = UI.InterfaceOptions
local UIC = UI.Constants

local function ChatFrame_Initialize(frame, level, menuList)
    for i = 1, NUM_CHAT_WINDOWS do
        local name, _, _, _, _, _, shown, locked, docked, uninteractible = GetChatWindowInfo(i)
        if name ~= nil and name ~= "" and not uninteractible then
            local info = UIDropDownMenu_CreateInfo()
            info.value = i
            info.text = name
            info.func = function(item)
                UIDropDownMenu_SetSelectedValue(frame, i, i)
                UIDropDownMenu_SetText(frame, name)
                item.checked = true
            end

            UIDropDownMenu_AddButton(info, level)

            if i == ChosenLadderOutputChannel then
                UIDropDownMenu_SetSelectedValue(frame, i, i)
                UIDropDownMenu_SetText(frame, name)
            end
        end
    end
end

function IO:CreatePanel()
    local rowHeight = 24
    local panel = CreateFrame("Frame", UI.UIPrefixes.OptionsPanel)
    panel.name = A
    InterfaceOptions_AddCategory(panel)
    InterfaceAddOnsList_Update()

    local fontTitle = panel:CreateFontString("ChosenLadderOptionsTitleString", nil, "GameFontNormal")
    fontTitle:SetPoint("TOPLEFT", panel, 8, -8)
    fontTitle:SetText(A)

    local toggleButton = CreateFrame("Button", UI.UIPrefixes.OptionsToggleMainWindowButton, panel,
        "UIPanelButtonTemplate")
    toggleButton:SetPoint("TOPLEFT", fontTitle, -2, -(fontTitle:GetHeight() + 4))
    toggleButton:SetWidth(102)
    toggleButton:SetText("Toggle Ladder")
    toggleButton:SetScript("OnClick", function()
        UI.ToggleMainWindowFrame()
    end)

    local bidRow = CreateFrame("Frame", "ChosenLadderOptionsBiddingStepsFontContainer", panel,
        "BackdropTemplate")
    bidRow:SetPoint("TOPLEFT", toggleButton, 2, -(toggleButton:GetHeight() + 4))
    bidRow:SetHeight(rowHeight)
    bidRow:SetScript("OnEnter", function(self)
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
    bidRow:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local fontSteps = bidRow:CreateFontString("ChosenLadderOptionsStepsFontString", nil,
        "GameFontNormal")
    fontSteps:SetPoint("LEFT", bidRow, 0, 0)
    fontSteps:SetText("Bidding Steps")

    local editBox = CreateFrame("EditBox", UI.UIPrefixes.OptionsBidSteps, bidRow, "InputBoxTemplate")
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(false)
    editBox:SetWidth(200)
    editBox:SetHeight(bidRow:GetHeight())
    editBox:SetPoint("LEFT", fontSteps, fontSteps:GetWidth() + 8, 0)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetText(D.GetPrintableBidSteps())
    editBox:SetCursorPosition(0)

    bidRow:SetWidth(fontSteps:GetWidth() + 8 + editBox:GetWidth())

    local outputRow = CreateFrame("Frame", "ChosenLadderOptionsOutputChannelContainer", panel,
        "BackdropTemplate")
    outputRow:SetPoint("TOPLEFT", bidRow, 0, -(rowHeight + 8))
    outputRow:SetHeight(rowHeight)

    local fontOutput = outputRow:CreateFontString("ChosenLadderOptionsOutputFontString", nil, "GameFontNormal")
    fontOutput:SetPoint("LEFT", outputRow, 0, 0)
    fontOutput:SetText("Output Window (Chat Frame)")

    local outputDropdown = CreateFrame("Frame", UI.UIPrefixes.OptionsOutputDropdown, outputRow, "UIDropdownMenuTemplate")
    outputDropdown:SetPoint("LEFT", fontOutput, fontOutput:GetWidth() + 4, -2)
    UIDropDownMenu_SetWidth(outputDropdown, 100)
    UIDropDownMenu_Initialize(outputDropdown, ChatFrame_Initialize)

    outputRow:SetWidth(fontOutput:GetWidth() + 4 + 100)

    function panel.okay()
        xpcall(function()
            ChosenLadderOutputChannel = UIDropDownMenu_GetSelectedValue(outputDropdown)
            D.SetBidSteps(editBox:GetText())
        end, geterrorhandler())
    end

    self.ioPanel = panel
end
