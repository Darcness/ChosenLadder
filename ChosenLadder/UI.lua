local CL, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

local toggleAll = false

local UIPrefixes = {
    PlayerRow = "ChosenLadderPlayerRow",
    CheckButton = "ChosenLadderCheckButton",
    DunkButton = "ChosenLadderDunkButton"
}

function CreatePlayerRowItem(parentScrollFrame, text, checked, idx, maxNameSize)
    -- Create a container frame
    local row = CreateFrame("Frame", UIPrefixes.PlayerRow .. text, parentScrollFrame, "BackdropTemplate")
    row:SetSize(parentScrollFrame:GetWidth(), 28)
    row:SetPoint("TOPLEFT", parentScrollFrame, 0, (idx - 1) * -28)

    -- Create the CheckButton
    local cb = CreateFrame("CheckButton", UIPrefixes.CheckButton .. text, row, "UICheckButtonTemplate")
    cb:SetSize(28, 28)
    cb:SetPoint("TOPLEFT", row, 0, 0)

    -- Set the Font
    local textFont = cb:CreateFontString("ARTWORK", nil, "GameFontNormal")
    textFont:SetText(idx .. " - " .. text)
    textFont:SetPoint("TOPLEFT", cb, cb:GetWidth() + 4, -8)
    cb:SetFontString(textFont)

    -- Any other properties
    cb:SetChecked(checked)
    cb:SetScript("OnClick", function(self, button, down)
        D.TogglePresent(text)
    end)

    local dunkButton = CreateFrame("Button", UIPrefixes.DunkButton .. text, row, "UIPanelButtonTemplate")
    dunkButton:SetText("Dunk")
    dunkButton:SetPoint("TOPLEFT", textFont, (maxNameSize * 7) + 4, 6)
    dunkButton:SetScript("OnClick", function(self, button, down)
        D.RunDunk(text)
        PopulatePlayerList(parentScrollFrame)
    end)

    return row
end

function GetMaxNameSize()
    local maxNameSize = 0
    for _, v in ipairs(D.players) do
        maxNameSize = math.max(maxNameSize, string.len(v.name) + 4) -- Add in "## -" where ## is their list spot.
    end

    return maxNameSize
end

function PopulatePlayerList(parentScrollFrame)
    -- We get this here so we're not re-calculating it for every row.
    local maxNameSize = GetMaxNameSize()

    local children = { parentScrollFrame:GetChildren() }
    for i, child in ipairs(children) do
        -- We want to hide the old ones, so they're not on mangling the new ones.
        child:Hide()
    end

    for k, v in ipairs(D.players) do
        -- Store the player row, since we can't count on the WoW client to garbage collect
        if _G[UIPrefixes.PlayerRow .. v.name] == nil then
            _G[UIPrefixes.PlayerRow .. v.name] = CreatePlayerRowItem(parentScrollFrame, v.name, v.present, k, maxNameSize)
        end

        -- Grab the stored player row and visually reorder it.
        local playerRow = _G[UIPrefixes.PlayerRow .. v.name]
        playerRow:SetPoint("TOPLEFT", parentScrollFrame, 0, (k - 1) * -28)
        -- Show them, in case they existed before and we hid them.
        playerRow:Show()

        -- Fix the Dunk button alignment
        local dunkButton = _G[UIPrefixes.DunkButton .. v.name]
        dunkButton:SetPoint("TOPLEFT", playerRow, (maxNameSize * 7) + 36, -4)
    end
end

function CreateImportFrame()
    local mainFrame = CreateFrame("Frame", "ChosenLadderImportFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetSize(400, 400)
    mainFrame:SetMovable(false)
    UI.importFrame = mainFrame
    _G["ChosenLadderImportFrame"] = mainFrame
    tinsert(UISpecialFrames, mainFrame:GetName())

    -- Title Text
    local title = mainFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    title:SetPoint("TOPLEFT", 5, -5)
    title:SetText("Import Names (one per line)")

    -- Import Button
    local importButton = CreateFrame("Button", "ChosenLadderImportButton", mainFrame, "UIPanelButtonTemplate")
    importButton:SetWidth(64)
    importButton:SetPoint("TOPRIGHT", mainFrame, -24, 0)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function(self, button, down)
        local text = ChosenLadderImportEditBox:GetText()
        local lines = {}
        for line in text:gmatch("([^\n]*)\n?") do
            if string.len(line) > 0 then
                table.insert(lines, F.Trim(line))
            end
        end
        D.BuildPlayerList(lines)

        ToggleImportFrame()
        ToggleMainWindowFrame()
    end)

    -- Content Window
    local contentFrame = CreateFrame("Frame", "ChosenLadderImportContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, 6, -24)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -5, 3)

    local scrollFrame = CreateFrame("ScrollFrame", "ChosenLadderImportScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, 3, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, -27, 4)
    scrollFrame:EnableMouse(true)

    contentFrame.scroll = scrollFrame
    contentFrame.scrollbar = ChosenLadderImportScrollFrameScrollBar

    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local editBox = CreateFrame("EditBox", "ChosenLadderImportEditBox", scrollFrame)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(true)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetHeight(scrollFrame:GetHeight())
    scrollFrame:SetScrollChild(editBox)

    mainFrame:Raise()
end

function ToggleImportFrame()
    if (UI.importFrame == nil) then
        CreateImportFrame()
        return
    end

    if UI.importFrame:IsShown() then
        UI.importFrame:Hide()
    else
        UI.importFrame:Show()
    end
end

UI.ToggleImportFrame = ToggleImportFrame

function CreateMainWindowFrame()
    local mainWidth = 400
    local mainHeight = 400

    local mainFrame = CreateFrame("Frame", "ChosenLadderFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetSize(mainWidth, mainHeight)
    mainFrame:SetMovable(false)
    UI.mainFrame = mainFrame
    _G["ChosenLadderFrame"] = mainFrame
    tinsert(UISpecialFrames, mainFrame:GetName())

    -- Title Text
    local title = mainFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    title:SetPoint("TOPLEFT", 5, -5)
    title:SetText("Chosen Ladder")

    -- Import Button
    local importButton = CreateFrame("Button", "ChosenLadderImportButton", mainFrame, "UIPanelButtonTemplate")
    importButton:SetWidth(96)
    importButton:SetPoint("TOPRIGHT", mainFrame, -24, 0)
    importButton:SetText("Import Players")
    importButton:SetScript("OnClick", function(self, button, down)
        ToggleMainWindowFrame()
        ToggleImportFrame()
    end)

    -- Select All Button
    local selectAllButton = CreateFrame("Button", "ChosenLadderSelectAllButton", mainFrame, "UIPanelButtonTemplate")
    selectAllButton:SetWidth(96)
    selectAllButton:SetPoint("TOPRIGHT", importButton, -importButton:GetWidth(), 0)
    selectAllButton:SetText(toggleAll and "Uncheck All" or "Check All")
    selectAllButton:SetScript("OnClick", function(self, button, down)
        toggleAll = not toggleAll
        for k, v in pairs(D.players) do
            if _G[UIPrefixes.CheckButton .. v.name] ~= nil then
                _G[UIPrefixes.CheckButton .. v.name]:Click()
            end
        end
        self:SetText(toggleAll and "Uncheck All" or "Check All")
    end)

    -- Content Window
    local contentFrame = CreateFrame("Frame", "ChosenLadderContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, 6, -24)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -5, 3)

    local scrollFrame = CreateFrame("ScrollFrame", "ChosenLadderScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, 3, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, -27, 4)
    scrollFrame:EnableMouse(true)

    contentFrame.scroll = scrollFrame
    contentFrame.scrollbar = ChosenLadderScrollFrameScrollBar

    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)

    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(scrollFrame:GetHeight())
    scrollChild:SetScript("OnShow", function(self)
        PopulatePlayerList(self)
    end)

    PopulatePlayerList(scrollChild)
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
