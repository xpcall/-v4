#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <errno.h>
#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "ljitauxlib.h"

void passert(lua_State* L,int res) {
	if (res==-1) {
		luaL_error(L,"%s",strerror(errno));
	}
}

extern int pipe_new(lua_State* L) {
	int pipes[2];
	passert(L,pipe(pipes));
	passert(L,fcntl(pipes[0],F_SETFL,O_NONBLOCK|O_RDONLY));
	lua_pushnumber(L,pipes[0]);
	lua_pushnumber(L,pipes[1]);
	return 2;
}

extern int pipe_close(lua_State* L) {
	passert(L,close(luaL_checkinteger(L,1)));
	return 0;
}

extern int pipe_read(lua_State* L) {
	int fd=luaL_checkinteger(L,1);
	int block=lua_toboolean(L,2);
	char buffer[64];
	luaL_Buffer lbuffer;
	luaL_buffinit(L,&lbuffer);
	int w=0;
	while (1) {
		ssize_t rs=read(fd,buffer,sizeof(buffer));
		if (rs==-1) {
			if (errno==EAGAIN) {
				if (w || !block) {
					break;
				}
				fcntl(fd,F_SETFL,O_RDONLY);
				passert(L,read(fd,NULL,0));
				fcntl(fd,F_SETFL,O_NONBLOCK|O_RDONLY);
			} else {
				passert(L,rs);
			}
		} else {
			w=1;
			luaL_addlstring(&lbuffer,buffer,rs);
		}
	}
	luaL_pushresult(&lbuffer);
	return 1;
}

extern int pipe_write(lua_State* L) {
	int fd=luaL_checkinteger(L,1);
	int block=lua_toboolean(L,2);
	if (block) {
		fcntl(fd,F_SETFL,O_WRONLY);
	} else {
		fcntl(fd,F_SETFL,O_NONBLOCK|O_WRONLY);
	}
	size_t len;
	const char* data=luaL_checklstring(L,2,&len);
	ssize_t rs=write(fd,data,len);
	if (rs==-1) {
		if (errno==EAGAIN) {
			lua_pushnumber(L,0);
			return 1;
		}
		passert(L,rs);
	}
	lua_pushnumber(L,rs);
	return 1;
}

extern int pipe_test(lua_State* L) {
	lua_pushnumber(L,F_SETFL);
	lua_pushnumber(L,O_RDONLY);
	lua_pushnumber(L,O_WRONLY);
	lua_pushnumber(L,O_NONBLOCK);
	lua_pushnumber(L,EAGAIN);
	return 5;
}

