#ifndef _LJITAUXLIB_H
#define _LJITAUXLIB_H

#include "lua.h"

void* luaL_pushtcdata(lua_State *L,void* data,size_t size,int type);
void* luaL_pushcdata(lua_State *L,void* data,size_t size,const char* type);
void luaL_pushpointer(lua_State *L,void* ptr);
int luaL_iscdata(lua_State *L,int narg);
void* luaL_checklcdata(lua_State *L,int narg,size_t* size);
int luaL_checkctype(lua_State *L,int narg);
void* luaL_checkpointer(lua_State *L,int narg);

#endif
