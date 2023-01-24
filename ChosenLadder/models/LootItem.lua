local CL, NS = ...

---@type Functions
local F = NS.Functions

---@class LootItem
---@field guid? string
---@field itemLink string
---@field sold boolean
---@field player string
---@field itemId number
---@field expire number
LootItem = {
    itemLink = "",
    sold = false,
    player = "",
    itemId = 0,
    expire = 0
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
    return string.format("%s~%s~%s~%s~%s", self.sold and "1" or "0", self.itemId, self.player, tostring(self.expire or 0)
        , self.guid or "")
end

---@param val string
function LootItem:Deserialize(val)
    local vals = F.Split(val, "~")
    local sold = vals[1] == "1" and true or false
    local itemId = tonumber(vals[2]) or 0
    local player = vals[3]
    local expire = tonumber(vals[4]) or 0
    local guid = vals[5]

    local item = Item:CreateFromItemID(itemId)

    local lootItem = LootItem:new({
        sold = sold,
        itemId = itemId,
        player = player,
        guid = guid,
        expire = expire,
        itemLink = item:GetItemLink()
    })

    return lootItem
end
