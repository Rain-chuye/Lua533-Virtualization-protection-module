package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

-- 1. Define a complex function to be virtualized
local function complex_logic(n)
    local result = 0
    local data = {}

    for i = 1, n do
        if i % 2 == 0 then
            result = result + i
        else
            result = result * 1.1 -- This will trigger float arithmetic
        end
        table.insert(data, i)
    end

    local upvalue_val = 100
    local function nested_check(x)
        return x + upvalue_val
    end

    return result, #data, nested_check(result)
end

print("--- CYLuaVM Verification Sample ---")

-- 2. Run natively
local n_res, n_len, n_nested = complex_logic(10)
print(string.format("Native Results: result=%.2f, length=%d, nested=%s", n_res, n_len, tostring(n_nested)))

-- 3. Automatically virtualize using CYLuaVM
print("Virtualizing function...")
local v_complex_logic = CYLuaVM.buildEntry(complex_logic)

-- 4. Run virtualized
local v_res, v_len, v_nested = v_complex_logic(10)
print(string.format("Virtualized Results: result=%.2f, length=%d, nested=%s", v_res, v_len, tostring(v_nested)))

-- 5. Validation
if math.abs(n_res - v_res) < 0.0001 and n_len == v_len and n_nested == v_nested then
    print("\n[SUCCESS] Virtualized function output matches native output exactly.")
else
    print("\n[FAILURE] Mismatch detected between native and virtualized execution.")
    os.exit(1)
end

print("\n--- Testing string.dump on virtualized function ---")
local ok, dumped = pcall(string.dump, v_complex_logic)
if ok then
    print("string.dump successful! (Length: " .. #dumped .. ")")
else
    print("string.dump failed: " .. tostring(dumped))
end

print("\n--- All checks completed successfully ---")
