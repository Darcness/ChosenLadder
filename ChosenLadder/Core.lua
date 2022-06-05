local CL, NS = ...
   
local UI = NS.UI

SLASH_LADDER1 = "/ladder"
function SlashCmdList.LADDER(msg, editBox)
    -- If someone is trying to run this command with the import open, then we close it.
    if UI.importFrame ~= nil and UI.importFrame:IsShown() then
        UI.importFrame:Hide()
    end

    UI.ToggleMainWindowFrame()
end
