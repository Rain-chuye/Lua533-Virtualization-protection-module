package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

-- A target function to be virtualized
local function secret_logic(a, b)
    local result = (a + b) * 2
    for i = 1, 5 do
        result = result + i
    end
    return result
end

print("--- Step 1: Virtualizing function ---")
local v_secret = CYLuaVM.buildEntry(secret_logic)

print("--- Step 2: Dumping to 'secret.v' ---")
local data = string.dump(v_secret)
local f = io.open("secret.v", "wb")
f:write(data)
f:close()
print("Saved virtualized bytecode (" .. #data .. " bytes)")

print("--- Step 3: Loading from 'secret.v' ---")
local f2 = io.open("secret.v", "rb")
local data2 = f2:read("*a")
f2:close()

local loaded_v_secret = load(data2)
if not loaded_v_secret then
    error("FAILED TO LOAD VIRTUALIZED FILE")
end

print("--- Step 4: Testing execution ---")
local res = loaded_v_secret(10, 20)
print("Result of loaded_v_secret(10, 20): " .. tostring(res))

-- (10+20)*2 = 60; 60 + 1 + 2 + 3 + 4 + 5 = 75
if res == 75 then
    print("\n[VERIFICATION SUCCESSFUL] Virtualized file generated and executed correctly.")
else
    print("\n[VERIFICATION FAILED] Expected 75, got " .. tostring(res))
    os.exit(1)
end
