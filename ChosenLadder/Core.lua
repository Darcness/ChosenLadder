local A, NS = ...

local UI = NS.UI

local StreamFlag = NS.Data.Constants.StreamFlag

function ChosenLadder:OnInitialize()
    print("ChosenLadder Loaded")
end

function ChosenLadder:OnEnable()
    self:RegisterComm(A, ChosenLadder:OnCommReceived())
    self:RegisterChatCommand("ladder", "SlashCommand")
end

function ChosenLadder:OnCommReceived(prefix, message, distribution, sender)
    if not not (prefix == A and distribution == "RAID") then

        local beginSyncFlag = NS.Data.Constants.BeginSyncFlag
        local endSyncFlag = NS.Data.Constants.EndSyncFlag

        if StartsWith(message, beginSyncFlag) then
            local vars = {}
            local players = {}

            -- carve it up
            for str in string.gmatch(message, "([^\\|]+)") do
                table.insert(vars, str)
            end

            local timestampStr = vars[1]:gsub(beginSyncFlag, "")
            local timestamp = tonumber(timestampStr)
            if timestamp > NS.Data.lastModified then
                -- Begin Sync
                NS.Data.syncing = StreamFlag.Started
            end


            if NS.Data.syncing == StreamFlag.Started then
                for k, v in ipairs(vars) do
                    if StartsWith(v, beginSyncFlag) then

                    elseif v == endSyncFlag then
                        NS.Data.syncing = StreamFlag.Complete
                    else
                        table.insert(players, v)
                    end
                end

                if NS.Data.syncing == StreamFlag.Complete then
                    print("Syncing List!")
                    NS.Data.BuildPlayerList(players)
                    UI.PopulatePlayerList()
                    NS.Data.syncing = StreamFlag.Empty
                end
            end
        end
    end
end

function ChosenLadder:SlashCommand(msg)
    -- If someone is trying to run this command with the import open, then we close it.
    if UI.importFrame ~= nil and UI.importFrame:IsShown() then
        UI.importFrame:Hide()
    end

    UI.ToggleMainWindowFrame()
end

function ChosenLadder:SendMessage(message, destination)
    self:SendCommMessage(A, message, destination, nil, "BULK")
end
