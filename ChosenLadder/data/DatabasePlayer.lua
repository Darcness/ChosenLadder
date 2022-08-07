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
    -- local base = {}
    -- for k, v in pairs(DatabasePlayer) do base[k] = v end
    o = o or {}
    -- for k, v in pairs(o) do base[k] = v end
    setmetatable(o, self)
    self.__index = self
    -- return base
    return o
end

---@return boolean
function DatabasePlayer:IsPresent()
    local guidTable = F.Split(self.guids, "-")
    for _, guid in ipairs(guidTable) do
        ---@param a RaidRosterInfo
        if F.Find(D.raidRoster, function(a)
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
        for _, rosterInfo in ipairs(D.raidRoster) do
            local playerGuid = F.ShortenPlayerGuid(UnitGUID(Ambiguate(rosterInfo.name, "all")))
            if playerGuid == F.ShortenPlayerGuid(guid) then
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
