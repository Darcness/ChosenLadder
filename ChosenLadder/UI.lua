local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

local UIPrefixes = {
    PlayerRow = "ChosenLadderPlayerRow",
    DunkButton = "ChosenLadderDunkButton",
    PlayerNameString = "ChosenLadderTextString",
    RaidMemberDropDown = "ChosenLadderRaidMemberDropDown"
}

function RaidDrop_Initialize_Builder(id)
    return function(frame, level, menuList)
        -- Clear any selections
        UIDropDownMenu_SetSelectedValue(frame, nil, nil)
        UIDropDownMenu_SetText(frame, "")

        for _, raider in ipairs(D.raidRoster) do
            local name = raider[1]
            local guid = UnitGUID(name)
            if guid == nil then
                -- Something went wrong?
                ChosenLadder:Print("Invalid Guid for raid member - " .. name)
            else
                local guid = D.ShortenGuid(guid)

                local info = UIDropDownMenu_CreateInfo()
                info.value = guid
                info.text = name
                info.func = function(b)
                    UIDropDownMenu_SetSelectedValue(frame, guid, guid)
                    UIDropDownMenu_SetText(frame, name)
                    b.checked = true
                    D.SetPlayerGUIDByID(id, guid)
                end

                UIDropDownMenu_AddButton(info, level)

                local player = D.GetPlayerByGUID(guid)
                if player ~= nil and player.id == id then
                    -- This id (player row) has the guid for this raid member.  Select them.
                    UIDropDownMenu_SetSelectedValue(frame, guid, guid)
                    UIDropDownMenu_SetText(frame, name)
                    D.SetPresentById(id, true)
                end
            end
        end
    end
end

function CreatePlayerRowItem(parentScrollFrame, player, idx)
    -- Create a container frame
    local row = CreateFrame("Frame", UIPrefixes.PlayerRow .. player.id, parentScrollFrame, "BackdropTemplate")
    row:SetSize(parentScrollFrame:GetWidth(), 28)
    row:SetPoint("TOPLEFT", parentScrollFrame, 0, (idx - 1) * -28)

    local raidDrop = CreateFrame("Frame", UIPrefixes.RaidMemberDropDown .. player.id, row, "UIDropDownMenuTemplate")
    raidDrop:SetPoint("TOPLEFT", row, 0, 0)
    UIDropDownMenu_SetWidth(raidDrop, 100)
    UIDropDownMenu_Initialize(raidDrop, RaidDrop_Initialize_Builder(player.id))
    -- raidDrop:SetEnabled(D.isLootMaster or false)

    -- Set the Font
    local textFont = row:CreateFontString(UIPrefixes.PlayerNameString .. player.id, nil, "GameFontNormal")
    textFont:SetText(idx .. " - " .. player.name)
    textFont:SetPoint("TOPLEFT", raidDrop, raidDrop:GetWidth() + 4, -8)

    -- Dunk Button
    local dunkButton = CreateFrame("Button", UIPrefixes.DunkButton .. player.id, row, "UIPanelButtonTemplate")
    dunkButton:SetText("Dunk")
    dunkButton:SetWidth(64)
    dunkButton:SetPoint("TOPRIGHT", row, -2, -2)
    dunkButton:SetScript(
        "OnClick",
        function(self, button, down)
            D.CompleteDunk(player.id)
            PopulatePlayerList()
        end
    )

    return row
end

function PopulatePlayerList()
    -- If there's no mainFrame yet, we have nothing to populate.
    if UI.mainFrame ~= nil and UI.scrollChild ~= nil then
        local children = { UI.scrollChild:GetChildren() }
        for _, child in ipairs(children) do
            -- We want to hide the old ones, so they're not on mangling the new ones.
            child:Hide()
        end

        for playerIdx, player in ipairs(LootLadder.players) do
            -- Store the player row, since we can't count on the WoW client to garbage collect
            if _G[UIPrefixes.PlayerRow .. player.id] == nil then
                _G[UIPrefixes.PlayerRow .. player.id] = CreatePlayerRowItem(UI.scrollChild, player, playerIdx)
            end

            -- Grab the stored player row and visually reorder it.
            local playerRow = _G[UIPrefixes.PlayerRow .. player.id]
            playerRow:SetPoint("TOPLEFT", UI.scrollChild, 0, (playerIdx - 1) * -28)
            -- Show them, in case they existed before and we hid them.
            playerRow:Show()

            -- Set up DunkButton values
            local dunkButton = _G[UIPrefixes.DunkButton .. player.id]
            local isDunking = false
            for _, dunker in ipairs(D.dunks) do
                if dunker.player.id == player.id then
                    isDunking = true
                    break
                end
            end
            dunkButton:SetEnabled(D.isLootMaster and isDunking)

            -- Fix the ordering
            local text = _G[UIPrefixes.PlayerNameString .. player.id]
            text:SetText(playerIdx .. " - " .. player.name)

            local raidDrop = _G[UIPrefixes.RaidMemberDropDown .. player.id]
            UIDropDownMenu_Initialize(raidDrop, RaidDrop_Initialize_Builder(player.id))
        end
    end
end

UI.PopulatePlayerList = PopulatePlayerList

function FormatNames()
    local names = ""
    for k, v in pairs(LootLadder.players) do
        names = names .. string.format("%s:%s:%s", v.id, v.name, (v.guid or "")) .. "\n"
    end
    return names
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
    title:SetText("Import Player Data (one per line)")

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
    editBox:SetText(FormatNames())
    editBox:SetScript(
        "OnShow",
        function(self)
            self:SetText(FormatNames())
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

    -- Sync Button
    local syncButton = CreateFrame("Button", "ChosenLadderSyncButton", contentFrame, "UIPanelButtonTemplate")
    syncButton:SetWidth(actionButtonWidth)
    syncButton:SetPoint("TOPLEFT", importButton, 0, -(importButton:GetHeight() + 2))
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

    -- Create the scrolling child frame, set its width to fit
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

    if UI.importSaveButton ~= nil then
        UI.importSaveButton:SetEnabled(D.isLootMaster or false)
    end

    PopulatePlayerList()
end

UI.UpdateElementsByPermission = UpdateElementsByPermission
