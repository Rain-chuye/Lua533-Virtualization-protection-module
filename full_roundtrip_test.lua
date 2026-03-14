package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

-- 1. Define a function
local function target(n)
    local x = 0
    for i = 1, n do
        x = x + i
    end
    return x
end

print("Step 1: Virtualizing function...")
local v_target = CYLuaVM.buildEntry(target)

print("Step 2: Dumping virtualized function...")
local dumped = string.dump(v_target)
print("Dumped size: " .. #dumped .. " bytes")

-- Save to file
local f = io.open("v_target.bin", "wb")
f:write(dumped)
f:close()

print("Step 3: Loading function back from binary...")
local reloaded = load(dumped)
if not reloaded then
    error("Failed to load dumped virtualized function")
end

print("Step 4: Executing reloaded function...")
local res = reloaded(10)
print("Result of reloaded(10): " .. tostring(res))

if res == 55 then
    print("\n[SUCCESS] Full round-trip (Virtualize -> Dump -> Load -> Execute) successful!")
else
    print("\n[FAILURE] Result mismatch: expected 55, got " .. tostring(res))
    os.exit(1)
end
