local A, NS = ...

---@alias Guid string

ChosenLadder = LibStub("AceAddon-3.0"):NewAddon(A, "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0")

NS.CL = ChosenLadder
NS.Icon = LibStub("LibDBIcon-1.0")

---@alias array<T> { [number] : T }

-- Functions Container
---@class Functions
local Functions = {}
NS.Functions = Functions

---@diagnostic disable-next-line: deprecated
unpack = unpack or table.unpack

function Trim(s)
    return s:match "^%s*(.*%S)" or ""
end

Functions.Trim = Trim

---@param str string
---@param start string
---@return boolean
function StartsWith(str, start)
    return str:sub(1, #start) == start
end

Functions.StartsWith = StartsWith

---@param str string
---@param ender string
---@return boolean
function EndsWith(str, ender)
    return str:sub(#ender * -1) == ender
end

Functions.EndsWith = EndsWith

---@param inputstr string
---@param sep string
---@return string[]
function Split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

Functions.Split = Split

---@param table any
---@param sep any
---@return string
function Join(table, sep)
    ---@type string
    local out = ""
    for _, v in pairs(table) do
        out = out .. tostring(v) .. sep
    end

    out = out .. ""

    if EndsWith(out, sep) then
        out = string.sub(out, 1, #sep * -1)
    end

    return out
end

Functions.Join = Join

function Dump(o)
    local varType = type(o)
    if varType == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            s = s .. "[" .. Dump(k) .. "] = " .. Dump(v) .. ","
        end
        return s .. "} "
    elseif varType == "number" then
        return tostring(o)
    else
        return string.format('"%s"', tostring(o))
    end
end

Functions.Dump = Dump

function ToArray(t)
    local ret = {}
    for _, v in pairs(t) do
        table.insert(ret, v)
    end

    return ret
end

Functions.ToArray = ToArray

---Filters a table based on a predicate function
---@param t table table to filter
---@param f function (item) returns boolean
---@return table
function Filter(t, f)
    local ret = {}
    for k, v in pairs(t) do
        if f(v) then
            ret[k] = v
        end
    end

    return ret
end

Functions.Filter = Filter

---Filters a table based on a predicate function, guarantees an array
---@generic T : table
---@param t array<T> table to filter
---@param f function (item) returns boolean
---@return array<T>
function FilterArray(t, f)
    return ToArray(Filter(t, f))
end

Functions.FilterArray = FilterArray

---Finds the first value in the supplied array which matches the predicate function, nil if none
---@generic T : table
---@param t array<T> table to filter
---@param f function (item) returns boolean
---@return T|nil
---@return integer|nil
function Find(t, f)
    if t ~= nil then
        for k, v in ipairs(t) do
            if f(v) then
                return v, k
            end
        end
    end

    return nil, nil
end

Functions.Find = Find

---@param guid string?
---@return string
function ShortenPlayerGuid(guid)
    local sub, _ = string.gsub(guid or "", "Player%-4648%-", "")
    return sub
end

Functions.ShortenPlayerGuid = ShortenPlayerGuid

---Determines if the supplied value is an item link
---@param val string
---@return boolean
function IsItemLink(val)
    local itemParts = Functions.Split(val, "|")
    return #itemParts > 1 and StartsWith(itemParts[2], "Hitem:")
end

Functions.IsItemLink = IsItemLink

---Determins if the supplied value is an item GUID
---@param val string
---@return boolean
function IsItemGUID(val)
    return StartsWith(val, "Item-4648-0")
end

Functions.IsItemGUID = IsItemGUID

local waitTable = {}
local waitFrame = nil

function Wait(delay, func, ...)
    if (type(delay) ~= "number" or type(func) ~= "function") then
        return false;
    end
    if (waitFrame == nil) then
        waitFrame = CreateFrame("Frame", "WaitFrame", UIParent);
        waitFrame:SetScript("OnUpdate", function(self, elapse)
            local count = #waitTable;
            local i = 1;
            while (i <= count) do
                local waitRecord = tremove(waitTable, i);
                local d = tremove(waitRecord, 1);
                local f = tremove(waitRecord, 1);
                local p = tremove(waitRecord, 1);
                if (d > elapse) then
                    tinsert(waitTable, i, { d - elapse, f, p });
                    i = i + 1;
                else
                    count = count - 1;
                    f(unpack(p));
                end
            end
        end);
    end
    tinsert(waitTable, { delay, func, { ... } });
    return true;
end

Functions.Wait = Wait
