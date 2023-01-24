local CL, NS = ...

---@type Functions
local F = NS.Functions

---@class LootList
---@field items LootItem[]
---@field lastModified number
---@field data Data
LootList = {
    items = {},
    lastModified = 0
}

---@param data Data
---@param o? LootList
---@return LootList
function LootList:new(data, o)
    ---@type LootList
    o = o or { unpack(LootList) }
    o.data = data
    setmetatable(o, self)
    self.__index = self
    return o
end

---Updates the items list, and handles any postprocessing
---@param items LootItem[]
function LootList:Update(items)
    local count = #self.items
    self.items = items
    if #self.items ~= count then
        self:SendUpdate()
    end
    self.lastModified = GetServerTime()
end

---Clears the items list
function LootList:Clear()
    self:Update({})
end

---@param target string? Target player to receive update
function LootList:SendUpdate(target)
    ChosenLadder:Log("Sending Update")
    ChosenLadder:SendMessage(self.data.Constants.LootListFlag .. "||" .. self:Serialize(), (target ~= nil and "WHISPER" or "RAID"), false, target)
end

---@param guid string
---@return LootItem|nil
function LootList:GetByGUID(guid)
    ---@param item LootItem
    return F.Find(self.items, function(item) return item.guid == guid end)
end

---@param guid string
function LootList:RemoveByGUID(guid)
    local newItems = {}
    for _, item in pairs(self.items) do
        if item.guid ~= guid then
            table.insert(newItems, item)
        end
    end
    self:Update(newItems)
end

---Serializes the current Loot items (ignores lastModified)
---@return string
function LootList:Serialize()
    local serializedItems = {}
    ---@param key string
    ---@param value LootItem
    foreach(self.items, function(key, value)
        table.insert(serializedItems, value:Serialize())
    end)

    return F.Join(serializedItems, "//")
end

---Deserializes the string into a list of LootItems
---@param val string
---@return LootItem[]
function LootList:Deserialize(val)
    local itemStrings = F.Split(val, "//")
    ---@type LootItem[]
    local deserializedItems = {}
    ---@param key string
    ---@param value string
    foreach(itemStrings, function(key, value)
        table.insert(deserializedItems, LootItem:Deserialize(value))
    end)
    return deserializedItems
end
