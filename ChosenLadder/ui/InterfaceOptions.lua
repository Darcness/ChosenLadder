---@diagnostic disable: param-type-mismatch
local A, NS = ...

---@type Data
local D = NS.Data
---@type UI
local UI = NS.UI
---@type Functions
local F = NS.Functions

---@class InterfaceOptions
---@field rowHeight number
local InterfaceOptions = {
    rowHeight = 24
}
UI.InterfaceOptions = InterfaceOptions

local UIC = UI.Constants

local function ChatFrame_Initialize(frame, level, menuList)
    for i = 1, NUM_CHAT_WINDOWS do
        local name, _, _, _, _, _, _, _, _, uninteractible = GetChatWindowInfo(i)
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

            if i == ChosenLadder:Database().char.outputChannel then
                UIDropDownMenu_SetSelectedValue(frame, i, i)
                UIDropDownMenu_SetText(frame, name)
            end
        end
    end
end

local function LadderType_Initialize(frame, level, menuList)
    for k, v in pairs(D.Constants.LadderType) do
        local info = UIDropDownMenu_CreateInfo()
        info.value = v
        info.text = k
        info.func = function(item)
            UIDropDownMenu_SetSelectedValue(frame, v, v)
            UIDropDownMenu_SetText(frame, k)
            item.checked = true
        end

        UIDropDownMenu_AddButton(info, level)

        if v == ChosenLadder:Database().profile.ladderType then
            UIDropDownMenu_SetSelectedValue(frame, v, v)
            UIDropDownMenu_SetText(frame, k)
        end
    end
end

---Creates the base row Frame
---@param name string
---@param panel Frame
---@param previousRow Frame
---@return BackdropTemplate|Frame
local function CreateBaseRowFrame(name, panel, previousRow)
    local row = _G[name] or CreateFrame("Frame", name, panel, "BackdropTemplate")
    row:SetPoint("TOPLEFT", previousRow, 0, -(InterfaceOptions.rowHeight + 8))
    row:SetPoint("BOTTOMRIGHT", previousRow, 0, -(InterfaceOptions.rowHeight + 8))
    row:SetHeight(InterfaceOptions.rowHeight)

    return row
end

---@param panel Frame
---@param previousRow Frame
---@return BackdropTemplate|Frame
local function CreateMinimapRow(panel, previousRow)
    local row = CreateBaseRowFrame("ChosenLadderOptionsMinimapContainer", panel, previousRow)

    local minimapCheck = _G["ChosenLadderOptionsMinimapCheck"] or
        CreateFrame("CheckButton", "ChosenLadderOptionsMinimapCheck", row, "UICheckButtonTemplate")
    minimapCheck:SetSize(28, 28)
    minimapCheck:SetPoint("LEFT", row, 0, 0)
    minimapCheck:SetChecked(not ChosenLadder:Database().char.minimap.hide)
    minimapCheck:SetScript("OnClick", function(self) ChosenLadder:SetMinimapHidden(not self:GetChecked()) end)

    local fontLabel = _G["ChosenLadderOptionsMinimapFontString"] or
        row:CreateFontString("ChosenLadderOptionsMinimapFontString", nil, "GameFontNormal")
    fontLabel:SetPoint("LEFT", minimapCheck, minimapCheck:GetWidth() + 4, 0)
    fontLabel:SetText("Show Minimap Icon")
    minimapCheck:SetFontString(fontLabel)

    return row
end

---@param panel Frame
---@param previousRow Frame
---@return BackdropTemplate|Frame
---@return EditBox|InputBoxTemplate
local function CreateBidStepsRow(panel, previousRow)
    local row = CreateBaseRowFrame("ChosenLadderOptionsBiddingStepsFontContainer", panel, previousRow)
    row:SetScript("OnEnter", function(self)
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
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local fontLabel = _G["ChosenLadderOptionsStepsFontString"] or
        row:CreateFontString("ChosenLadderOptionsStepsFontString", nil, "GameFontNormal")
    fontLabel:SetPoint("LEFT", row, 0, 0)
    fontLabel:SetText("Bidding Steps")

    local editBox = _G[UI.UIPrefixes.OptionsBidSteps] or
        CreateFrame("EditBox", UI.UIPrefixes.OptionsBidSteps, row, "InputBoxTemplate")
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(false)
    editBox:SetWidth(200)
    editBox:SetHeight(InterfaceOptions.rowHeight)
    editBox:SetPoint("LEFT", fontLabel, fontLabel:GetWidth() + 8, 0)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetText(D:GetPrintableBidSteps())
    editBox:SetCursorPosition(0)

    return row, editBox
end

---@param panel Frame
---@param previousRow Frame
---@return BackdropTemplate|Frame
---@return Frame|UIDropdownMenuTemplate
local function CreateOutputChannelRow(panel, previousRow)
    local row = CreateBaseRowFrame("ChosenLadderOptionsOutputChannelContainer", panel, previousRow)

    local fontLabel = _G["ChosenLadderOptionsOutputFontString"] or
        row:CreateFontString("ChosenLadderOptionsOutputFontString", nil, "GameFontNormal")
    fontLabel:SetPoint("LEFT", row, 0, 0)
    fontLabel:SetText("Output Window (Chat Frame)")

    local outputDropdown = _G[UI.UIPrefixes.OptionsOutputDropdown] or
        CreateFrame("Frame", UI.UIPrefixes.OptionsOutputDropdown, row, "UIDropdownMenuTemplate")
    outputDropdown:SetPoint("LEFT", fontLabel, fontLabel:GetWidth() + 4, -2)
    UIDropDownMenu_SetWidth(outputDropdown, 100)
    UIDropDownMenu_Initialize(outputDropdown, ChatFrame_Initialize)

    return row, outputDropdown
end

---@param panel Frame
---@param previousRow Frame
---@return BackdropTemplate|Frame
---@return Frame|UIDropdownMenuTemplate
local function CreateLadderTypeRow(panel, previousRow)
    local row = CreateBaseRowFrame("ChosenLadderOptionsLadderTypeContainer", panel, previousRow)

    local fontLabel = _G["ChosenLadderOptionsLadderTypeFontString"] or
        row:CreateFontString("ChosenLadderOptionsLadderTypeFontString", nil, "GameFontNormal")
    fontLabel:SetPoint("LEFT", row, 0, 0)
    fontLabel:SetText("Ladder Type")

    local ladderTypeDropdown = _G[UI.UIPrefixes.OptionsLadderDropdown] or
        CreateFrame("Frame", UI.UIPrefixes.OptionsLadderDropdown, row, "UIDropdownMenuTemplate")
    ladderTypeDropdown:SetPoint("LEFT", fontLabel, fontLabel:GetWidth() + 4, -2)
    UIDropDownMenu_SetWidth(ladderTypeDropdown, 100)
    UIDropDownMenu_Initialize(ladderTypeDropdown, LadderType_Initialize)

    return row, ladderTypeDropdown
end

---Builds the names of Frames used for Announcement Checkboxes
---@param type string
---@return string
---@return string
local function AnnouncementFrameNames(type)
    local cbName = "ChosenLadderOptionsAnnouncement" .. type .. "Check"
    local lName = "ChosenLadderOptionsAnnouncement" .. type .. "Label"

    return cbName, lName
end

---@param type string
---@param parent Frame
---@param previousFrame Frame
---@param checked boolean
---@return CheckButton|UICheckButtonTemplate
---@return FontString
local function CreateAnnounceCheckbox(type, parent, previousFrame, checked)
    local cbName, lName = AnnouncementFrameNames(type)
    local checkBox = _G[cbName] or CreateFrame("CheckButton", cbName, parent, "UICheckButtonTemplate")
    checkBox:SetSize(28, 28)
    checkBox:SetPoint("LEFT", previousFrame, previousFrame:GetWidth() + 8, 0)
    checkBox:SetChecked(checked)

    local label = _G[lName] or parent:CreateFontString(lName, nil, "GameFontNormal")
    label:SetPoint("LEFT", checkBox, checkBox:GetWidth() + 2, 0)
    label:SetText("Auction Start")
    checkBox:SetFontString(label)

    return checkBox, label
end

---@param panel Frame
---@param previousRow Frame
---@return BackdropTemplate|Frame
---@return CheckButton|UICheckButtonTemplate
---@return CheckButton|UICheckButtonTemplate
---@return CheckButton|UICheckButtonTemplate
---@return CheckButton|UICheckButtonTemplate
---@return CheckButton|UICheckButtonTemplate
---@return CheckButton|UICheckButtonTemplate
---@return CheckButton|UICheckButtonTemplate
local function CreateAnnouncementsRow(panel, previousRow)
    local row = CreateBaseRowFrame("ChosenLadderOptionsAnnouncementContainer", panel, previousRow)

    local fontLabel = _G["ChosenLadderOptionsAnnouncementRowFontString"] or
        row:CreateFontString("ChosenLadderOptionsAnnouncementRowFontString", nil, "GameFontNormal")
    fontLabel:SetPoint("LEFT", row, 0, 0)
    fontLabel:SetText("Raid Warning")

    local auctionStartCheck, auctionStartLabel = CreateAnnounceCheckbox("AuctionStart", row, fontLabel,
        ChosenLadder:Database().char.announcements.auctionStart)
    local auctionCompleteCheck, auctionCompleteLabel = CreateAnnounceCheckbox("AuctionComplete", row, auctionStartLabel,
        ChosenLadder:Database().char.announcements.auctionComplete)
    local auctionCancelCheck, auctionCancelLabel = CreateAnnounceCheckbox("AuctionCancel", row, auctionCompleteLabel,
        ChosenLadder:Database().char.announcements.auctionCancel)

    local secondRow = CreateBaseRowFrame("ChosenLadderOptionsAnnouncementContainer2", panel, row)

    local auctionUpdateCheck = _G["ChosenLadderOptionsAnnouncementAuctionUpdateCheck"] or
        CreateFrame("CheckButton", "ChosenLadderOptionsAnnouncementAuctionUpdateCheck", secondRow,
            "UICheckButtonTemplate")
    auctionUpdateCheck:SetSize(28, 28)
    auctionUpdateCheck:SetPoint("LEFT", secondRow, fontLabel:GetWidth() + 8, 0)
    auctionUpdateCheck:SetChecked(ChosenLadder:Database().char.announcements.auctionUpdate)

    local auctionUpdateLabel = _G["ChosenLadderOptionsAnnouncementAuctionUpdateLabel"] or
        secondRow:CreateFontString("ChosenLadderOptionsAnnouncementAuctionUpdateLabel", nil, "GameFontNormal")
    auctionUpdateLabel:SetPoint("LEFT", auctionUpdateCheck, auctionUpdateCheck:GetWidth() + 4, 0)
    auctionUpdateLabel:SetText("Auction Update (Bid)")
    auctionUpdateCheck:SetFontString(auctionUpdateLabel)

    local dunkStartCheck, dunkStartLabel = CreateAnnounceCheckbox("DunkStart", secondRow, auctionUpdateLabel,
        ChosenLadder:Database().char.announcements.dunkStart)
    local dunkCompleteCheck, dunkCompleteLabel = CreateAnnounceCheckbox("DunkComplete", secondRow, dunkStartLabel,
        ChosenLadder:Database().char.announcements.dunkComplete)
    local dunkCancelCheck, dunkCancelLabel = CreateAnnounceCheckbox("DunkCancel", secondRow, dunkCompleteLabel,
        ChosenLadder:Database().char.announcements.dunkCancel)

    return secondRow, auctionStartCheck, auctionCompleteCheck, auctionCancelCheck, auctionUpdateCheck, dunkStartCheck,
        dunkCompleteCheck, dunkCancelCheck
end

function InterfaceOptions:CreatePanel()
    local panel = _G[UI.UIPrefixes.OptionsPanel]
    if panel == nil then
        panel = CreateFrame("Frame", UI.UIPrefixes.OptionsPanel)
        panel.name = A
        InterfaceOptions_AddCategory(panel)
        InterfaceAddOnsList_Update()
    end

    local titleRow = _G["ChosenLadderOptionsRow"] or
        CreateFrame("Frame", "ChosenLadderOptionsRow", panel, "BackdropTemplate")
    titleRow:SetPoint("TOPLEFT", panel, 8, -8)
    titleRow:SetHeight(InterfaceOptions.rowHeight)
    titleRow:SetWidth(600) -- Such an arbitrary number, but I can't control it otherwise.

    local fontTitle = _G["ChosenLadderOptionsTitleString"] or
        titleRow:CreateFontString("ChosenLadderOptionsTitleString", nil, "GameFontNormal")
    fontTitle:SetPoint("TOP", titleRow, 0, 0)
    fontTitle:SetText(A)

    local minimapRow = CreateMinimapRow(panel, titleRow)
    local bidRow, editBox = CreateBidStepsRow(panel, minimapRow)
    local outputRow, outputDropdown = CreateOutputChannelRow(panel, bidRow)
    local announcementsRow, auctionStartCheck, auctionCompleteCheck, auctionCancelCheck, auctionUpdateCheck, dunkStartCheck, dunkCompleteCheck, dunkCancelCheck = CreateAnnouncementsRow(panel
        , outputRow)
    local ladderTypeRow, ladderTypeDropdown = CreateLadderTypeRow(panel, announcementsRow)

    function panel.okay()
        xpcall(function()
            ChosenLadder:Database().char.outputChannel = UIDropDownMenu_GetSelectedValue(outputDropdown)
            D:SetBidSteps(editBox:GetText())
            ChosenLadder:Database().profile.ladderType = UIDropDownMenu_GetSelectedValue(ladderTypeDropdown)
            ChosenLadder:Database().char.announcements.auctionCancel = auctionCancelCheck:GetChecked() == true
            ChosenLadder:Database().char.announcements.auctionComplete = auctionCompleteCheck:GetChecked() == true
            ChosenLadder:Database().char.announcements.auctionStart = auctionStartCheck:GetChecked() == true
            ChosenLadder:Database().char.announcements.auctionUpdate = auctionUpdateCheck:GetChecked() == true
            ChosenLadder:Database().char.announcements.dunkCancel = dunkCancelCheck:GetChecked() == true
            ChosenLadder:Database().char.announcements.dunkComplete = dunkCompleteCheck:GetChecked() == true
            ChosenLadder:Database().char.announcements.dunkStart = dunkStartCheck:GetChecked() == true
        end, geterrorhandler())
    end

    function panel.default()
        xpcall(function()
            ChosenLadder:Database().char.outputChannel = 1
            UIDropDownMenu_SetSelectedValue(outputDropdown, 1, 1)
            UIDropDownMenu_SetSelectedValue(ladderTypeDropdown, 1, 1)
            local defaultSteps = "50:10|300:50|1000:100"
            D:SetBidSteps(defaultSteps)
            editBox:SetText(defaultSteps)
        end, geterrorhandler())
    end

    function panel.cancel()
        xpcall(function()
            InterfaceOptions:CreatePanel()
        end, geterrorhandler())
    end

    self.ioPanel = panel
end
