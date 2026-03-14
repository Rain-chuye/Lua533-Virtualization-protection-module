LUA_DIR = ../lua_src/src
LUA_LIB = $(LUA_DIR)/liblua.a
CC = gcc
CFLAGS = -I$(LUA_DIR) -O3 -fPIC -Wall -Wextra

CYLUAVM_SO = cyluavm.so

all: $(CYLUAVM_SO)

$(CYLUAVM_SO): cyluavm.c
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LUA_LIB) -lm -ldl

clean:
	rm -f $(CYLUAVM_SO)
