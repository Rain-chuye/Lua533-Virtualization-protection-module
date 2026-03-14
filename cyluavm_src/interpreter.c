#include "lua.h"
#include "lauxlib.h"
#include "lobject.h"
#include "lstate.h"
#include "lvm.h"
#include "ldo.h"
#include "ltm.h"
#include "ldebug.h"
#include "lgc.h"

#include "cyluavm_opcodes.h"
#include "cyluavm_internal.h"

// We reuse the Lua stack, but we need to manage our own instruction pointer.
// A CYLuaVM function is a C closure. Its first upvalue is the CYBytecode object (as a lightuserdata or blob).
// The other upvalues are the actual Lua upvalues.

static int cyluavm_interpreter(lua_State *L) {
    CYBytecode *bc = (CYBytecode *)lua_touserdata(L, lua_upvalueindex(1));
    const Instruction *pc = bc->code;
    TValue *k = bc->k;
    StkId base = L->ci->u.l.base; // This might need adjustment for C closures

    // For C closures, L->ci->u.c.k might be used differently.
    // However, the user said "reuse running stack", which is what lvm.c does.
    // In a C function, L->top points to the first free slot.
    // Arguments start at L->ci->func + 1.

    // Actually, for a C closure, it's easier to think of it as:
    // Slot 0, 1, ... are registers.
    // We should ensure enough stack space is available.
    luaD_checkstack(L, bc->maxstacksize);

    // For simplicity in this implementation, we'll map registers to L->ci->func + 1 + register_index
    StkId registers = L->ci->func + 1;

    for (;;) {
        Instruction i = *pc++;
        int op = CY_GET_OPCODE(i);
        int a = CY_GET_A(i);

        switch (op) {
            case CYOP_MOVE: {
                setobj2s(L, registers + a, registers + CY_GET_B(i));
                break;
            }
            case CYOP_LOADK: {
                setobj2s(L, registers + a, k + CY_GET_Bx(i));
                break;
            }
            case CYOP_LOADBOOL: {
                setbvalue(registers + a, CY_GET_B(i));
                if (CY_GET_C(i)) pc++;
                break;
            }
            case CYOP_LOADNIL: {
                int b = CY_GET_B(i);
                do {
                    setnilvalue(registers + a++);
                } while (b--);
                break;
            }
            case CYOP_GETUPVAL: {
                int b = CY_GET_B(i);
                // C closure upvalues start at index 1.
                // Upvalue 1 is our bytecode. So Lua upvalues start at index 2.
                setobj2s(L, registers + a, lua_upvalueindex(b + 2)); // Simplified
                break;
            }
            // ... Many more opcodes to implement ...
            case CYOP_RETURN: {
                int b = CY_GET_B(i);
                if (b != 0) L->top = registers + a + b - 1;
                return (b == 0) ? -1 : b - 1; // Lua C function return protocol
            }
            // Add other core opcodes like ADD, SUB, CALL, etc.
        }
    }
}
