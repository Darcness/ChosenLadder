local A, NS = ...

-- UI Container
NS.UI = {}
-- Functions Container
NS.Functions = {}
-- Data Container
NS.Data = {}
NS.Data.Constants = {}
NS.Data.Constants.BeginSyncFlag = "BEGIN SYNC:"
NS.Data.Constants.EndSyncFlag = "END SYNC"
NS.Data.Constants.PlayerSyncFlag = "PlayerPos:"

function Trim(s)
    return s:match '^%s*(.*%S)' or ''
end

NS.Functions.Trim = Trim

function StartsWith(str, start)
    return str:sub(1, #start) == start
end

NS.Functions.StartsWith = StartsWith


function ChosenLadder_OnLoad(self)
    self:RegisterEvent("ADDON_LOADED")
end

function ChosenLadder_OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == A then
        self:UnregisterEvent("ADDON_LOADED")
        C_ChatInfo.RegisterAddonMessagePrefix(A)
        print("Registered Chat Listener - " .. A)
    elseif event == "CHAT_MSG_ADDON_LOGGED" then
        print("CHAT MSG - " .. ...)
        local msgText = arg[1]
        local msgChannel = arg[2]
        local msgSender = arg[3]
        local msgTarget = arg[4]

        if msgChannel == "RAID" then
            print(msgText)
            local beginSyncFlag = NS.Data.Constants.BeginSyncFlag
            if StartsWith(msgText, beginSyncFlag) then
                local timestampStr = msgText:gsub(beginSyncFlag, "")
                local timestamp = tonumber(timestampStr)
                if timestamp > NS.Data.lastModified then
                    -- Begin Sync
                    NS.Data.syncing = true
                    NS.Data.syncingPlayers = {}
                end
            end

            local endSyncFlag = NS.Data.Constants.EndSyncFlag
            if msgText == endSyncFlag then
                NS.Data.syncing = false
                NS.Data.BuildPlayerList(NS.Data.syncingPlayers)
                print("Syncing List!")
            end

            if StartsWith(msgText, NS.Data.Constants.PlayerSyncFlag) then
                local playerPlace = msgText:gsub(NS.Data.Constants.PlayerSyncFlag, "")
                local i, j = string.find(playerPlace, " - ")
                local playerPosStr = string.sub(playerPlace, i, j)
                local playerPos = tonumber(playerPosStr)

                local playerName = string.sub(playerPlace, j + 1)

                NS.Data.syncingPlayers[playerPos] = playerName
            end
        end
    end
end
