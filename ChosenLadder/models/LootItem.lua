local CL, NS = ...

---@type Functions
local F = NS.Functions

---@class LootItem
---@field guid? string
---@field itemLink string
---@field sold boolean
---@field player string
LootItem = {
    itemLink = "",
    sold = false,
    player = ""
}

---@param o? LootItem
---@return LootItem
function LootItem:new(o)
    ---@type LootItem
    o = o or { unpack(LootItem) }
    setmetatable(o, self)
    self.__index = self
    return o
end

function LootItem:IsMine()
    return Ambiguate(self.player, "all") == UnitName("player")
end

function LootItem:Serialize()
    return string.format("%s~%s~%s~%s", self.sold and "true" or "false", self.itemLink, self.player, self.guid or "")
end

---@param val string
function LootItem:Deserialize(val)
    local vals = F.Split(val, "~")
    local sold = vals[1] == "true" and true or false
    local itemLink = vals[2]
    local player = vals[3]
    local guid = vals[4]

    return LootItem:new({
        sold = sold,
        itemLink = itemLink,
        player = player,
        guid = guid
    })
end