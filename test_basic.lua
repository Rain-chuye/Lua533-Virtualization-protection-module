package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

local function add(a, b)
    return a + b
end

print("Testing native add(10, 20):", add(10, 20))

local v_add = CYLuaVM.buildEntry(add)
print("v_add(10, 20):", v_add(10, 20))

local function identity(a)
    return a
end

local v_identity = CYLuaVM.buildEntry(identity)
print("v_identity(42):", v_identity(42))

local function constants()
    return "hello", 123
end
local v_constants = CYLuaVM.buildEntry(constants)
print("v_constants():", v_constants())

local x = 10
local function upvalue_test(y)
    x = x + y
    return x
end
local v_upvalue_test = CYLuaVM.buildEntry(upvalue_test)
print("v_upvalue_test(5):", v_upvalue_test(5))
print("native x after virtual call:", x)

local function loop_test(n)
    local sum = 0
    for i = 1, n do
        sum = sum + i
    end
    return sum
end
local v_loop_test = CYLuaVM.buildEntry(loop_test)
print("v_loop_test(10):", v_loop_test(10))
