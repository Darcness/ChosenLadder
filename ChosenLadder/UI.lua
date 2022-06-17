local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

local toggleAll = false

local UIPrefixes = {
    PlayerRow = "ChosenLadderPlayerRow",
    CheckButton = "ChosenLadderCheckButton",
    DunkButton = "ChosenLadderDunkButton",
    PlayerNameString = "ChosenLadderPlayerNameString",
    RaidMemberDropDown = "ChosenLadderRaidMemberDropDown"
}

function RaidDrop_Initialize_Builder(rowName)
    return function(frame, level, menuList)
        local currentValue = UIDropDownMenu_GetSelectedValue(frame)
        local found = false
        for k, v in ipairs(D.raidRoster) do
            local name = v[1]
            local guid = UnitGUID(name)
            -- Is this our selected user?
            if guid == currentValue then
                found = true
            end

            local info = UIDropDownMenu_CreateInfo()
            info.value = guid
            info.text = name

            info.func = function(b)
                UIDropDownMenu_SetSelectedValue(frame, guid, guid)
                UIDropDownMenu_SetText(frame, name)
                b.checked = true
                D.SetPlayerGUIDByPosition(rowName, guid)
            end
            UIDropDownMenu_AddButton(info, level)
        end

        -- If our selected user isn't found, we blank the dropdown
        if not found then
            UIDropDownMenu_SetSelectedValue(frame, nil, nil)
            UIDropDownMenu_SetText(frame, "")
        end
    end
end

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
    local textFont = cb:CreateFontString(UIPrefixes.PlayerNameString .. text, nil, "GameFontNormal")
    textFont:SetText(idx .. " - " .. text)
    textFont:SetPoint("TOPLEFT", cb, cb:GetWidth() + 4, -8)
    cb:SetFontString(textFont)

    -- Any other properties
    cb:SetChecked(checked)

    -- Dunk Button
    local dunkButton = CreateFrame("Button", UIPrefixes.DunkButton .. text, row, "UIPanelButtonTemplate")
    dunkButton:SetText("Dunk")
    dunkButton:SetWidth(64)
    dunkButton:SetPoint("TOPRIGHT", row, -2, -2)
    dunkButton:SetScript(
        "OnClick",
        function(self, button, down)
            D.RunDunk(text)
            PopulatePlayerList()
        end
    )

    local raidDrop = CreateFrame("Frame", UIPrefixes.RaidMemberDropDown .. text, row, "UIDropDownMenuTemplate")
    raidDrop:SetPoint("TOPRIGHT", dunkButton, -(dunkButton:GetWidth() - 12), 2)
    UIDropDownMenu_SetWidth(raidDrop, 100)
    UIDropDownMenu_Initialize(raidDrop, RaidDrop_Initialize_Builder(text))

    dunkButton:SetEnabled(cb:GetChecked())
    cb:SetScript(
        "OnClick",
        function(self, button, down)
            D.TogglePresent(text)
            dunkButton:SetEnabled(self:GetChecked())
        end
    )

    return row
end

function GetMaxNameSize()
    local maxNameSize = 0
    for _, v in ipairs(LootLadder.players) do
        maxNameSize = math.max(maxNameSize, string.len(v.name) + 4) -- Add in "## -" where ## is their list spot.
    end

    return maxNameSize
end

function PopulatePlayerList()
    -- If there's no mainFrame yet, we have nothing to populate.
    if UI.mainFrame ~= nil then
        -- We get this here so we're not re-calculating it for every row.
        local maxNameSize = GetMaxNameSize()

        local children = { UI.scrollChild:GetChildren() }
        for i, child in ipairs(children) do
            -- We want to hide the old ones, so they're not on mangling the new ones.
            child:Hide()
        end

        for k, v in ipairs(LootLadder.players) do
            -- Store the player row, since we can't count on the WoW client to garbage collect
            if _G[UIPrefixes.PlayerRow .. v.name] == nil then
                _G[UIPrefixes.PlayerRow .. v.name] = CreatePlayerRowItem(UI.scrollChild, v.name, v.present, k,
                    maxNameSize)
            end

            -- Grab the stored player row and visually reorder it.
            local playerRow = _G[UIPrefixes.PlayerRow .. v.name]
            playerRow:SetPoint("TOPLEFT", UI.scrollChild, 0, (k - 1) * -28)
            -- Show them, in case they existed before and we hid them.
            playerRow:Show()

            -- Set up CheckButton values
            local cb = _G[UIPrefixes.CheckButton .. v.name]
            cb:SetChecked(v.present)
            cb:SetEnabled(D.isLootMaster)

            -- Set up DunkButton values
            local dunkButton = _G[UIPrefixes.DunkButton .. v.name]
            dunkButton:SetEnabled(D.isLootMaster and cb:GetChecked())

            -- Fix the ordering
            local text = _G[UIPrefixes.PlayerNameString .. v.name]
            text:SetText(k .. " - " .. v.name)

            local raidDrop = _G[UIPrefixes.RaidMemberDropDown .. v.name]
            UIDropDownMenu_Initialize(raidDrop, RaidDrop_Initialize_Builder(v.name))
        end
    end
end

UI.PopulatePlayerList = PopulatePlayerList

function PopulateNames(editBox)
    local names = ""
    for k, v in pairs(LootLadder.players) do
        names = names .. v.name .. "\n"
    end
    editBox:SetText(names)
end

function CreateImportFrame()
    local mainFrame = CreateFrame("Frame", "ChosenLadderImportFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetSize(400, 400)
    mainFrame:SetMovable(false)
    mainFrame:SetScript(
        "OnHide",
        function(self)
            ToggleMainWindowFrame()
        end
    )
    UI.importFrame = mainFrame
    _G["ChosenLadderImportFrame"] = mainFrame

    -- Title Text
    local title = mainFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    title:SetPoint("TOPLEFT", 5, -5)
    title:SetText("Import Names (one per line)")

    -- Import Button
    local saveButton = CreateFrame("Button", "ChosenLadderSaveButton", mainFrame, "UIPanelButtonTemplate")
    saveButton:SetWidth(64)
    saveButton:SetPoint("TOPRIGHT", mainFrame, -24, 0)
    saveButton:SetText("Save")
    saveButton:SetEnabled(D.isLootMaster or false)
    saveButton:SetScript(
        "OnClick",
        function(self, button, down)
            local text = ChosenLadderImportEditBox:GetText()
            local lines = {}
            for line in text:gmatch("([^\n]*)\n?") do
                if string.len(line) > 0 then
                    table.insert(lines, F.Trim(line))
                end
            end
            D.BuildPlayerList(lines)

            ToggleImportFrame()
        end
    )
    UI.importSaveButton = saveButton

    -- Content Window
    local contentFrame = CreateFrame("Frame", "ChosenLadderImportContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, 6, -24)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -5, 3)

    local scrollFrame =
    CreateFrame("ScrollFrame", "ChosenLadderImportScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
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
    PopulateNames(editBox)
    editBox:SetScript(
        "OnShow",
        function(self)
            PopulateNames(self)
        end
    )
    scrollFrame:SetScrollChild(editBox)

    mainFrame:SetFrameLevel(9000)
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

function CreateMainActionsFrame(mainFrame)
    local actionButtonWidth = 102
    local contentFrame = CreateFrame("Frame", "ChosenLadderActionContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, 6, -24)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -122, 3)

    -- Import Button
    local importButton = CreateFrame("Button", "ChosenLadderImportButton", contentFrame, "UIPanelButtonTemplate")
    importButton:SetWidth(actionButtonWidth)
    importButton:SetPoint("TOPLEFT", contentFrame, 6, -6)
    importButton:SetText("Import/Export")
    importButton:SetScript(
        "OnClick",
        function(self, button, down)
            ToggleMainWindowFrame()
            ToggleImportFrame()
        end
    )

    -- Select All Button
    local selectAllButton = CreateFrame("Button", "ChosenLadderSelectAllButton", contentFrame, "UIPanelButtonTemplate")
    selectAllButton:SetWidth(actionButtonWidth)
    selectAllButton:SetPoint("TOPLEFT", importButton, 0, -(importButton:GetHeight() + 2))
    selectAllButton:SetText(toggleAll and "Uncheck All" or "Check All")
    selectAllButton:SetEnabled(D.isLootMaster or false)
    selectAllButton:SetScript(
        "OnClick",
        function(self, button, down)
            toggleAll = not toggleAll
            for k, v in pairs(LootLadder.players) do
                if _G[UIPrefixes.CheckButton .. v.name] ~= nil then
                    _G[UIPrefixes.CheckButton .. v.name]:Click()
                end
            end
            self:SetText(toggleAll and "Uncheck All" or "Check All")
        end
    )
    UI.selectAllButton = selectAllButton

    -- Sync Button
    local syncButton = CreateFrame("Button", "ChosenLadderSyncButton", contentFrame, "UIPanelButtonTemplate")
    syncButton:SetWidth(actionButtonWidth)
    syncButton:SetPoint("TOPLEFT", selectAllButton, 0, -(selectAllButton:GetHeight() + 2))
    syncButton:SetText("Sync")
    syncButton:SetEnabled(D.isLootMaster or false)
    syncButton:SetScript(
        "OnClick",
        function(self, button, down)
            D.GenerateSyncData(false)
            ChosenLadder:Print("Submitting Sync Request")
        end
    )
    UI.syncButton = syncButton
end

function CreateMainPlayerListFrame(mainFrame)
    -- Content Window
    local contentFrame = CreateFrame("Frame", "ChosenLadderScrollContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, 122, -24)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -5, 3)

    local scrollFrame =
    CreateFrame("ScrollFrame", "ChosenLadderScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, 3, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, -27, 4)
    scrollFrame:EnableMouse(true)

    contentFrame.scroll = scrollFrame
    contentFrame.scrollbar = ChosenLadderScrollFrameScrollBar

    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)

    UI.scrollChild = scrollChild
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(scrollFrame:GetHeight())
    scrollChild:SetScript(
        "OnShow",
        function(self)
            PopulatePlayerList()
        end
    )

    PopulatePlayerList()
end

function CreateMainWindowFrame()
    local mainWidth = 550
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

    CreateMainActionsFrame(mainFrame)

    CreateMainPlayerListFrame(mainFrame)

    PopulatePlayerList()
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

    if UI.selectAllButton ~= nil then
        UI.selectAllButton:SetEnabled(D.isLootMaster or false)
    end

    if UI.importSaveButton ~= nil then
        UI.importSaveButton:SetEnabled(D.isLootMaster or false)
    end

    PopulatePlayerList()
end

UI.UpdateElementsByPermission = UpdateElementsByPermission
