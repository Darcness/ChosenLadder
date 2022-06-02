local isOpen = false

function ChosenLadder_OnLoad(self, event, ...)
    self:RegisterEvent("ADDON_LOADED")
end

function ChosenLadder_OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == "ChosenLadder" then
        self:UnregisterEvent("ADDON_LOADED")

    end
end

SLASH_LADDER1 = "/ladder"
function SlashCmdList.LADDER(msg, editBox)
    if isOpen == false then
        isOpen = true
        if (LadderFrame == nil) then
            CreateWindowFrame()
        else
            LadderFrame:Show()
        end
    else
        isOpen = false
        LadderFrame:Hide()
    end
end

function CreateWindowFrame()
    local mainFrame = CreateFrame("Frame", "LadderFrame", UIParent, "BackdropTemplate")
    mainFrame:SetPoint("Center", 0, 0)
    mainFrame:SetSize(600, 400)
    mainFrame:SetMovable(false)

    local backdropInfo =
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }

    local backdrop = {
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
        insets = { left = 4, right = 3, top = 4, bottom = 3 }
    }
    
    mainFrame:SetBackdrop(backdrop)
    mainFrame:SetBackdropColor(0, 0, 0)


    local scrollFrame = CreateFrame("ScrollFrame", "LadderScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, -26, 4)
    scrollFrame:EnableMouse(true)
    
    mainFrame.scroll = scrollFrame
    mainFrame.scrollbar = LadderScrollFrameScrollBar

        
    -- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)

    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)

    -- Add widgets to the scrolling child frame as desired
    local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
    title:SetPoint("TOPLEFT", 0)
    title:SetText("Chosen Ladder")

    local footer = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
    footer:SetPoint("TOPLEFT", 0, -5000)
    footer:SetText("This is 5000 below the top, so the scrollChild automatically expanded.")
end
