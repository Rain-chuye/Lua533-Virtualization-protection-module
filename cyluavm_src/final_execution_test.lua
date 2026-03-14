package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

-- Function to virtualize
local function my_app(a, b)
    local sum = a + b
    local fact = 1
    for i = 1, 5 do fact = fact * i end
    return "Sum: " .. sum .. ", Factorial(5): " .. fact
end

print("--- Step 1: Virtualizing function ---")
local v_app = CYLuaVM.buildEntry(my_app)

print("--- Step 2: Dumping to 'virtualized_logic.bin' ---")
local data = string.dump(v_app)
local f = io.open("virtualized_logic.bin", "wb")
f:write(data)
f:close()
print("Saved virtualized file: virtualized_logic.bin (" .. #data .. " bytes)")

print("--- Step 3: Loading from 'virtualized_logic.bin' ---")
local f2 = io.open("virtualized_logic.bin", "rb")
local data2 = f2:read("*a")
f2:close()

local loaded_v_app = load(data2)
if not loaded_v_app then
    print("[ERROR] Failed to load virtualized file!")
    os.exit(1)
end

print("--- Step 4: Executing virtualized function ---")
local final_res = loaded_v_app(10, 20)
print("Execution Result: " .. tostring(final_res))

if final_res == "Sum: 30, Factorial(5): 120" then
    print("\n[SUCCESS] Virtualization, Dumping, Loading, and Execution are all working correctly!")
else
    print("\n[FAILURE] Result mismatch!")
    os.exit(1)
end
