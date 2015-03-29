#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <poll.h>
#include <string.h>
#include "lua.h"
#include "lauxlib.h"

int main() {
	printf("Init\n");
	const char* crash;
	while (1) {
		lua_State *L=luaL_newstate();
		if (crash) {
			lua_pushstring(L,crash);
			free((void*)crash);
			crash=0;
			lua_setglobal(L,"crash");
		}
		luaL_openlibs(L);
		if (luaL_dofile(L,"main.lua")!=0) {
			crash=strdup(lua_tolstring(L,-1,NULL));
			printf("crashed %s\n",crash);
			poll(NULL,0,10000);
		}
		lua_close(L);
	}
	return 0;
}