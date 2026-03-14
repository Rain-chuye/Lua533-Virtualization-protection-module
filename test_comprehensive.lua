package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

local function assert_eq(a, b, msg)
    if a ~= b then
        error(string.format("%s: %s ~= %s", msg, tostring(a), tostring(b)))
    end
end

print("Test 1: Basic arithmetic and logic")
local function basic(a, b)
    local c = a + b
    local d = a * b
    local e = a > b
    return c, d, e
end
local v_basic = CYLuaVM.buildEntry(basic)
local c1, d1, e1 = v_basic(10, 5)
assert_eq(c1, 15, "add")
assert_eq(d1, 50, "mul")
assert_eq(e1, true, "gt")
print("Test 1 passed")

print("Test 2: Upvalues")
local count = 0
local function counter()
    count = count + 1
    return count
end
local v_counter = CYLuaVM.buildEntry(counter)
assert_eq(v_counter(), 1, "counter 1")
assert_eq(v_counter(), 2, "counter 2")
assert_eq(count, 2, "native count")
print("Test 2 passed")

print("Test 3: Loops")
local function sum_n(n)
    local s = 0
    for i = 1, n do
        s = s + i
    end
    return s
end
local v_sum_n = CYLuaVM.buildEntry(sum_n)
assert_eq(v_sum_n(10), 55, "sum_n(10)")
assert_eq(v_sum_n(100), 5050, "sum_n(100)")
print("Test 3 passed")

print("Test 4: Tables")
local function tables()
    local t = {a = 1, b = 2}
    t.c = t.a + t.b
    return t.c
end
local v_tables = CYLuaVM.buildEntry(tables)
assert_eq(v_tables(), 3, "table ops")
print("Test 4 passed")

print("Test 5: string.dump hijack")
local dumped = string.dump(v_basic)
assert_eq(type(dumped), "string", "dump type")
-- In current impl, it returns a marker
assert_eq(dumped, "CYLUAVM_DUMPED_DATA", "dump marker")
print("Test 5 passed")

print("All tests passed!")
