#include <stdlib.h>
#include "luajit-2.1/luajit.h"
#include "luajit-2.1/lauxlib.h"

#include "derplib.h"

int main() {
	lua_State L=luaL_newstate();
	return luaL_dofile(L,"");
}
