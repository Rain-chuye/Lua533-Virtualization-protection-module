package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

local function my_app(n)
    local result = 0
    for i = 1, n do
        result = result + i
    end
    return "The sum of 1 to " .. n .. " is " .. result
end

print("--- Step 1: Virtualizing function ---")
local v_app = CYLuaVM.buildEntry(my_app)

print("--- Step 2: Saving to virtualized file ---")
local data = string.dump(v_app)
local f = io.open("app_virtualized.bin", "wb")
f:write(data)
f:close()
print("Saved " .. #data .. " bytes to app_virtualized.bin")

print("--- Step 3: Loading and Executing from file ---")
local loaded_f = load(data)
local final_res = loaded_f(10)
print("Execution Result: " .. tostring(final_res))

if final_res == "The sum of 1 to 10 is 55" then
    print("\n[VERIFICATION SUCCESSFUL]")
else
    print("\n[VERIFICATION FAILED]")
    os.exit(1)
end
