local CL, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

---@class LadderPlayer
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

---@param o LadderPlayer
---@return LadderPlayer
function DatabasePlayer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return boolean
function DatabasePlayer:IsPresent()
    return self.currentGuid ~= nil
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
    return self.currentGuid
end

---@param guid string
function DatabasePlayer:SetCurrentGuid(guid)
    local newGuid = F.ShortenPlayerGuid(guid)
    self.currentGuid = newGuid
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
