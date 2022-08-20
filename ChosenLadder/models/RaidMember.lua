local CL, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

---@class RaidMember
---@field name string
---@field rank number
---@field subgroup number
---@field level number
---@field class string
---@field fileName string
---@field zone string?
---@field online boolean
---@field isDead boolean
---@field role string
---@field isML boolean
---@field combatRole string
---@field guid string

RaidMember = {
    name = "",
    rank = "",
    subgroup = 0,
    level = 0,
    class = "",
    fileName = "",
    online = false,
    isDead = false,
    role = "",
    isML = false,
    combatRole = "",
    guid = ""
}

---@param o RaidMember
---@return RaidMember
function RaidMember:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return RaidMember | nil
function RaidMember:CreateByRaidIndex(raidIndex)
    local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex)
    if name == nil then
        return nil
    end

    ---@type RaidMember
    local member = RaidMember:new({
        name = name,
        rank = rank,
        subgroup = subgroup,
        level = level,
        class = class,
        fileName = fileName,
        zone = zone,
        online = online,
        isDead = isDead,
        role = role,
        isML = isML,
        combatRole = combatRole,
        guid = UnitGUID(Ambiguate(name, "all")) or ""
    })
    return member
end
