package.cpath = "./?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

local function app(n)
    local s = 0
    for i = 1, n do s = s + i end
    return s
end

print("Virtualizing...")
local v = CYLuaVM.buildEntry(app)
print("Dumping...")
local data = string.dump(v)
print("Loading...")
local loaded = load(data)
print("Executing...")
local res = loaded(10)

if res == 55 then
    print("VIRTUALIZATION_ROUNDTRIP_SUCCESSFUL")
else
    print("VIRTUALIZATION_ROUNDTRIP_FAILED: " .. tostring(res))
    os.exit(1)
end
