import random

opcodes = [
    "MOVE", "LOADK", "LOADKX", "LOADBOOL", "LOADNIL", "GETUPVAL",
    "GETTABUP", "GETTABLE", "SETTABUP", "SETUPVAL", "SETTABLE",
    "NEWTABLE", "SELF", "ADD", "SUB", "MUL", "MOD", "POW", "DIV",
    "IDIV", "BAND", "BOR", "BXOR", "SHL", "SHR", "UNM", "BNOT",
    "NOT", "LEN", "CONCAT", "JMP", "EQ", "LT", "LE", "TEST",
    "TESTSET", "CALL", "TAILCALL", "RETURN", "FORLOOP", "FORPREP",
    "TFORCALL", "TFORLOOP", "SETLIST", "CLOSURE", "VARARG", "EXTRAARG"
]

indices = list(range(len(opcodes)))
random.seed(42) # Fixed seed for reproducibility
random.shuffle(indices)

mapping = {i: indices[i] for i in range(len(opcodes))}
reverse_mapping = {indices[i]: i for i in range(len(opcodes))}

print("#ifndef CYLUAVM_OPCODES_H")
print("#define CYLUAVM_OPCODES_H\n")

for i, op in enumerate(opcodes):
    print(f"#define CYOP_{op} {indices[i]}")

print("\n#endif")

# Also generate the C arrays for mapping
with open("mapping_data.c", "w") as f:
    f.write("static const int lua_to_cy[] = {\n")
    for i in range(len(opcodes)):
        f.write(f"    {indices[i]}, // OP_{opcodes[i]}\n")
    f.write("};\n\n")

    f.write("static const int cy_to_lua[] = {\n")
    for i in range(len(opcodes)):
        f.write(f"    {reverse_mapping[i]}, // CYOP_{opcodes[reverse_mapping[i]]}\n")
    f.write("};\n")
