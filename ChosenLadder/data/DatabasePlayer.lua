local CL, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

---@class DatabasePlayer
---@field id string
---@field name string
---@field guids string
---@field log string
DatabasePlayer = {
    id = "",
    name = "",
    guids = "",
    log = ""
}

---@param o DatabasePlayer
---@return DatabasePlayer
function DatabasePlayer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return boolean
function DatabasePlayer:IsPresent()
    local guidTable = F.Split(self.guids, "-")
    for _, guid in ipairs(guidTable) do
        ---@param a RaidRosterInfo
        if F.Find(D:GetRaidRoster(), function(a)
            return F.ShortenPlayerGuid(UnitGUID(Ambiguate(a.name, "all"))) == F.ShortenPlayerGuid(guid)
        end) then
            return true
        end
    end

    return false
end

---@return string | nil
function DatabasePlayer:CurrentGuid()
    local guidTable = F.Split(self.guids, "-")
    for _, guid in ipairs(guidTable) do
        for _, rosterInfo in ipairs(D:GetRaidRoster()) do
            local playerGuid = F.ShortenPlayerGuid(UnitGUID(Ambiguate(rosterInfo.name, "all")))
            if playerGuid == F.ShortenPlayerGuid(guid) and UnitIsConnected(Ambiguate(rosterInfo.name, "all")) then
                return playerGuid
            end
        end
    end

    return nil
end

---@param guid string
function DatabasePlayer:AddGuid(guid)
    local guidTable = F.Split(self.guids, "-")
    if not F.Find(guidTable, function(a) return a == guid end) then
        table.insert(guidTable, guid)
        self.guids = table.concat(guidTable, "-")
    end
end

function DatabasePlayer:ClearGuids()
    self.guids = ""
end
