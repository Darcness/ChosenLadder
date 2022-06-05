local A, NS = ...

-- UI Container
NS.UI = {}
-- Functions Container
NS.Functions = {}
-- Data Container
NS.Data = {}

function Trim(s)
    return s:match '^%s*(.*%S)' or ''
end

NS.Functions.Trim = Trim