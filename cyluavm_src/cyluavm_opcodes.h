#ifndef CYLUAVM_OPCODES_H
#define CYLUAVM_OPCODES_H

#define CYOP_MOVE 29
#define CYOP_LOADK 23
#define CYOP_LOADKX 24
#define CYOP_LOADBOOL 10
#define CYOP_LOADNIL 21
#define CYOP_GETUPVAL 9
#define CYOP_GETTABUP 30
#define CYOP_GETTABLE 38
#define CYOP_SETTABUP 12
#define CYOP_SETUPVAL 3
#define CYOP_SETTABLE 35
#define CYOP_NEWTABLE 4
#define CYOP_SELF 42
#define CYOP_ADD 26
#define CYOP_SUB 11
#define CYOP_MUL 33
#define CYOP_MOD 28
#define CYOP_POW 46
#define CYOP_DIV 18
#define CYOP_IDIV 31
#define CYOP_BAND 45
#define CYOP_BOR 32
#define CYOP_BXOR 36
#define CYOP_SHL 25
#define CYOP_SHR 20
#define CYOP_UNM 22
#define CYOP_BNOT 39
#define CYOP_NOT 43
#define CYOP_LEN 0
#define CYOP_CONCAT 19
#define CYOP_JMP 16
#define CYOP_EQ 41
#define CYOP_LT 13
#define CYOP_LE 37
#define CYOP_TEST 44
#define CYOP_TESTSET 2
#define CYOP_CALL 27
#define CYOP_TAILCALL 5
#define CYOP_RETURN 34
#define CYOP_FORLOOP 6
#define CYOP_FORPREP 8
#define CYOP_TFORCALL 14
#define CYOP_TFORLOOP 15
#define CYOP_SETLIST 17
#define CYOP_CLOSURE 1
#define CYOP_VARARG 7
#define CYOP_EXTRAARG 40

#endif
