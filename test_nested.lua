package.cpath = "./cyluavm_src/?.so;" .. package.cpath
local CYLuaVM = require("CYLuaVM")

local function outer(a)
    local function inner(b)
        return a + b
    end
    return inner
end

local v_outer = CYLuaVM.buildEntry(outer)
local v_inner = v_outer(10)

-- Note: The current implementation of buildEntry doesn't automatically virtualize inner functions
-- created by OP_CLOSURE because OP_CLOSURE isn't implemented yet.
-- To support nested functions, OP_CLOSURE must be implemented to create a virtualized closure.

print("Testing nested function (will likely fail until OP_CLOSURE is implemented)")
local ok, res = pcall(v_inner, 5)
if ok then print("Result:", res) else print("Error:", res) end
