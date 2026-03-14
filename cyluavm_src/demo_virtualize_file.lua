package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

-- A target function to be virtualized
local function my_app(a, b)
    local sum = a + b
    local fact = 1
    for i = 1, 5 do fact = fact * i end
    return "Sum: " .. sum .. ", Factorial(5): " .. fact
end

print("--- Step 1: Virtualizing function ---")
local v_app = CYLuaVM.buildEntry(my_app)

print("--- Step 2: Dumping virtualized function to 'app_v.bin' ---")
local dumped_data = string.dump(v_app)
local f = io.open("app_v.bin", "wb")
f:write(dumped_data)
f:close()
print("Successfully generated 'app_v.bin' (" .. #dumped_data .. " bytes)")

print("--- Step 3: Loading virtualized function from 'app_v.bin' ---")
local f_in = io.open("app_v.bin", "rb")
local data_in = f_in:read("*a")
f_in:close()

-- The 'load' function is hijacked by CYLuaVM to recognize our custom format
local loaded_v_app = load(data_in)
if not loaded_v_app then
    error("Failed to load virtualized file!")
end

print("--- Step 4: Testing execution of loaded virtualized function ---")
local final_result = loaded_v_app(10, 20)
print("Output: " .. tostring(final_result))

-- (10+20) = 30; Factorial(5) = 120
if final_result == "Sum: 30, Factorial(5): 120" then
    print("\n[VERIFICATION SUCCESSFUL] The virtualized file was generated, loaded, and executed correctly.")
else
    print("\n[VERIFICATION FAILED] Result mismatch!")
    os.exit(1)
end
