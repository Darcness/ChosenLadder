--[[
  
The stuff in this file is a complete mess.  Dont' use any of it.
None of this is even included in the TOC file, so it doesn't render in the addon.

--]]


-- Don't use this function, for real, it's jacked up.
function MakeCloseButton(name, parentFrame)
    local defaultSize = 32
    local leftFrameSize = 5
    local topFrameSize = 3
    local bottomFrameSize = 4
    local rightFrameSize = 8

    local button = CreateFrame("Button", name, parentFrame, "UIPanelButtonTemplate,BackdropTemplate")
    button:SetSize(28, 28)
    button:SetSize(100, 100)

    local normalTexture = button:CreateTexture(nil, nil)
    normalTexture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    normalTexture:SetTexCoord(leftFrameSize / defaultSize, 1 - (rightFrameSize / defaultSize), topFrameSize / defaultSize, 1 - (bottomFrameSize / defaultSize))
    normalTexture:SetAllPoints(button)
    -- normalTexture:SetPoint("TOPLEFT", button, 0, 0)
    -- normalTexture:SetPoint("BOTTOMRIGHT", button, 0, 0)
    button:SetNormalTexture(normalTexture)

    -- local highlightTexture = button:CreateTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    -- highlightTexture:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    -- button:SetHighlightTexture(highlightTexture)

    local pushedTexture = button:CreateTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    pushedTexture:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    button:SetPushedTexture(pushedTexture)

    button:SetScript("OnClick", function(self, button, down)
        parentFrame:Hide()
    end)

    return button
end
