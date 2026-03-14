package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

-- 1. Create a sample Lua source file
local source_code = [[
local a = 10
local b = 20
print("Calculating sum in virtualized environment...")
local sum = a + b
for i = 1, 5 do
    sum = sum + i
end
print("Final sum:", sum)
return sum
]]

local f = io.open("test_source.lua", "w")
f:write(source_code)
f:close()

print("Step 1: Loading source file...")
local chunk = loadfile("test_source.lua")

print("Step 2: Virtualizing chunk...")
local virtual_chunk = CYLuaVM.buildEntry(chunk)

print("Step 3: Testing string.dump (Serialization)...")
local dumped_data = string.dump(virtual_chunk)
print("Dumped size: " .. #dumped_data .. " bytes")

-- In a real scenario, we would save this to a file
local f_bin = io.open("test_virtualized.bin", "wb")
f_bin:write(dumped_data)
f_bin:close()
print("Saved virtualized bytecode to test_virtualized.bin")

print("Step 4: Executing virtualized chunk directly...")
local result = virtual_chunk()

print("Step 5: Verifying result...")
if result == 45 then
    print("[SUCCESS] Virtualized execution result is correct (45).")
else
    print("[FAILURE] Virtualized execution result is incorrect: " .. tostring(result))
end
