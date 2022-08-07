---@diagnostic disable: param-type-mismatch
local A, NS = ...

---@type Data
local D = NS.Data
---@type UI
local UI = NS.UI
---@type Functions
local F = NS.Functions

---@class Ladder
local Ladder = {}
UI.Ladder = Ladder

local UIC = UI.Constants

local function RaidDrop_Initialize_Builder(id)
    return function(frame, level, menuList)
        -- Clear any selections
        UIDropDownMenu_SetSelectedValue(frame, nil, nil)
        UIDropDownMenu_SetText(frame, "")

        ---@type RaidRosterInfo[]
        local sortedRoster = {}
        for k, v in pairs(D:GetRaidRoster()) do
            if k ~= nil and v ~= nil then
                table.insert(sortedRoster, v)
            end
        end

        table.sort(sortedRoster, function(a, b) return a.name < b.name end)

        -- Preselect the 'current' player if they exist.
        local player, _ = D:GetPlayerByID(id)
        if player ~= nil then
            local myGuid = player:CurrentGuid()
            if myGuid ~= nil then
                local raidPlayer, _ = F.Find(sortedRoster,
                    ---@param a RaidRosterInfo
                    function(a) return F.ShortenPlayerGuid(UnitGUID(Ambiguate(a.name, "all"))) == myGuid end)

                if raidPlayer ~= nil then
                    local myInfo = UIDropDownMenu_CreateInfo()

                    myInfo.value = myGuid
                    myInfo.text = raidPlayer.name
                    myInfo.func = function(b)
                        UIDropDownMenu_SetSelectedValue(frame, myGuid, myGuid)
                        UIDropDownMenu_SetText(frame, raidPlayer.name)
                        b.checked = true
                    end

                    UIDropDownMenu_AddButton(myInfo, level)

                    UIDropDownMenu_SetSelectedValue(frame, myGuid, myGuid)
                    UIDropDownMenu_SetText(frame, raidPlayer.name)
                end
            end
        end

        for _, raider in ipairs(sortedRoster) do
            --- Add other raid members
            local name = raider.name
            local guid = UnitGUID(name)

            if guid ~= nil and select(1, D:GetPlayerByGUID(guid)) == nil and raider.online then
                local guid = F.ShortenPlayerGuid(guid)

                local info = UIDropDownMenu_CreateInfo()
                info.value = guid
                info.text = name
                info.func = function(b)
                    UIDropDownMenu_SetSelectedValue(frame, guid, guid)
                    UIDropDownMenu_SetText(frame, name)
                    b.checked = true
                    D:SetPlayerGUIDByID(id, guid)
                end

                UIDropDownMenu_AddButton(info, level)
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
            D.Dunk:Complete(player.id)
            Ladder:PopulatePlayerList()
        end
    )

    return row
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

    for playerIdx, player in ipairs(ChosenLadder:GetLadderPlayers()) do
        -- Store the player row, since we can't count on the WoW client to garbage collect
        if _G[UI.UIPrefixes.PlayerRow .. player.id] == nil then
            _G[UI.UIPrefixes.PlayerRow .. player.id] = CreatePlayerRowItem(UI.scrollChild, player, playerIdx)
        end

        -- Grab the stored player row and visually reorder it.
        local playerRow = _G[UI.UIPrefixes.PlayerRow .. player.id]
        playerRow:SetPoint("TOPLEFT", UI.scrollChild, 0, (playerIdx - 1) * -28)
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
        ChosenLadder_wait(1, UIDropDownMenu_Initialize, raidDrop, RaidDrop_Initialize_Builder(player.id))
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
            UI:ToggleMainWindowFrame()
        end
    )
    ---@diagnostic disable-next-line: assign-type-mismatch
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
            local text = _G["ChosenLadderImportEditBox"]:GetText()
            local lines = {}
            for line in text:gmatch("([^\n]*)\n?") do
                if string.len(line) > 0 then
                    table.insert(lines, F.Trim(line))
                end
            end
            D:BuildPlayerList(lines)

            Ladder:ToggleImportFrame()
        end
    )
    ---@diagnostic disable-next-line: assign-type-mismatch
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
    contentFrame.scrollbar = _G["ChosenLadderImportScrollFrameScrollBar"]

    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local editBox = CreateFrame("EditBox", "ChosenLadderImportEditBox", scrollFrame)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(true)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetHeight(scrollFrame:GetHeight())
    editBox:SetText(D:FormatNames())
    editBox:SetScript(
        "OnShow",
        function(self)
            self:SetText(D:FormatNames())
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

---@param mainFrame Frame
function Ladder:CreateMainFrame(mainFrame)
    local actionFrame = CreateFrame("Frame", "ChosenLadderActionContentFrame", mainFrame, "BackdropTemplate")
    actionFrame:SetPoint("TOPLEFT", mainFrame, UIC.FrameInset.left, -UIC.FrameInset.top)
    actionFrame:SetPoint("BOTTOMRIGHT", mainFrame, -UIC.LeftFrame.width, UIC.FrameInset.bottom)

    -- Import Button
    local importButton = CreateFrame("Button", "ChosenLadderImportButton", actionFrame, "UIPanelButtonTemplate")
    importButton:SetWidth(UIC.actionButtonWidth)
    importButton:SetPoint("TOPLEFT", actionFrame, 6, -6)
    importButton:SetText("Backup/Restore")
    importButton:SetScript(
        "OnClick",
        function(self, button, down)
            UI:ToggleMainWindowFrame()
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
    ---@diagnostic disable-next-line: assign-type-mismatch
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
    ---@diagnostic disable-next-line: undefined-global
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
