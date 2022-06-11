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

ChosenLadder = LibStub("AceAddon-3.0"):NewAddon(A, "AceConsole-3.0", "AceComm-3.0")
NS.CL = ChosenLadder

function Trim(s)
    return s:match '^%s*(.*%S)' or ''
end

NS.Functions.Trim = Trim

function StartsWith(str, start)
    return str:sub(1, #start) == start
end

NS.Functions.StartsWith = StartsWith
