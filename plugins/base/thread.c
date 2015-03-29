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
	printf("thread start\n");
	lua_pcall((lua_State*)L,lua_gettop(L)-1,0,0);
	printf("thread end\n");
	return NULL;
}
