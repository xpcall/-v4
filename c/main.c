#include <stdlib.h>
#include <stdio.h>
#include "lua.h"
#include "lauxlib.h"

#include "util.h"

int main() {
	printf("derrrp\n");
	lua_State *L=luaL_newstate();
	//util_load(L);
	luaL_openlibs(L);
	if (luaL_dofile(L,"main.lua")!=0) {
		printf("bork %s\n",lua_tolstring(L,-1,NULL));
	}
	lua_close(L);
	return 0;
}

