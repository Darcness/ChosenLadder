local CL, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

---@class RaidRoster
---@field members table<string, RaidMember>
RaidRoster = {
    members = {}
}

---@param o? RaidRoster
---@return RaidRoster
function RaidRoster:new(o)
    o = o or RaidRoster
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param playername string
---@return boolean
function RaidRoster:IsPlayerInRaid(playername)
    if playername == nil then return false end
    local playerGuid = F.ShortenPlayerGuid(UnitGUID(Ambiguate(playername, "all")))
    return self.members[playerGuid] ~= nil
end

function RaidRoster:Clear()
    self.members = {}
end

---@param guid string
---@return RaidMember?
function RaidRoster:GetPlayerByGuid(guid)
    local guid = F.ShortenPlayerGuid(guid)
    return self.members[guid]
end
