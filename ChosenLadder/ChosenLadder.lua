local A, NS = ...

-- UI Container
NS.UI = {}
-- Functions Container
NS.Functions = {}
-- Data Container
NS.Data = {}
NS.Data.Constants = {}
NS.Data.Constants.BeginSyncFlag = "BEGIN SYNC:"
NS.Data.Constants.EndSyncFlag = "END SYNC"
NS.Data.Constants.AsheosWords = {
    "dunk",
    "sunk",
    "funk",
    "dink",
    "dynk",
    "dumk",
    "dubk",
    "dunl",
    "duni",
    "dunm",
    "dlunk",
    "drunk"
}

StreamFlag = {
    Empty = 1,
    Started = 2,
    Complete = 3
}

NS.Data.Constants.StreamFlag = StreamFlag

ChosenLadder = LibStub("AceAddon-3.0"):NewAddon(A, "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0")

NS.CL = ChosenLadder

function Trim(s)
    return s:match "^%s*(.*%S)" or ""
end

NS.Functions.Trim = Trim

function StartsWith(str, start)
    return str:sub(1, #start) == start
end

NS.Functions.StartsWith = StartsWith

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

NS.Functions.Split = Split

function Dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. Dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 NS.Functions.Dump = Dump