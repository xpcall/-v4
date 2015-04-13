#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <poll.h>
#include <string.h>
#include <pthread.h>
#include <errno.h>
#include "lua.h"
#include "lauxlib.h"
#include "ljitauxlib.h"

extern void* lthread_callback(void* L) {
	printf("[thread] start\n");
	int res=lua_pcall((lua_State*)L,lua_gettop(L)-1,0,0);
	if (res==LUA_ERRRUN) {
		printf("[thread] error %s\n",luaL_checkstring(L,-1));
	} else if (res==LUA_ERRMEM) {
		printf("[thread] errmem\n");
	} else if (res==LUA_ERRERR) {
		printf("[thread] errerr\n");
	}
	printf("[thread] end\n");
	return NULL;
}
