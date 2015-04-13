#include <math.h>
#include <time.h>
#include "lua.h"
#include "lauxlib.h"
#include "ljitauxlib.h"

extern int lib_udataptr(lua_State* L) {
	luaL_pushpointer(L,lua_touserdata(L,1));
	return 1;
}

extern int lib_dump(lua_State* L) {
	size_t size;
	void* data=luaL_checklcdata(L,1,&size);
	lua_pushlstring(L,(const char*)data,size);
	return 1;
}

extern int lib_udump(lua_State* L) {
	const char* tp=luaL_checkstring(L,1);
	size_t size;
	const char* data=luaL_checklstring(L,2,&size);
	luaL_pushcdata(L,(void*)data,size,tp);
	return 1;
}

extern int lib_test(lua_State *L) {
	lua_pushboolean(L,signbit(luaL_checknumber(L,1)));
	return 1;
}

extern int lib_nanosecond(lua_State *L) {
	struct timespec out;
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&out);
	lua_pushnumber(L,out.tv_sec+(out.tv_nsec/1000000.0));
	return 1;
}

