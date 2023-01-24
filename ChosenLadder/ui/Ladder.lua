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

        ---@type RaidMember[]
        local sortedRoster = {}
        for k, v in pairs(D:GetRaidRoster().members) do
            if k ~= nil and v ~= nil then
                table.insert(sortedRoster, v)
            end
        end

        table.sort(sortedRoster, function(a, b) return a.name < b.name end)

        -- Preselect the 'current' player if they exist.
        local player, _ = ChosenLadder:GetLadder():GetPlayerByID(id)
        if player ~= nil then
            local myGuid = player:CurrentGuid()
            if myGuid ~= nil then
                local raidPlayer = D:GetRaidRoster().members[myGuid]

                if raidPlayer ~= nil then
                    local myInfo = UIDropDownMenu_CreateInfo()

                    myInfo.value = myGuid
                    myInfo.text = raidPlayer.name
                    myInfo.func = function(self, arg1, arg2, checked)
                        UIDropDownMenu_SetSelectedValue(frame, myGuid, myGuid)
                        UIDropDownMenu_SetText(frame, raidPlayer.name)
                        self.checked = true
                        player:AddGuid(myGuid)
                        player:SetCurrentGuid(myGuid)
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

            if guid ~= nil and select(1, ChosenLadder:GetLadder():GetPlayerByGUID(guid)) == nil and raider.online then
                local guid = F.ShortenPlayerGuid(guid)

                local info = UIDropDownMenu_CreateInfo()
                info.value = guid
                info.text = name
                info.func = function(b)
                    UIDropDownMenu_SetSelectedValue(frame, guid, guid)
                    UIDropDownMenu_SetText(frame, name)
                    b.checked = true
                    ChosenLadder:GetLadder():SetPlayerGUIDByID(id, guid)
                end

                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end

---@param row BackdropTemplate|Frame
---@param player LadderPlayer
---@return Button
local function CreateDunkButton(row, player)
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

    ---@diagnostic disable-next-line: return-type-mismatch
    return dunkButton
end

---@param row BackdropTemplate|Frame
---@param player LadderPlayer
---@param dunkButton Button
---@return Button
local function CreateClearAltsButton(row, player, dunkButton)
    local buttonName = UI.UIPrefixes.PlayerClearAltsButton .. player.id
    local clearButton = _G[buttonName] or CreateFrame("Button", buttonName, row, "UIPanelButtonTemplate")
    clearButton:SetText("Clear Alts")
    clearButton:SetWidth(96);
    clearButton:SetPoint("TOPRIGHT", dunkButton, -(dunkButton:GetWidth() + 4), 0)
    clearButton:SetScript("OnClick", function()
        player:ClearGuids()
        ChosenLadder:PrintToWindow("Clearing Alts for " .. player.name)
        Ladder:PopulatePlayerList()
    end)

    if D:IsLootMaster() then
        clearButton:SetEnabled(true)
    else
        clearButton:SetEnabled(false)
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return clearButton
end

---@param parentScrollFrame Frame
---@param player LadderPlayer
---@param idx number
---@return BackdropTemplate|Frame
local function CreatePlayerRowItem(parentScrollFrame, player, idx)
    -- Create a container frame
    local row = CreateFrame("Frame", UI.UIPrefixes.PlayerRow .. player.id, parentScrollFrame, "BackdropTemplate")
    row:SetSize(parentScrollFrame:GetWidth(), 28)
    row:SetPoint("TOPLEFT", parentScrollFrame, 0, (idx - 1) * -28)

    local raidDrop = CreateFrame("Frame", UI.UIPrefixes.RaidMemberDropDown .. player.id, row, "UIDropDownMenuTemplate")
    raidDrop:SetPoint("TOPLEFT", row, 0, 0)
    UIDropDownMenu_SetWidth(raidDrop, 100)
    UIDropDownMenu_Initialize(raidDrop, RaidDrop_Initialize_Builder(player.id))
    if D:IsLootMaster() then
        UIDropDownMenu_EnableDropDown(raidDrop)
    else
        UIDropDownMenu_DisableDropDown(raidDrop)
    end

    local dunkButton = CreateDunkButton(row, player)
    local clearButton = CreateClearAltsButton(row, player, dunkButton)

    -- Set the Font last, since it requires the other elements to be in place first.
    local textFont = row:CreateFontString(UI.UIPrefixes.PlayerNameString .. player.id, nil, "GameFontNormal")
    textFont:SetText(idx .. " - " .. player.name)
    textFont:SetPoint("TOPLEFT", raidDrop, raidDrop:GetWidth() - 4, -8)

    textFont:SetPoint("TOPRIGHT", clearButton, -(clearButton:GetWidth() + 2), 0)
    textFont:SetJustifyH("LEFT")

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

    for playerIdx, player in ipairs(ChosenLadder:GetLadder().players) do
        local playerRow = _G[UI.UIPrefixes.PlayerRow .. player.id] or
            CreatePlayerRowItem(UI.scrollChild, player, playerIdx)
        playerRow:SetPoint("TOPLEFT", UI.scrollChild, 0, (playerIdx - 1) * -28)
        playerRow:Show()

        -- Set up DunkButton values
        local dunkButton = _G[UI.UIPrefixes.PlayerDunkButton .. player.id] or CreateDunkButton(playerRow, player)
        local isDunking = false
        for _, dunker in ipairs(D.Dunk.dunks) do
            if dunker.player.id == player.id then
                isDunking = true
                break
            end
        end
        dunkButton:SetEnabled(D:IsLootMaster() and isDunking)

        local clearButton = _G[UI.UIPrefixes.PlayerClearAltsButton .. player.id] or
            CreateClearAltsButton(playerRow, player, dunkButton)
        clearButton:SetEnabled(D:IsLootMaster())

        -- Fix the ordering
        local text = _G[UI.UIPrefixes.PlayerNameString .. player.id]
        text:SetText(playerIdx .. " - " .. player.name)

        local raidDrop = _G[UI.UIPrefixes.RaidMemberDropDown .. player.id]
        F.Wait(1, UIDropDownMenu_Initialize, raidDrop, RaidDrop_Initialize_Builder(player.id))
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
    saveButton:SetEnabled(D:IsLootMaster())
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
            ChosenLadder:GetLadder():BuildFromPlayerList(lines, D)

            Ladder:PopulatePlayerList()
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
    editBox:SetText(ChosenLadder:GetLadder():FormatNames())
    editBox:SetScript(
        "OnShow",
        function(self)
            self:SetText(ChosenLadder:GetLadder():FormatNames())
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

    -- Refresh button

    local refreshButtonName = "ChosenLadderRefreshLadderButton"
    local refreshButton = _G[refreshButtonName] or
        CreateFrame("Button", refreshButtonName, actionFrame, "UIPanelButtonTemplate")
    refreshButton:SetWidth(UIC.actionButtonWidth)
    refreshButton:SetPoint("TOPLEFT", importButton, 0, -(importButton:GetHeight() + 2))
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function(self, button, down)
        ChosenLadder:SendMessage(D.Constants.RequestSyncFlag, "RAID", true)
    end)

    -- Push Button
    local syncButton = CreateFrame("Button", "ChosenLadderSyncButton", actionFrame, "UIPanelButtonTemplate")
    syncButton:SetWidth(UIC.actionButtonWidth)
    syncButton:SetPoint("TOPLEFT", refreshButton, 0, -(refreshButton:GetHeight() + 2))
    syncButton:SetText("Push")
    syncButton:SetEnabled(D:IsLootMaster())
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
