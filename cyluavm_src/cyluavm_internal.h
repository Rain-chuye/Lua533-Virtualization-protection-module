#ifndef CYLUAVM_INTERNAL_H
#define CYLUAVM_INTERNAL_H

#include "lua.h"
#include "lobject.h"

typedef struct {
    Instruction *code;
    int sizecode;
    TValue *k;
    int sizek;
    int numparams;
    int is_vararg;
    int maxstacksize;
} CYBytecode;

#define CY_MAGIC 0x43594C56 // "CYLV"

#endif
