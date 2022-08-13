local CL, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

---@class DatabasePlayer
---@field id string
---@field name string
---@field guids string[]
---@field log string
DatabasePlayer = {
    id = "",
    name = "",
    guids = {},
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
    for _, guid in ipairs(self.guids) do
        ---@param a RaidRosterInfo
        if F.Find(D:GetRaidRoster(), function(a)
            return F.ShortenPlayerGuid(UnitGUID(Ambiguate(a.name, "all"))) == F.ShortenPlayerGuid(guid)
        end) then
            return true
        end
    end

    return false
end

---@param guid string
---@return boolean
function DatabasePlayer:HasGuid(guid)
    local newGuid = F.ShortenPlayerGuid(guid);
    ---@param a string
    return select(1, F.Find(self.guids, function(a) return a == newGuid end)) ~= nil
end

---@return string | nil
function DatabasePlayer:CurrentGuid()
    for _, rosterInfo in ipairs(D:GetRaidRoster()) do
        local playerGuid = rosterInfo.guid ~= nil and F.ShortenPlayerGuid(rosterInfo.guid) or
            F.ShortenPlayerGuid(UnitGUID(Ambiguate(rosterInfo.name, "all")))
        if self:HasGuid(playerGuid) then
            return playerGuid
        end
    end

    return nil
end

---@param guid string
function DatabasePlayer:AddGuid(guid)
    local newGuid = F.ShortenPlayerGuid(guid)
    if not F.Find(self.guids, function(a) return a == newGuid end) then
        table.insert(self.guids, newGuid)
    end
end

function DatabasePlayer:ClearGuids()
    self.guids = {}
end
