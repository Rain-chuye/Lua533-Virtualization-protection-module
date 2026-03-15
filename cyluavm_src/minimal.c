#define LUA_CORE
#include "lua.h"
#include "lauxlib.h"
#include "lobject.h"
#include "lstate.h"

int luaopen_CYLuaVM(lua_State *L) {
    lua_newtable(L);
    return 1;
}
