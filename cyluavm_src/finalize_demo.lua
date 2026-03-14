package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

print("--- Step 1: Loading app.lua ---")
local f_app = loadfile("app.lua")
if not f_app then error("Failed to load app.lua") end

print("--- Step 2: Virtualizing app.lua ---")
local v_app = CYLuaVM.buildEntry(f_app)

print("--- Step 3: Saving virtualized version to app_v.bin ---")
local dumped_data = string.dump(v_app)
local f_bin = io.open("app_v.bin", "wb")
f_bin:write(dumped_data)
f_bin:close()
print("Saved " .. #dumped_data .. " bytes.")

print("--- Step 4: Loading virtualized version from app_v.bin ---")
local f_in = io.open("app_v.bin", "rb")
local data_in = f_in:read("*a")
f_in:close()

local loaded_v_app = load(data_in)
if not loaded_v_app then error("Failed to load app_v.bin") end

print("--- Step 5: Executing virtualized application ---")
local res = loaded_v_app()
print("Final Result: " .. tostring(res))

if res == 55 then
    print("\n[CYLuaVM VERIFICATION SUCCESSFUL]")
else
    print("\n[CYLuaVM VERIFICATION FAILED]")
    os.exit(1)
end
