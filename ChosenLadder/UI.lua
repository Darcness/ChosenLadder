local CL, NS = ...

local F = NS.F
local UI = NS.UI

local players = {}
for i = 1, 50 do
    table.insert(players, {
        name = "Player " .. i,
        present = false
    })
end

function CreateMainWindowFrame()
    local mainWidth = 600
    local mainHeight = 400

    local mainFrame = CreateFrame("Frame", "LadderFrame", UIParent, "BackdropTemplate,BasicFrameTemplateWithInset")
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetSize(mainWidth, mainHeight)
    mainFrame:SetMovable(false)
    -- mainFrame:SetBackdrop(backdrop)
    UI.mainFrame = mainFrame
    _G["LadderFrame"] = mainFrame
    tinsert(UISpecialFrames, mainFrame:GetName())

    local title = mainFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    title:SetPoint("TOPLEFT", 5, -5)
    title:SetText("Chosen Ladder")

    local contentFrame = CreateFrame("Frame", "LadderContentFrame", mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", mainFrame, 6, -24)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, -5, 3)

    local scrollFrame = CreateFrame("ScrollFrame", "LadderScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, 3, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, -27, 4)
    scrollFrame:EnableMouse(true)

    contentFrame.scroll = scrollFrame
    contentFrame.scrollbar = LadderScrollFrameScrollBar

    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)

    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(scrollFrame:GetHeight())

    local nameLength = 0;
    for k, v in ipairs(players) do
        nameLength = math.max(nameLength, string.len(v.name))
    end

    PopulatePlayerList(scrollChild, nameLength)
end

F.CreateMainWindowFrame = CreateMainWindowFrame

function CreatePlayerRowItem(parentScrollFrame, text, checked, idx, maxNameSize)
    -- Create a container frame
    local row = CreateFrame("Frame", "PlayerRow" .. text, parentScrollFrame, "BackdropTemplate")
    row:SetSize(parentScrollFrame:GetWidth(), 28)
    row:SetPoint("TOPLEFT", parentScrollFrame, 0, (idx - 1) * -28)

    -- Create the CheckButton
    local cb = CreateFrame("CheckButton", "CheckButton" .. text, row, "UICheckButtonTemplate")
    cb:SetSize(28, 28)
    cb:SetPoint("TOPLEFT", row, 0, 0)

    -- Set the Font
    local textFont = cb:CreateFontString("ARTWORK", nil, "GameFontNormal")
    textFont:SetText(text)
    textFont:SetPoint("TOPLEFT", cb, cb:GetWidth() + 4, -8)
    cb:SetFontString(textFont)

    -- Any other properties
    cb:SetChecked(checked)

    local dunkButton = CreateFrame("Button", "DunkButton" .. text, row, "UIPanelButtonTemplate")
    dunkButton:SetText("Dunk")
    dunkButton:SetPoint("TOPLEFT", textFont, (maxNameSize * 8) + 4, 6)
    dunkButton:SetScript("OnClick", function(self, button, down)
        RunDunk(parentScrollFrame, text)
    end)

    return row
end

function PopulatePlayerList(parentScrollFrame, maxNameSize)
    for k, v in ipairs(players) do
        if _G["PlayerRow" .. v.name] == nil then
            _G["PlayerRow" .. v.name] = CreatePlayerRowItem(parentScrollFrame, v.name, v.present, k, maxNameSize)
        end

        local playerRow = _G["PlayerRow" .. v.name]
        playerRow:SetPoint("TOPLEFT", parentScrollFrame, 0, (k - 1) * -28)
    end
end

function RunDunk(parentScrollName, name)
    local newPlayers = {}
    local found
    local maxNameSize = 0
    for _, v in ipairs(players) do
        maxNameSize = math.max(maxNameSize, string.len(v.name))

        if name == v.name then
            found = v
        else
            table.insert(newPlayers, v)
        end
    end

    if found ~= nil then
        table.insert(newPlayers, found)
    end

    players = newPlayers
    PopulatePlayerList(parentScrollName, maxNameSize)
end

function ToggleFrame()
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

F.ToggleFrame = ToggleFrame
