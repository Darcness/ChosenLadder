local A, NS = ...

local D = NS.Data
local UI = NS.UI
local F = NS.Functions

UI.Ladder = {}
local Ladder = UI.Ladder
local UIC = UI.Constants

local function RaidDrop_Initialize_Builder(id)
    return function(frame, level, menuList)
        -- Clear any selections
        UIDropDownMenu_SetSelectedValue(frame, nil, nil)
        UIDropDownMenu_SetText(frame, "")

        local clear = UIDropDownMenu_CreateInfo()
        clear.value = "0"
        clear.text = "Clear Selection"
        clear.func = function(b)
            UIDropDownMenu_SetSelectedValue(frame, "0", "0")
            UIDropDownMenu_SetText(frame, "Clear Selection")
            b.checked = true
            D.SetPlayerGUIDByID(id, "0")
        end

        UIDropDownMenu_AddButton(clear, level)

        local sortedRoster = {}
        for k, v in pairs(D.raidRoster) do
            if k ~= nil and v ~= nil then
                table.insert(sortedRoster, v)
            end
        end

        table.sort(sortedRoster, function(a, b) return a[1] < b[1] end)

        for _, raider in ipairs(sortedRoster) do
            local name = raider[1]
            local guid = UnitGUID(name)
            if guid ~= nil then
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

local function CreatePlayerRowItem(parentScrollFrame, player, idx)
    -- Create a container frame
    local row = CreateFrame("Frame", UI.UIPrefixes.PlayerRow .. player.id, parentScrollFrame, "BackdropTemplate")
    row:SetSize(parentScrollFrame:GetWidth(), 28)
    row:SetPoint("TOPLEFT", parentScrollFrame, 0, (idx - 1) * -28)

    local raidDrop = CreateFrame("Frame", UI.UIPrefixes.RaidMemberDropDown .. player.id, row, "UIDropDownMenuTemplate")
    raidDrop:SetPoint("TOPLEFT", row, 0, 0)
    UIDropDownMenu_SetWidth(raidDrop, 100)
    UIDropDownMenu_Initialize(raidDrop, RaidDrop_Initialize_Builder(player.id))
    -- raidDrop:SetEnabled(D.isLootMaster or false)

    -- Set the Font
    local textFont = row:CreateFontString(UI.UIPrefixes.PlayerNameString .. player.id, nil, "GameFontNormal")
    textFont:SetText(idx .. " - " .. player.name)
    textFont:SetPoint("TOPLEFT", raidDrop, raidDrop:GetWidth() + 4, -8)

    -- Dunk Button
    local dunkButton = CreateFrame("Button", UI.UIPrefixes.PlayerDunkButton .. player.id, row, "UIPanelButtonTemplate")
    dunkButton:SetText("Dunk")
    dunkButton:SetWidth(64)
    dunkButton:SetPoint("TOPRIGHT", row, -2, -2)
    dunkButton:SetScript(
        "OnClick",
        function(self, button, down)
            D.Dunk:CompleteAnnounce(player.id)
            D.Dunk:CompleteProcess(player.id, D.Dunk.dunkItem)
            Ladder:PopulatePlayerList()
        end
    )

    return row
end

function FormatNames()
    local names = ""
    for k, v in pairs(ChosenLadderLootLadder.players) do
        names = names .. string.format("%s:%s:%s", v.id, v.name, (v.guid or "")) .. "\n"
    end
    return names
end

function Ladder:PopulatePlayerList()
    -- If there's no scrollChild yet, we have nothing to populate.
    if UI.scrollChild == nil then
        return
    end

    local children = { UI.scrollChild:GetChildren() }
    for _, child in ipairs(children) do
        -- We want to hide the old ones, so they're not on mangling the new ones.
        child:Hide()
    end

    for playerIdx, player in ipairs(ChosenLadderLootLadder.players) do
        -- Store the player row, since we can't count on the WoW client to garbage collect
        if _G[UI.UIPrefixes.PlayerRow .. player.id] == nil then
            _G[UI.UIPrefixes.PlayerRow .. player.id] = CreatePlayerRowItem(UI.scrollChild, player, playerIdx)
        end

        -- Grab the stored player row and visually reorder it.
        local playerRow = _G[UI.UIPrefixes.PlayerRow .. player.id]
        playerRow:SetPoint("TOPLEFT", UI.scrollChild, 0, (playerIdx - 1) * -28)
        -- Show them, in case they existed before and we hid them.
        playerRow:Show()

        -- Set up DunkButton values
        local dunkButton = _G[UI.UIPrefixes.PlayerDunkButton .. player.id]
        local isDunking = false
        for _, dunker in ipairs(D.Dunk.dunks) do
            if dunker.player.id == player.id then
                isDunking = true
                break
            end
        end
        dunkButton:SetEnabled(D.isLootMaster and isDunking)

        -- Fix the ordering
        local text = _G[UI.UIPrefixes.PlayerNameString .. player.id]
        text:SetText(playerIdx .. " - " .. player.name)

        local raidDrop = _G[UI.UIPrefixes.RaidMemberDropDown .. player.id]
        UIDropDownMenu_Initialize(raidDrop, RaidDrop_Initialize_Builder(player.id))
    end
end

local function CreateImportFrame()
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

            Ladder:ToggleImportFrame()
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

function Ladder:ToggleImportFrame()
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

function Ladder:CreateMainFrame(mainFrame)
    local actionFrame = CreateFrame("Frame", "ChosenLadderActionContentFrame", mainFrame, "BackdropTemplate")
    actionFrame:SetPoint("TOPLEFT", mainFrame, UIC.FrameInset.left, -UIC.FrameInset.top)
    actionFrame:SetPoint("BOTTOMRIGHT", mainFrame, -UIC.LeftFrame.width, UIC.FrameInset.bottom)

    -- Import Button
    local importButton = CreateFrame("Button", "ChosenLadderImportButton", actionFrame, "UIPanelButtonTemplate")
    importButton:SetWidth(UIC.actionButtonWidth)
    importButton:SetPoint("TOPLEFT", actionFrame, 6, -6)
    importButton:SetText("Import/Export")
    importButton:SetScript(
        "OnClick",
        function(self, button, down)
            UI.ToggleMainWindowFrame()
            Ladder:ToggleImportFrame()
        end
    )

    -- Sync Button
    local syncButton = CreateFrame("Button", "ChosenLadderSyncButton", actionFrame, "UIPanelButtonTemplate")
    syncButton:SetWidth(UIC.actionButtonWidth)
    syncButton:SetPoint("TOPLEFT", importButton, 0, -(importButton:GetHeight() + 2))
    syncButton:SetText("Sync")
    syncButton:SetEnabled(D.isLootMaster or false)
    syncButton:SetScript(
        "OnClick",
        function(self, button, down)
            D.GenerateSyncData(false)
            ChosenLadder:PrintToWindow("Submitting Sync Request")
        end
    )
    UI.syncButton = syncButton

    -- Content Window
    local contentFrame = CreateFrame("Frame", "ChosenLadderScrollContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, UIC.LeftFrame.width, -UIC.FrameInset.top)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -UIC.FrameInset.right, UIC.FrameInset.bottom)

    local scrollFrame = CreateFrame("ScrollFrame", "ChosenLadderScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
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
    scrollChild:SetScript("OnShow", function(self) Ladder:PopulatePlayerList() end)

    self:PopulatePlayerList()
end
