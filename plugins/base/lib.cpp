extern "C" {
	#include <stdint.h>
	#include <stdlib.h>
	#include <string.h>
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
		lua_pushnumber(L,1234+5);
		return 1;
	}

	extern int lib_nanosecond(lua_State *L) {
		struct timespec out;
		clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&out);
		uint64_t tme=(out.tv_sec*1000000)+out.tv_nsec;
		luaL_pushcdata(L,&tme,sizeof(tme),"uint64_t");
		return 1;
	}

	typedef struct {
		char* data;
		size_t sz;
	} writerdata;

	int writer(lua_State* L,const void* p,size_t sz,void* ud) {
		writerdata* ostr=(writerdata*)ud;
		ostr->data=(char*)realloc((void*)ostr->data,ostr->sz+sz);
		memcpy((void*)(ostr->data+ostr->sz),p,sz);
		ostr->sz+=sz;
		return 0;
	}

	extern int lib_fdump(lua_State *L) {
		writerdata ud;
		ud.data=NULL;
		ud.sz=0;
		lua_dump(L,writer,(void*)&ud);
		lua_pushlstring(L,ud.data,ud.sz);
		free(ud.data);
		return 1;
	}

}