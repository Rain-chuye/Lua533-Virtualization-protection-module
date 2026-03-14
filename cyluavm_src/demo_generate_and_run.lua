package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

-- A target function to be virtualized
local function compute(a, b)
    local result = (a + b) * 10
    for i = 1, 5 do
        result = result + i
    end
    return "Result is: " .. result
end

print("--- Step 1: Virtualizing function ---")
local v_compute = CYLuaVM.buildEntry(compute)

print("--- Step 2: Dumping virtualized function to 'app_v.bin' ---")
local dumped_data = string.dump(v_compute)
local f = io.open("app_v.bin", "wb")
f:write(dumped_data)
f:close()
print("Successfully generated 'app_v.bin' (" .. #dumped_data .. " bytes)")

print("--- Step 3: Loading virtualized function from 'app_v.bin' ---")
local f_in = io.open("app_v.bin", "rb")
local data_in = f_in:read("*a")
f_in:close()

local loaded_v_compute = load(data_in)
if not loaded_v_compute then
    error("Failed to load virtualized file!")
end

print("--- Step 4: Testing execution of loaded virtualized function ---")
local final_result = loaded_v_compute(5, 5)
print("Output: " .. tostring(final_result))

-- (5+5)*10 = 100; 100 + 1 + 2 + 3 + 4 + 5 = 115
if final_result == "Result is: 115" then
    print("\n[VERIFICATION SUCCESSFUL] The virtualized file was generated, loaded, and executed correctly.")
else
    print("\n[VERIFICATION FAILED] Result mismatch!")
    os.exit(1)
end
