do return end
local libdl=ffi.load("dl")
ffi.cdef[[
	void *dlopen(const char*,int);
	char *dlerror(void);
	void *dlsym(void*,const char*);
	int dlclose(void*);
]]
local dleris=libdl.dlopen("./liberis.so",1337)
if dleris==nil then
	local err=libdl.dlerror()
	if err==nil then
		error("unknown error loading eris")
	else
		error(ffi.string(err))
	end
end

ffi.cdef[[
typedef struct eris_State eris_State;
typedef int (*eris_CFunction) (eris_State *L);
typedef const char * (*eris_Reader) (eris_State *L, void *ud, size_t *sz);
typedef int (*eris_Writer) (eris_State *L, const void* p, size_t sz, void* ud);
typedef void * (*eris_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);
typedef struct eris_Debug eris_Debug;
typedef void (*eris_Hook) (eris_State *L, eris_Debug *ar);

struct eris_Debug {
	int event;
	const char *name;
	const char *namewhat;
	const char *what;
	const char *source;
	int currentline;
	int linedefined;
	int lastlinedefined;
	unsigned char nups;
	unsigned char nparams;
	char isvararg;
	char istailcall;
	char short_src[60];
	struct CallInfo *i_ci;
};

typedef struct erisL_Reg {
  const char *name;
  eris_CFunction func;
} erisL_Reg;
]]

local erissymbols={
	["lua_newstate"]="eris_State* (*)(eris_Alloc f, void *ud)",
	["lua_close"]="void (*)(eris_State *L)",
	["lua_newthread"]="eris_State* (*)(eris_State *L)",
	["lua_atpanic"]="eris_CFunction (*)(eris_State *L, eris_CFunction panicf)",
	["lua_version"]="eris_Number* (*)(eris_State *L)",
	["lua_absindex"]="int (*)(eris_State *L, int idx)",
	["lua_gettop"]="int (*)(eris_State *L)",
	["lua_settop"]="void (*)(eris_State *L, int idx)",
	["lua_pushvalue"]="void (*)(eris_State *L, int idx)",
	["lua_remove"]="void (*)(eris_State *L, int idx)",
	["lua_insert"]="void (*)(eris_State *L, int idx)",
	["lua_replace"]="void (*)(eris_State *L, int idx)",
	["lua_copy"]="void (*)(eris_State *L, int fromidx, int toidx)",
	["lua_checkstack"]="int (*)(eris_State *L, int sz)",
	["lua_xmove"]="void (*)(eris_State *from, eris_State *to, int n)",
	["lua_isnumber"]="int (*)(eris_State *L, int idx)",
	["lua_isstring"]="int (*)(eris_State *L, int idx)",
	["lua_iscfunction"]="int (*)(eris_State *L, int idx)",
	["lua_isuserdata"]="int (*)(eris_State *L, int idx)",
	["lua_type"]="int (*)(eris_State *L, int idx)",
	["lua_typename"]="const char* (*)(eris_State *L, int tp)",
	["lua_tonumberx"]="eris_Number (*)(eris_State *L, int idx, int *isnum)",
	["lua_tointegerx"]="eris_Integer (*)(eris_State *L, int idx, int *isnum)",
	["lua_tounsignedx"]="eris_Unsigned (*)(eris_State *L, int idx, int *isnum)",
	["lua_toboolean"]="int (*)(eris_State *L, int idx)",
	["lua_tolstring"]="const char* (*)(eris_State *L, int idx, size_t *len)",
	["lua_rawlen"]="size_t (*)(eris_State *L, int idx)",
	["lua_tocfunction"]="eris_CFunction (*)(eris_State *L, int idx)",
	["lua_touserdata"]="void* (*)(eris_State *L, int idx)",
	["lua_tothread"]="eris_State* (*)(eris_State *L, int idx)",
	["lua_topointer"]="const void* (*)(eris_State *L, int idx)",
	["lua_pushnil"]="void (*)(eris_State *L)",
	["lua_pushnumber"]="void (*)(eris_State *L, eris_Number n)",
	["lua_pushinteger"]="void (*)(eris_State *L, eris_Integer n)",
	["lua_pushunsigned"]="void (*)(eris_State *L, eris_Unsigned n)",
	["lua_pushlstring"]="const char* (*)(eris_State *L, const char *s, size_t l)",
	["lua_pushstring"]="const char* (*)(eris_State *L, const char *s)",
	["lua_pushvfstring"]="const char* (*)(eris_State *L, const char *fmt, va_list argp)",
	["lua_pushfstring"]="const char* (*)(eris_State *L, const char *fmt, ...)",
	["lua_pushcclosure"]="void (*)(eris_State *L, eris_CFunction fn, int n)",
	["lua_pushboolean"]="void (*)(eris_State *L, int b)",
	["lua_pushlightuserdata"]="void (*)(eris_State *L, void *p)",
	["lua_pushthread"]="int (*)(eris_State *L)",
	["lua_getglobal"]="void (*)(eris_State *L, const char *var)",
	["lua_gettable"]="void (*)(eris_State *L, int idx)",
	["lua_getfield"]="void (*)(eris_State *L, int idx, const char *k)",
	["lua_rawget"]="void (*)(eris_State *L, int idx)",
	["lua_rawgeti"]="void (*)(eris_State *L, int idx, int n)",
	["lua_rawgetp"]="void (*)(eris_State *L, int idx, const void *p)",
	["lua_createtable"]="void (*)(eris_State *L, int narr, int nrec)",
	["lua_newuserdata"]="void* (*)(eris_State *L, size_t sz)",
	["lua_getmetatable"]="int (*)(eris_State *L, int objindex)",
	["lua_getuservalue"]="void (*)(eris_State *L, int idx)",
	["lua_setglobal"]="void (*)(eris_State *L, const char *var)",
	["lua_settable"]="void (*)(eris_State *L, int idx)",
	["lua_setfield"]="void (*)(eris_State *L, int idx, const char *k)",
	["lua_rawset"]="void (*)(eris_State *L, int idx)",
	["lua_rawseti"]="void (*)(eris_State *L, int idx, int n)",
	["lua_rawsetp"]="void (*)(eris_State *L, int idx, const void *p)",
	["lua_setmetatable"]="int (*)(eris_State *L, int objindex)",
	["lua_setuservalue"]="void (*)(eris_State *L, int idx)",
	["lua_callk"]="void (*)(eris_State *L, int nargs, int nresults, int ctx, eris_CFunction k)",
	["lua_getctx"]="int (*)(eris_State *L, int *ctx)",
	["lua_pcallk"]="int (*)(eris_State *L, int nargs, int nresults, int errfunc, int ctx, eris_CFunction k)",
	["lua_load"]="int (*)(eris_State *L, eris_Reader reader, void *dt, const char *chunkname, const char *mode)",
	["lua_dump"]="int (*)(eris_State *L, eris_Writer writer, void *data)",
	["lua_yieldk"]="int (*)(eris_State *L, int nresults, int ctx, eris_CFunction k)",
	["lua_resume"]="int (*)(eris_State *L, eris_State *from, int narg)",
	["lua_status"]="int (*)(eris_State *L)",
	["lua_gc"]="int (*)(eris_State *L, int what, int data)",
	["lua_error"]="int (*)(eris_State *L)",
	["lua_next"]="int (*)(eris_State *L, int idx)",
	["lua_concat"]="void (*)(eris_State *L, int n)",
	["lua_len"]="void (*)(eris_State *L, int idx)",
	["lua_getallocf"]="eris_Alloc (*)(eris_State *L, void **ud)",
	["lua_setallocf"]="void (*)(eris_State *L, eris_Alloc f, void *ud)",
	["lua_getstack"]="int (*)(eris_State *L, int level, eris_Debug *ar)",
	["lua_getinfo"]="int (*)(eris_State *L, const char *what, eris_Debug *ar)",
	["lua_getlocal"]="const char* (*)(eris_State *L, const eris_Debug *ar, int n)",
	["lua_setlocal"]="const char* (*)(eris_State *L, const eris_Debug *ar, int n)",
	["lua_getupvalue"]="const char* (*)(eris_State *L, int funcindex, int n)",
	["lua_setupvalue"]="const char* (*)(eris_State *L, int funcindex, int n)",
	["lua_upvalueid"]="void* (*)(eris_State *L, int fidx, int n)",
	["lua_upvaluejoin"]="void (*)(eris_State *L, int fidx1, int n1, int fidx2, int n2)",
	["lua_sethook"]="int (*)(eris_State *L, eris_Hook func, int mask, int count)",
	["lua_gethook"]="eris_Hook (*)(eris_State *L)",
	["lua_gethookmask"]="int (*)(eris_State *L)",
	["lua_gethookcount"]="int (*)(eris_State *L)",
}

