package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

local function target(n)
    local x = 0
    for i = 1, n do x = x + i end
    return x
end

-- Virtualize
local v1 = CYLuaVM.buildEntry(target)
-- Dump to file
local data = string.dump(v1)
local f = io.open("virtualized.bin", "wb")
f:write(data)
f:close()

-- Load from file
local f2 = io.open("virtualized.bin", "rb")
local data2 = f2:read("*a")
f2:close()
local v2 = load(data2)

-- Execute
local res = v2(10)
if res == 55 then
    print("VIRTUALIZATION_SUCCESS")
else
    print("VIRTUALIZATION_FAILURE: " .. tostring(res))
end
