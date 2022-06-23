local CL, NS = ...

local D = NS.Data
local F = NS.Functions

D.raidRoster = {}
D.isLootMaster = false
D.lootMasterItems = {}

function BuildPlayerList(rows)
    LootLadder.players = {}

    for _, v in ipairs(rows) do
        local nameParts = F.Split(v, ":")
        if #nameParts >= 2 then
            table.insert(
                LootLadder.players,
                {
                    id = nameParts[1],
                    name = nameParts[2],
                    guid = nameParts[3],
                    present = false,
                    log = ""
                }
            )
        else
            ChosenLadder:Print("Invalid Import Data: " .. v)
        end
    end

    LootLadder.lastModified = GetServerTime()
end

D.BuildPlayerList = BuildPlayerList

function GenerateSyncData(localDebug)
    local timeMessage = D.Constants.BeginSyncFlag .. LootLadder.lastModified
    local channel = "RAID"

    local fullMessage = timeMessage .. "|"

    for _, player in ipairs(LootLadder.players) do
        fullMessage = fullMessage .. player.name .. "|"
    end

    local endMessage = D.Constants.EndSyncFlag
    fullMessage = fullMessage .. endMessage

    if localDebug then
        print(fullMessage)
    else
        ChosenLadder:SendMessage(fullMessage, channel)
    end
end

D.GenerateSyncData = GenerateSyncData

function IsPlayerInRaid(playername)
    if playername ~= nil then
        for k, v in ipairs(D.raidRoster) do
            if v[1] == Ambiguate(playername, "all") then
                return true
            end
        end
    end

    return false
end

D.IsPlayerInRaid = IsPlayerInRaid

function SetPlayerGUIDByID(id, guid)
    local player = GetPlayerByID(id)
    if player ~= nil then
        player.guid = guid
    else
        ChosenLadder:Print(string.format("Selected Player unable to be found! %s - %s", player, guid))
    end
end

D.SetPlayerGUIDByID = SetPlayerGUIDByID

function ShortenGuid(guid)
    return string.gsub(guid, "Player%-4648%-", "")
end

D.ShortenGuid = ShortenGuid

function GetPlayerByID(id)
    return F.Find(LootLadder.players, function(player) return player.id == id end)
end

D.GetPlayerByID = GetPlayerByID

function GetPlayerByGUID(guid)
    guid = ShortenGuid(guid)
    return F.Find(LootLadder.players, function(player) return player.guid == guid end)
end

D.GetPlayerByGUID = GetPlayerByGUID

function SetPresentById(id, present)
    local player = GetPlayerByID(id)
    if player ~= nil then
        player.present = present
    end
end

D.SetPresentById = SetPresentById

function GetLootItemByGUID(guid)
    return F.Find(D.lootMasterItems, function(item) return item.guid == guid end)
end

D.GetLootItemByGUID = GetLootItemByGUID

function RemoveLootItemByGUID(guid)
    local newItems = {}
    for _, item in pairs(D.lootMasterItems) do
        if item.guid ~= guid then
            table.insert(newItems, item)
        end
    end
    D.lootMasterItems = newItems
end

D.RemoveLootItemByGUID = RemoveLootItemByGUID
