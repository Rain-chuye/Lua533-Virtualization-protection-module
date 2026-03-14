#include "lua.h"
#include "lauxlib.h"
#include "lobject.h"
#include "lopcodes.h"
#include "lfunc.h"
#include "lstring.h"
#include "lmem.h"

#include "cyluavm_opcodes.h"

#include "mapping_data.c"

Instruction cy_translate_instruction(Instruction i) {
    OpCode op = GET_OPCODE(i);
    int cy_op = lua_to_cy[op];
    OpArgMask mode = getOpMode(op);

    switch (getOpMode(op)) {
        case iABC:
            return CY_CREATE_ABC(cy_op, GETARG_A(i), GETARG_B(i), GETARG_C(i));
        case iABx:
            return CY_CREATE_ABx(cy_op, GETARG_A(i), GETARG_Bx(i));
        case iAsBx:
            return CY_CREATE_ABx(cy_op, GETARG_A(i), GETARG_sBx(i) + 131071);
        case iAx:
            return CY_CREATE_Ax(cy_op, GETARG_Ax(i));
    }
    return 0;
}

typedef struct {
    Instruction *code;
    int sizecode;
    TValue *k;
    int sizek;
    Upvaldesc *upvalues;
    int sizeupvalues;
    int numparams;
    int is_vararg;
    int maxstacksize;
} CYProto;

// Serialized format will be needed for string.dump hijack
