#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "lua.h"
#include "lauxlib.h"
#include "ljitauxlib.h"

int absidx(lua_State *L,int idx) {
	if (idx<0) {
		return lua_gettop(L)+1-idx;
	}
	return idx;
}
#define max(a,b) (a>b?a:b)
#define min(a,b) (a<b?a:b)

typedef struct {
	size_t x;
	size_t y;
	size_t width;
	size_t height;
	char* value;
	luaL_Buffer* buffer;
} frame;

typedef struct {
	int size;
	frame* list;
} frames;

frame newFrame(frames fs) {
	fs.size++;
	fs.list=realloc(fs.list,sizeof(frame)*fs.size);
	memset((void*)&fs.list[fs.size-1],0,sizeof(frame));
	return fs.list[fs.size-1];
}

void catFrames(frames a,frames b) {
	a.size+=b.size;
	a.list=realloc(a.list,sizeof(frame)*a.size);
	memcpy((void*)&a.list[a.size],(void*)b.list,sizeof(frame)*b.size);
}

void _cserialize(lua_State* L,int idx,frame f,frames fs) {
	if (lua_isnoneornil(L,idx)) {
		f.width=3;
		f.height=1;
		f.value="nil";
	} else if (lua_isboolean(L,idx)) {
		f.height=1;
		if (lua_toboolean(L,idx)) {
			f.width=4;
			f.value="true";
		} else {
			f.width=5;
			f.value="false";
		}
	} else if (lua_isnumber(L,idx)) {
		f.height=1;
		lua_Number v=lua_tonumber(L,idx);
		if (isnan(v)) {
			if (signbit(v)) {
				f.width=4;
				f.value="-nan";
			} else {
				f.width=3;
				f.value="nan";
			}
		} else if (v==0&&signbit(v)) {
			f.width=2;
			f.value="-0";
		}
	} else if (lua_isstring(L,idx)) {
		luaL_buffinit(L,f.buffer);
		size_t l;
		const char *v=lua_tolstring(L,idx,&l);
		f.width=2;
		luaL_addchar(f.buffer,'"');
		while (l--) {
			switch (*v) {
				case '"': case '\\': {
					f.width+=2;
					luaL_addchar(f.buffer,'\\');
					luaL_addchar(f.buffer,*v);
					break;
				}
				case '\r': {
					f.width+=2;
					luaL_addlstring(f.buffer,"\\r",2);
					break;
				}
				case '\n': {
					f.width+=2;
					luaL_addlstring(f.buffer,"\\n",2);
					break;
				}
				case '\0': {
					f.width+=4;
					luaL_addlstring(f.buffer,"\\000",4);
					break;
				}
				default: {
					f.width++;
					luaL_addchar(f.buffer,*v);
					break;
				}
			}
			v++;
		}
		luaL_addchar(f.buffer,'"');
	} else if (lua_istable(L,idx)) {
		f.height=2;
		size_t kw=0;
		size_t vw=0;
		frames keys;
		frames values;
		lua_pushnil(L);
		size_t cy=1;
		while (lua_next(L,idx)!=0) {
			frame k=newFrame(keys);
			k.y=cy;
			k.x=f.x;
			_cserialize(L,absidx(L,-2),k,fs);
			frame v=newFrame(values);
			v.y=cy;
			v.x=f.x;
			_cserialize(L,absidx(L,-1),v,values);
			cy+=max(k.height,v.height);
			lua_pop(L,1);
		}
		f.height=cy+1;
		for (int i=1;i<keys.size;i++) {
			frame c=keys.list[i];
			kw=max(kw,c.width);
		}
		for (int i=1;i<values.size;i++) {
			frame c=values.list[i];
			vw=max(vw,c.width);
			c.x+=kw+3;
		}
		f.width=kw+vw+3;
		catFrames(fs,keys);
		catFrames(fs,values);
	} else {
		f.value=(char*)lua_tolstring(L,idx,&f.width);
	}
}

extern int cserialize(lua_State* L) {
	frames fs;
	frame f=newFrame(fs);
	_cserialize(L,1,f,fs);
	char* out=malloc(f.width*f.height);
	memset(out,*" ",f.width*f.height);
	for (int i=0;i<fs.size;i++) {
		frame c=fs.list[i];
		char* cout=out+c.x+(c.y*f.width);
		if (c.buffer) {
			luaL_pushresult(c.buffer);
			c.value=(char*)lua_tostring(L,-1);
			memcpy((void*)cout,(void*)c.value,c.width);
			lua_pop(L,1);
		} else if (c.value) {
			memcpy(cout,c.value,c.width);
			free((void*)c.value);
		} else {
			cout[0]=*"/";
			memset(cout+1,*"=",c.width-2);
			cout[c.width-1]=*"\\";
			for (int i=1;i<(c.height-2);i++) {
				cout[f.width*i]=*"|";
				cout[(f.width*i)+(c.width-1)]=*"|";
			}
			cout[f.width*(c.height-1)]=*"\\";
			memset(cout+1,*"=",c.width-2);
		}
	}
	lua_pushlstring(L,out,f.width*f.height);
	free((void*)out);
	return 1;
}

