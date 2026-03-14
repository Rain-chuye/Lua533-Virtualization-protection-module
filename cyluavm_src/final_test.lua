package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

local function my_function(n)
    local result = 0
    for i = 1, n do
        result = result + i
    end
    return result
end

print("--- Step 1: Virtualizing function ---")
local v_func = CYLuaVM.buildEntry(my_function)

print("--- Step 2: Dumping to binary file (string.dump hijack) ---")
local data = string.dump(v_func)
local f = io.open("test_virtualized.bin", "wb")
f:write(data)
f:close()
print("Saved " .. #data .. " bytes to test_virtualized.bin")

print("--- Step 3: Loading from binary file (load hijack) ---")
local f2 = io.open("test_virtualized.bin", "rb")
local data2 = f2:read("*a")
f2:close()
local loaded_v_func = load(data2)

if not loaded_v_func then
    print("[ERROR] Failed to load virtualized binary!")
    os.exit(1)
end

print("--- Step 4: Executing loaded function ---")
local res = loaded_v_func(100)
print("Result of loaded_v_func(100): " .. tostring(res))

if res == 5050 then
    print("\n[VERIFICATION SUCCESSFUL] The virtualized function was dumped, reloaded, and executed correctly.")
else
    print("\n[VERIFICATION FAILED] Expected 5050, got " .. tostring(res))
    os.exit(1)
end
