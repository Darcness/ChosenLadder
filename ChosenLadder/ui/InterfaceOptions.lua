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

local function LadderType_Initialize(frame, level, menuList)
    for k, v in ipairs(D.Constants.LadderType) do
        local info = UIDropDownMenu_CreateInfo()
        info.value = k
        info.text = v
        info.func = function(item)
            UIDropDownMenu_SetSelectedValue(frame, k, k)
            UIDropDownMenu_SetText(frame, v)
        end

        UIDropDownMenu_AddButton(info, level)

        if k == ChosenLadder.db.char.ladderType then
            UIDropDownMenu_SetSelectedValue(frame, k, k)
            UIDropDownMenu_SetText(frame, v)
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

    local minimapRow = CreateFrame("Frame", "ChosenLadderOptionsMinimapContainer", panel, "BackdropTemplate")
    minimapRow:SetPoint("TOPLEFT", fontTitle, 0, -(rowHeight + 8))
    minimapRow:SetHeight(rowHeight)

    local minimapCheck = CreateFrame("CheckButton", nil, minimapRow, "UICheckButtonTemplate")
    minimapCheck:SetSize(28, 28)
    minimapCheck:SetPoint("LEFT", minimapRow, 0, 0)
    minimapCheck:SetChecked(not ChosenLadder.db.profile.minimap.hide)
    minimapCheck:SetScript("OnClick", function(self) ChosenLadder:SetMinimapHidden(not self:GetChecked()) end)

    local fontMinimap = minimapRow:CreateFontString("ChosenLadderOptionsMinimapFontString", nil, "GameFontNormal")
    fontMinimap:SetPoint("LEFT", minimapCheck, minimapCheck:GetWidth() + 8, 0)
    fontMinimap:SetText("Show Minimap Icon")
    minimapCheck:SetFontString(fontMinimap)

    minimapRow:SetWidth(minimapCheck:GetWidth() + 8 + fontMinimap:GetWidth())

    local bidRow = CreateFrame("Frame", "ChosenLadderOptionsBiddingStepsFontContainer", panel,
        "BackdropTemplate")
    bidRow:SetPoint("TOPLEFT", minimapRow, 2, -(rowHeight + 8))
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

    local ladderTypeRow = CreateFrame("Frame", "ChosenLadderOptionsLadderTypeContainer", panel,
        "BackdropTemplate")
    ladderTypeRow:SetPoint("TOPLEFT", outputRow, 0, -(rowHeight + 8))
    ladderTypeRow:SetHeight(rowHeight)

    local fontLadderType = ladderTypeRow:CreateFontString("ChosenLadderOptionsLadderTypeFontString", nil,
        "GameFontNormal")
    fontLadderType:SetPoint("LEFT", outputRow, 0, 0)
    fontLadderType:SetText("Ladder Type")

    local ladderTypeDropdown = CreateFrame("Frame", UI.UIPrefixes.OptionsLadderDropdown, ladderTypeRow,
        "UIDropdownMenuTemplate")
    ladderTypeDropdown:SetPoint("LEFT", fontLadderType, fontLadderType:GetWidth() + 4, -2)
    UIDropDownMenu_SetWidth(ladderTypeDropdown, 100)
    UIDropDownMenu_Initialize(ladderTypeDropdown, LadderType_Initialize)

    ladderTypeRow:SetWidth(fontLadderType:GetWidth() + 4 + 100)

    function panel.okay()
        xpcall(function()
            ChosenLadderOutputChannel = UIDropDownMenu_GetSelectedValue(outputDropdown)
            D.SetBidSteps(editBox:GetText())
            ChosenLadder.db.char.ladderType = UIDropDownMenu_GetSelectedValue(ladderTypeDropdown)
        end, geterrorhandler())
    end

    function panel.default()
        xpcall(function()
            ChosenLadderOutputChannel = 1
            UIDropDownMenu_SetSelectedValue(ladderTypeDropdown, 1, 1)
            local defaultSteps = "50:10|300:50|1000:100"
            D.SetBidSteps(defaultSteps)
            editBox:SetText(defaultSteps)
        end, geterrorhandler())
    end

    self.ioPanel = panel
end
