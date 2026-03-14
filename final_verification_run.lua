-- package.cpath setup to find our built .so
package.cpath = "./?.so;" .. package.cpath

-- Mocking the user's environment 'import' if needed, but here we just require
local CYLuaVM = require("CYLuaVM")

print("--- CYLuaVM High-Performance Virtualization Verification ---")

-- A sample application logic
local function app_logic(n)
    local result = 0
    for i = 1, n do
        result = result + i
    end
    return result
end

print("1. Virtualizing function 'app_logic'...")
local virtual_app = CYLuaVM.buildEntry(app_logic)

print("2. Testing virtualization execution...")
local res = virtual_app(100)
print("Result of virtualized execution (1..100): " .. tostring(res))

if res == 5050 then
    print("[SUCCESS] Virtualized execution is correct.")
else
    print("[FAILURE] Virtualized execution mismatch!")
    os.exit(1)
end

print("3. Testing string.dump (Serialization Fix)...")
local dumped_data = string.dump(virtual_app)
print("Dumped virtualized function size: " .. #dumped_data .. " bytes")

print("4. Testing load (Deserialization)...")
local reloaded_app = load(dumped_data)
if not reloaded_app then
    print("[FAILURE] Failed to load dumped virtualized function!")
    os.exit(1)
end

print("5. Executing reloaded function...")
local final_res = reloaded_app(10)
print("Result of reloaded execution (1..10): " .. tostring(final_res))

if final_res == 55 then
    print("[SUCCESS] Full round-trip verified.")
else
    print("[FAILURE] Reloaded execution mismatch!")
    os.exit(1)
end

print("\n--- ALL TESTS PASSED SUCCESSFULLY ---")
print("The file 'CYLuaVM.so' is now compiled and ready.")
