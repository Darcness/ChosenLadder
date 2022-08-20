local CL, NS = ...

---@type Data
local D = NS.Data
---@type Functions
local F = NS.Functions

---@class LadderList
---@field players LadderPlayer[]
---@field lastModified number
LadderList = {
    players = {},
    lastModified = 0
}

---@param o? LadderList
---@return LadderList
function LadderList:new(o)
    ---@type LadderList
    o = o or LadderList
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param rows string[]
function LadderList:BuildFromPlayerList(rows)
    ---@type LadderList
    local newPlayerList = LadderList:new({
        lastModified = GetServerTime(),
        players = {}
    })

    for _, v in ipairs(rows) do
        local nameParts = F.Split(v, ":")
        if #nameParts >= 2 then
            local player = DatabasePlayer:new({
                id = nameParts[1],
                name = nameParts[2],
                guids = F.Split(nameParts[3] or "", "-"),
                log = ""
            })
            table.insert(newPlayerList.players, player)
        else
            ChosenLadder:PrintToWindow("Invalid Import Data: " .. v)
        end
    end

    ChosenLadder:Database().factionrealm.ladder = newPlayerList
end
