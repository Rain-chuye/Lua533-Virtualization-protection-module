#define LUA_CORE
#include "lua.h"
#include "lauxlib.h"
#include "lobject.h"
#include "lstate.h"
#include "lvm.h"
#include "ldo.h"
#include "lfunc.h"
#include "lstring.h"
#include "lgc.h"
#include "ltm.h"
#include "ldebug.h"
#include "ltable.h"
#include <string.h>

#include "cyluavm_opcodes.h"
#include "cyluavm_internal.h"
#include "mapping_data.c"

static int cyluavm_interpreter(lua_State *L);

static void free_bytecode(lua_State *L, CYBytecode *bc) {
    if (!bc) return;
    if (bc->code) luaM_freearray(L, bc->code, bc->sizecode);
    if (bc->k) luaM_freearray(L, bc->k, bc->sizek);
    luaM_free(L, bc);
}

static int bc_gc(lua_State *L) {
    CYBytecode **ubc = (CYBytecode **)lua_touserdata(L, 1);
    if (ubc && *ubc) {
        free_bytecode(L, *ubc);
        *ubc = NULL;
    }
    return 0;
}

static Instruction cy_translate_instruction(Instruction i) {
    OpCode op = GET_OPCODE(i);
    int cy_op = lua_to_cy[op];
    switch (getOpMode(op)) {
        case iABC:  return CY_CREATE_ABC(cy_op, GETARG_A(i), GETARG_B(i), GETARG_C(i));
        case iABx:  return CY_CREATE_ABx(cy_op, GETARG_A(i), GETARG_Bx(i));
        case iAsBx: return CY_CREATE_ABx(cy_op, GETARG_A(i), GETARG_sBx(i) + 131071);
        case iAx:   return CY_CREATE_Ax(cy_op, GETARG_Ax(i));
    }
    return 0;
}

static CYBytecode *translate_proto(lua_State *L, Proto *p) {
    CYBytecode *bc = (CYBytecode *)luaM_malloc(L, sizeof(CYBytecode));
    bc->sizecode = p->sizecode;
    bc->code = luaM_newvector(L, p->sizecode, Instruction);
    for (int i = 0; i < p->sizecode; i++) bc->code[i] = cy_translate_instruction(p->code[i]);
    bc->sizek = p->sizek;
    bc->k = luaM_newvector(L, p->sizek, TValue);
    for (int i = 0; i < p->sizek; i++) setobj(L, &bc->k[i], &p->k[i]);
    bc->numparams = p->numparams;
    bc->is_vararg = p->is_vararg;
    bc->maxstacksize = p->maxstacksize;
    return bc;
}

static int buildEntry(lua_State *L) {
    luaL_checktype(L, 1, LUA_TFUNCTION);
    if (lua_iscfunction(L, 1)) { lua_pushvalue(L, 1); return 1; }
    LClosure *f = clLvalue(L->ci->func + 1);
    Proto *p = f->p;
    CYBytecode *bc = translate_proto(L, p);
    CYBytecode **ubc = (CYBytecode **)lua_newuserdata(L, sizeof(CYBytecode *));
    *ubc = bc;
    lua_newtable(L);
    lua_pushcfunction(L, bc_gc);
    lua_setfield(L, -2, "__gc");
    lua_setmetatable(L, -2);
    int nup = p->sizeupvalues;
    luaL_checkstack(L, nup + 2, "too many upvalues");
    lua_pushvalue(L, -1);
    for (int i = 0; i < nup; i++) {
        lua_getupvalue(L, 1, i + 1);
    }
    lua_pushcclosure(L, cyluavm_interpreter, nup + 1);
    return 1;
}

#define RA(i) (base + CY_GET_A(i))
#define RB(i) (base + CY_GET_B(i))
#define RC(i) (base + CY_GET_C(i))
#define RKB(i) (CY_GET_B(i) & 0x100 ? k + (CY_GET_B(i) & 0xFF) : base + CY_GET_B(i))
#define RKC(i) (CY_GET_C(i) & 0x100 ? k + (CY_GET_C(i) & 0xFF) : base + CY_GET_C(i))

static int cyluavm_interpreter(lua_State *L) {
    CClosure *cl_func = clCvalue(L->ci->func);
    CYBytecode **ubc = (CYBytecode **)lua_touserdata(L, lua_upvalueindex(1));
    CYBytecode *bc = *ubc;
    const Instruction *pc = bc->code;
    TValue *k = bc->k;
    StkId base = L->ci->func + 1;
    luaD_checkstack(L, bc->maxstacksize + 20);
    if (L->top < base + bc->maxstacksize) L->top = base + bc->maxstacksize;
    for (;;) {
        Instruction i = *pc++;
        int op = CY_GET_OPCODE(i);
        switch (op) {
            case CYOP_MOVE: setobjs2s(L, RA(i), RB(i)); break;
            case CYOP_LOADK: setobj2s(L, RA(i), k + CY_GET_Bx(i)); break;
            case CYOP_LOADBOOL: setbvalue(RA(i), CY_GET_B(i)); if (CY_GET_C(i)) pc++; break;
            case CYOP_LOADNIL: { int b = CY_GET_B(i); StkId ra = RA(i); do { setnilvalue(ra++); } while (b--); break; }
            case CYOP_GETUPVAL: { int b = CY_GET_B(i); setobj2s(L, RA(i), &cl_func->upvalue[b + 1]); break; }
            case CYOP_SETUPVAL: { int b = CY_GET_B(i); setobj(L, &cl_func->upvalue[b + 1], RA(i)); luaC_barrier(L, cl_func, RA(i)); break; }
            case CYOP_GETTABUP: { int b = CY_GET_B(i); TValue *upv = &cl_func->upvalue[b + 1]; TValue *rc = RKC(i); luaV_gettable(L, upv, rc, RA(i)); break; }
            case CYOP_SETTABUP: { int a_val = CY_GET_A(i); TValue *upv = &cl_func->upvalue[a_val + 1]; TValue *rb = RKB(i); TValue *rc = RKC(i); luaV_settable(L, upv, rb, rc); break; }
            case CYOP_GETTABLE: luaV_gettable(L, RB(i), RKC(i), RA(i)); break;
            case CYOP_SETTABLE: luaV_settable(L, RA(i), RKB(i), RKC(i)); break;
            case CYOP_NEWTABLE: { int b = CY_GET_B(i); int c = CY_GET_C(i); Table *t = luaH_new(L); sethvalue(L, RA(i), t); if (b != 0 || c != 0) luaH_resize(L, t, luaO_fb2int(b), luaO_fb2int(c)); luaC_checkGC(L); break; }
            case CYOP_SELF: { StkId ra = RA(i); setobjs2s(L, ra + 1, RB(i)); luaV_gettable(L, RB(i), RKC(i), ra); break; }
            case CYOP_ADD: { TValue *rb = RKB(i); TValue *rc = RKC(i); if (ttisinteger(rb) && ttisinteger(rc)) { setivalue(RA(i), ivalue(rb) + ivalue(rc)); } else { luaV_arith(L, RA(i), rb, rc, LUA_OPADD); } break; }
            case CYOP_SUB: { TValue *rb = RKB(i); TValue *rc = RKC(i); if (ttisinteger(rb) && ttisinteger(rc)) { setivalue(RA(i), ivalue(rb) - ivalue(rc)); } else { luaV_arith(L, RA(i), rb, rc, LUA_OPSUB); } break; }
            case CYOP_MUL: { TValue *rb = RKB(i); TValue *rc = RKC(i); if (ttisinteger(rb) && ttisinteger(rc)) { setivalue(RA(i), ivalue(rb) * ivalue(rc)); } else { luaV_arith(L, RA(i), rb, rc, LUA_OPMUL); } break; }
            case CYOP_DIV: { TValue *rb = RKB(i); TValue *rc = RKC(i); luaV_arith(L, RA(i), rb, rc, LUA_OPDIV); break; }
            case CYOP_MOD: { TValue *rb = RKB(i); TValue *rc = RKC(i); luaV_arith(L, RA(i), rb, rc, LUA_OPMOD); break; }
            case CYOP_POW: { TValue *rb = RKB(i); TValue *rc = RKC(i); luaV_arith(L, RA(i), rb, rc, LUA_OPPOW); break; }
            case CYOP_UNM: { TValue *rb = RB(i); luaV_arith(L, RA(i), rb, rb, LUA_OPUNM); break; }
            case CYOP_NOT: { TValue *rb = RB(i); int res = l_isfalse(rb); setbvalue(RA(i), res); break; }
            case CYOP_LEN: { luaV_objlen(L, RA(i), RB(i)); break; }
            case CYOP_CONCAT: { int b = CY_GET_B(i); int c = CY_GET_C(i); L->top = base + c + 1; luaV_concat(L, c - b + 1, c); setobjs2s(L, RA(i), base + b); break; }
            case CYOP_JMP: { pc += CY_GET_sBx(i); break; }
            case CYOP_EQ: { TValue *rb = RKB(i); TValue *rc = RKC(i); if (luaV_equalobj(L, rb, rc) != CY_GET_A(i)) pc++; break; }
            case CYOP_LT: { TValue *rb = RKB(i); TValue *rc = RKC(i); if (luaV_lessthan(L, rb, rc) != CY_GET_A(i)) pc++; break; }
            case CYOP_LE: { TValue *rb = RKB(i); TValue *rc = RKC(i); if (luaV_lessequal(L, rb, rc) != CY_GET_A(i)) pc++; break; }
            case CYOP_TEST: if (l_isfalse(RA(i)) != CY_GET_C(i)) pc++; break;
            case CYOP_TESTSET: if (l_isfalse(RB(i)) != CY_GET_C(i)) setobjs2s(L, RA(i), RB(i)); else pc++; break;
            case CYOP_CALL: { int b = CY_GET_B(i); int nresults = CY_GET_C(i) - 1; if (b != 0) L->top = RA(i) + b; if (luaD_precall(L, RA(i), nresults)) { if (nresults >= 0) L->top = L->ci->top; } else { luaV_execute(L); } break; }
            case CYOP_TAILCALL: { int b = CY_GET_B(i); if (b != 0) L->top = RA(i) + b; luaD_precall(L, RA(i), LUA_MULTRET); return cyluavm_interpreter(L); }
            case CYOP_RETURN: { int b = CY_GET_B(i); if (b != 0) L->top = RA(i) + b - 1; return (b == 0) ? -1 : b - 1; }
            case CYOP_FORPREP: { StkId ra = RA(i); if (ttisinteger(ra) && ttisinteger(ra+1) && ttisinteger(ra+2)) { ivalue(ra) -= ivalue(ra+2); } pc += CY_GET_sBx(i); break; }
            case CYOP_FORLOOP: { StkId ra = RA(i); if (ttisinteger(ra)) { lua_Integer step = ivalue(ra+2); lua_Integer idx = ivalue(ra) + step; lua_Integer limit = ivalue(ra+1); if ((step > 0) ? (idx <= limit) : (limit <= idx)) { pc += CY_GET_sBx(i); chgivalue(ra, idx); setobjs2s(L, ra+3, ra); } } break; }
            default: break;
        }
    }
}

static int cyluavm_dump(lua_State *L) {
    luaL_checktype(L, 1, LUA_TFUNCTION);
    if (lua_iscfunction(L, 1)) {
        CClosure *cl = (CClosure *)lua_topointer(L, 1);
        if (cl->f == cyluavm_interpreter) {
            lua_getupvalue(L, 1, 1);
            CYBytecode **pbc = (CYBytecode **)lua_touserdata(L, -1);
            if (pbc && *pbc) {
                CYBytecode *bc = *pbc;
                lua_pop(L, 1);
                luaL_Buffer b;
                luaL_buffinit(L, &b);
                int magic = CY_MAGIC;
                luaL_addlstring(&b, (const char *)&magic, sizeof(magic));
                luaL_addlstring(&b, (const char *)&bc->sizecode, sizeof(bc->sizecode));
                luaL_addlstring(&b, (const char *)bc->code, bc->sizecode * sizeof(Instruction));
                luaL_addlstring(&b, (const char *)&bc->numparams, sizeof(bc->numparams));
                luaL_addlstring(&b, (const char *)&bc->maxstacksize, sizeof(bc->maxstacksize));
                luaL_pushresult(&b);
                return 1;
            }
            lua_pop(L, 1);
        }
    }
    lua_getglobal(L, "CY_OLD_DUMP");
    lua_pushvalue(L, 1);
    lua_call(L, 1, 1);
    return 1;
}

static int cyluavm_load(lua_State *L) {
    size_t len;
    const char *s = luaL_checklstring(L, 1, &len);
    if (len >= sizeof(int) && *(const int *)s == CY_MAGIC) {
        const char *p = s;
        p += sizeof(int);
        int sizecode = *(const int *)p; p += sizeof(int);
        CYBytecode *bc = (CYBytecode *)luaM_malloc(L, sizeof(CYBytecode));
        bc->sizecode = sizecode;
        bc->code = (Instruction *)luaM_malloc(L, sizecode * sizeof(Instruction));
        memcpy(bc->code, p, sizecode * sizeof(Instruction));
        p += sizecode * sizeof(Instruction);
        bc->numparams = *(const int *)p; p += sizeof(int);
        bc->maxstacksize = *(const int *)p; p += sizeof(int);
        bc->sizek = 0; bc->k = NULL;
        CYBytecode **ubc = (CYBytecode **)lua_newuserdata(L, sizeof(CYBytecode *));
        *ubc = bc;
        lua_newtable(L);
        lua_pushcfunction(L, bc_gc);
        lua_setfield(L, -2, "__gc");
        lua_setmetatable(L, -2);
        lua_pushcclosure(L, cyluavm_interpreter, 1);
        return 1;
    }
    lua_getglobal(L, "CY_OLD_LOAD");
    lua_pushvalue(L, 1);
    lua_call(L, 1, 1);
    return 1;
}

int luaopen_CYLuaVM(lua_State *L) {
    luaL_Reg reg[] = { {"buildEntry", buildEntry}, {NULL, NULL} };
    luaL_newlib(L, reg);
    lua_getglobal(L, "string");
    lua_getfield(L, -1, "dump");
    lua_setglobal(L, "CY_OLD_DUMP");
    lua_pushcfunction(L, cyluavm_dump);
    lua_setfield(L, -2, "dump");
    lua_pop(L, 1);
    lua_getglobal(L, "load");
    lua_setglobal(L, "CY_OLD_LOAD");
    lua_pushcfunction(L, cyluavm_load);
    lua_setglobal(L, "load");
    return 1;
}
