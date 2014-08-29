#include <stdlib.h>
#include "lua.h"
#include "lauxlib.h"

static int getstate(lua_State *L) {
	char out[16];
	snprintf(out,16,"%llu",(unsigned long long)L);
	lua_pushstring(L,out);
	return 1;
}

static const luaL_Reg R[]={
	{"getstate",getstate},
	{NULL,NULL}
};

int luaopen_derp(lua_State *L) {
 luaL_newmetatable(L,"derp");
 luaL_register(L,NULL,R);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 return 1;
}

