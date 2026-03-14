package.cpath = "./cyluavm_src/?.so;" .. package.cpath
-- Mocking the user's environment structure
local CYLuaVM = require("CYLuaVM")

-- Sample app.lua content
local app_content = [[
print("Hello from virtualized app.lua!")
local x = 0
for i = 1, 100 do x = x + i end
print("Sum 1..100 is: " .. x)
return x
]]
local f = io.open("app.lua", "w")
f:write(app_content)
f:close()

print("--- Starting CYLuaVM Demo ---")
local F = loadfile("app.lua")
if not F then print("Failed to load app.lua") return end

print("Building virtual entry...")
local FF = CYLuaVM.buildEntry(F)

print("Executing virtualized function...")
local result = FF()
print("Result of execution: " .. tostring(result))

if result == 5050 then
    print("\n[SUCCESS] CYLuaVM is running correctly.")
else
    print("\n[FAILURE] Result mismatch.")
end
