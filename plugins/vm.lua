local head=[[
typedef struct lua_State lua_State;

typedef int (*lua_CFunction) (lua_State *L);

typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);

typedef int (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);

typedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);

typedef double lua_Number;

typedef ptrdiff_t lua_Integer;

lua_State *(lua_newstate) (lua_Alloc f, void *ud);
void       (lua_close) (lua_State *L);
lua_State *(lua_newthread) (lua_State *L);

lua_CFunction (lua_atpanic) (lua_State *L, lua_CFunction panicf);

int   (lua_gettop) (lua_State *L);
void  (lua_settop) (lua_State *L, int idx);
void  (lua_pushvalue) (lua_State *L, int idx);
void  (lua_remove) (lua_State *L, int idx);
void  (lua_insert) (lua_State *L, int idx);
void  (lua_replace) (lua_State *L, int idx);
int   (lua_checkstack) (lua_State *L, int sz);

void  (lua_xmove) (lua_State *from, lua_State *to, int n);

int             (lua_isnumber) (lua_State *L, int idx);
int             (lua_isstring) (lua_State *L, int idx);
int             (lua_iscfunction) (lua_State *L, int idx);
int             (lua_isuserdata) (lua_State *L, int idx);
int             (lua_type) (lua_State *L, int idx);
const char     *(lua_typename) (lua_State *L, int tp);

int            (lua_equal) (lua_State *L, int idx1, int idx2);
int            (lua_rawequal) (lua_State *L, int idx1, int idx2);
int            (lua_lessthan) (lua_State *L, int idx1, int idx2);

lua_Number      (lua_tonumber) (lua_State *L, int idx);
lua_Integer     (lua_tointeger) (lua_State *L, int idx);
int             (lua_toboolean) (lua_State *L, int idx);
const char     *(lua_tolstring) (lua_State *L, int idx, size_t *len);
size_t          (lua_objlen) (lua_State *L, int idx);
lua_CFunction   (lua_tocfunction) (lua_State *L, int idx);
void           *(lua_touserdata) (lua_State *L, int idx);
lua_State      *(lua_tothread) (lua_State *L, int idx);
const void     *(lua_topointer) (lua_State *L, int idx);

void  (lua_pushnil) (lua_State *L);
void  (lua_pushnumber) (lua_State *L, lua_Number n);
void  (lua_pushinteger) (lua_State *L, lua_Integer n);
void  (lua_pushlstring) (lua_State *L, const char *s, size_t l);
void  (lua_pushstring) (lua_State *L, const char *s);
const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
                                                      va_list argp);
const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
void  (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int n);
void  (lua_pushboolean) (lua_State *L, int b);
void  (lua_pushlightuserdata) (lua_State *L, void *p);
int   (lua_pushthread) (lua_State *L);

void  (lua_gettable) (lua_State *L, int idx);
void  (lua_getfield) (lua_State *L, int idx, const char *k);
void  (lua_rawget) (lua_State *L, int idx);
void  (lua_rawgeti) (lua_State *L, int idx, int n);
void  (lua_createtable) (lua_State *L, int narr, int nrec);
void *(lua_newuserdata) (lua_State *L, size_t sz);
int   (lua_getmetatable) (lua_State *L, int objindex);
void  (lua_getfenv) (lua_State *L, int idx);

void  (lua_settable) (lua_State *L, int idx);
void  (lua_setfield) (lua_State *L, int idx, const char *k);
void  (lua_rawset) (lua_State *L, int idx);
void  (lua_rawseti) (lua_State *L, int idx, int n);
int   (lua_setmetatable) (lua_State *L, int objindex);
int   (lua_setfenv) (lua_State *L, int idx);

void  (lua_call) (lua_State *L, int nargs, int nresults);
int   (lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
int   (lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);
int   (lua_load) (lua_State *L, lua_Reader reader, void *dt,
                                        const char *chunkname);

int (lua_dump) (lua_State *L, lua_Writer writer, void *data);

int  (lua_yield) (lua_State *L, int nresults);
int  (lua_resume) (lua_State *L, int narg);
int  (lua_status) (lua_State *L);

int (lua_gc) (lua_State *L, int what, int data);

int   (lua_error) (lua_State *L);

int   (lua_next) (lua_State *L, int idx);

void  (lua_concat) (lua_State *L, int n);

lua_Alloc (lua_getallocf) (lua_State *L, void **ud);
void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);

typedef struct lua_Debug lua_Debug;  /* activation record */


/* Functions to be called by the debuger in specific events */
typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);

int lua_getstack (lua_State *L, int level, lua_Debug *ar);
int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_getupvalue (lua_State *L, int funcindex, int n);
const char *lua_setupvalue (lua_State *L, int funcindex, int n);

int lua_sethook (lua_State *L, lua_Hook func, int mask, int count);
lua_Hook lua_gethook (lua_State *L);
int lua_gethookmask (lua_State *L);
int lua_gethookcount (lua_State *L);

struct lua_Debug {
  int event;
  const char *name;     /* (n) */
  const char *namewhat; /* (n) `global', `local', `field', `method' */
  const char *what;     /* (S) `Lua', `C', `main', `tail' */
  const char *source;   /* (S) */
  int currentline;      /* (l) */
  int nups;             /* (u) number of upvalues */
  int linedefined;      /* (S) */
  int lastlinedefined;  /* (S) */
  char short_src[60]; /* (S) */
  /* private part */
  int i_ci;  /* active function */
};

typedef struct luaL_Reg {
  const char *name;
  lua_CFunction func;
} luaL_Reg;

void (luaI_openlib) (lua_State *L, const char *libname,
                                const luaL_Reg *l, int nup);
void (luaL_register) (lua_State *L, const char *libname,
                                const luaL_Reg *l);
int (luaL_getmetafield) (lua_State *L, int obj, const char *e);
int (luaL_callmeta) (lua_State *L, int obj, const char *e);
int (luaL_typerror) (lua_State *L, int narg, const char *tname);
int (luaL_argerror) (lua_State *L, int numarg, const char *extramsg);
const char *(luaL_checklstring) (lua_State *L, int numArg,
                                                          size_t *l);
const char *(luaL_optlstring) (lua_State *L, int numArg,
                                          const char *def, size_t *l);
lua_Number (luaL_checknumber) (lua_State *L, int numArg);
lua_Number (luaL_optnumber) (lua_State *L, int nArg, lua_Number def);

lua_Integer (luaL_checkinteger) (lua_State *L, int numArg);
lua_Integer (luaL_optinteger) (lua_State *L, int nArg,
                                          lua_Integer def);

void (luaL_checkstack) (lua_State *L, int sz, const char *msg);
void (luaL_checktype) (lua_State *L, int narg, int t);
void (luaL_checkany) (lua_State *L, int narg);

int   (luaL_newmetatable) (lua_State *L, const char *tname);
void *(luaL_checkudata) (lua_State *L, int ud, const char *tname);

void (luaL_where) (lua_State *L, int lvl);
int (luaL_error) (lua_State *L, const char *fmt, ...);

int (luaL_checkoption) (lua_State *L, int narg, const char *def,
                                   const char *const lst[]);

int (luaL_ref) (lua_State *L, int t);
void (luaL_unref) (lua_State *L, int t, int ref);

int (luaL_loadfile) (lua_State *L, const char *filename);
int (luaL_loadbuffer) (lua_State *L, const char *buff, size_t sz,
                                  const char *name);
int (luaL_loadstring) (lua_State *L, const char *s);

lua_State *(luaL_newstate) (void);


const char *(luaL_gsub) (lua_State *L, const char *s, const char *p,
                                                  const char *r);

const char *(luaL_findtable) (lua_State *L, int idx,
                                         const char *fname, int szhint);

typedef struct luaL_Buffer {
  char *p;                      /* current position in buffer */
  int lvl;  /* number of strings in the stack (level) */
  lua_State *L;
  char buffer[32];
} luaL_Buffer;

void (luaL_buffinit) (lua_State *L, luaL_Buffer *B);
char *(luaL_prepbuffer) (luaL_Buffer *B);
void (luaL_addlstring) (luaL_Buffer *B, const char *s, size_t l);
void (luaL_addstring) (luaL_Buffer *B, const char *s);
void (luaL_addvalue) (luaL_Buffer *B);
void (luaL_pushresult) (luaL_Buffer *B);

int (luaopen_base) (lua_State *L);
int (luaopen_table) (lua_State *L);
int (luaopen_io) (lua_State *L);
int (luaopen_os) (lua_State *L);
int (luaopen_string) (lua_State *L);
int (luaopen_math) (lua_State *L);
int (luaopen_debug) (lua_State *L);
int (luaopen_package) (lua_State *L);
int (luaopen_package) (lua_State *L);
void (luaL_openlibs) (lua_State *L); 
]]
local threadhead=[[
union pthread_attr_t
{
  char __size[56];
  long int __align;
};
typedef union pthread_attr_t pthread_attr_t;


typedef struct __pthread_internal_slist
{
  struct __pthread_internal_slist *__next;
} __pthread_slist_t;


/* Data structures for mutex handling.  The structure of the attribute
   type is not exposed on purpose.  */
typedef union
{
  struct __pthread_mutex_s
  {
    int __lock;
    unsigned int __count;
    int __owner;
    unsigned int __nusers;
    __extension__ union
    {
      struct
      {
	short __espins;
	short __elision;
      } d;
      __pthread_slist_t __list;
    };
  } __data;
  char __size[40];
  long int __align;
} pthread_mutex_t;

typedef union
{
  char __size[4];
  int __align;
} pthread_mutexattr_t;


/* Data structure for conditional variable handling.  The structure of
   the attribute type is not exposed on purpose.  */
typedef union
{
  struct
  {
    int __lock;
    unsigned int __futex;
    __extension__ unsigned long long int __total_seq;
    __extension__ unsigned long long int __wakeup_seq;
    __extension__ unsigned long long int __woken_seq;
    void *__mutex;
    unsigned int __nwaiters;
    unsigned int __broadcast_seq;
  } __data;
  char __size[48];
  __extension__ long long int __align;
} pthread_cond_t;

typedef union
{
  char __size[4];
  int __align;
} pthread_condattr_t;


/* Keys for thread-specific data */
typedef unsigned int pthread_key_t;


/* Once-only execution */
typedef int pthread_once_t;


/* Data structure for read-write lock variable handling.  The
   structure of the attribute type is not exposed on purpose.  */
typedef union
{
  struct
  {
    int __lock;
    unsigned int __nr_readers;
    unsigned int __readers_wakeup;
    unsigned int __writer_wakeup;
    unsigned int __nr_readers_queued;
    unsigned int __nr_writers_queued;
    /* FLAGS must stay at this position in the structure to maintain
       binary compatibility.  */
    unsigned char __flags;
    unsigned char __shared;
    unsigned char __pad1;
    unsigned char __pad2;
    int __writer;
  } __data;
  char __size[56];
  long int __align;
} pthread_rwlock_t;

typedef union
{
  char __size[8];
  long int __align;
} pthread_rwlockattr_t;

typedef volatile int pthread_spinlock_t;

typedef union
{
  char __size[32];
  long int __align;
} pthread_barrier_t;

typedef union
{
  char __size[8];
  int __align;
} pthread_barrierattr_t;

typedef unsigned long int pthread_t;

int   pthread_attr_destroy(pthread_attr_t *);
int   pthread_attr_getdetachstate(const pthread_attr_t *, int *);
int   pthread_attr_getguardsize(const pthread_attr_t *, size_t *);
int   pthread_attr_getinheritsched(const pthread_attr_t *, int *);
int   pthread_attr_getschedparam(const pthread_attr_t *, struct sched_param *);
int   pthread_attr_getschedpolicy(const pthread_attr_t *, int *);
int   pthread_attr_getscope(const pthread_attr_t *, int *);
int   pthread_attr_getstackaddr(const pthread_attr_t *, void **);
int   pthread_attr_getstacksize(const pthread_attr_t *, size_t *);
int   pthread_attr_init(pthread_attr_t *);
int   pthread_attr_setdetachstate(pthread_attr_t *, int);
int   pthread_attr_setguardsize(pthread_attr_t *, size_t);
int   pthread_attr_setinheritsched(pthread_attr_t *, int);
int   pthread_attr_setschedparam(pthread_attr_t *, const struct sched_param *);
int   pthread_attr_setschedpolicy(pthread_attr_t *, int);
int   pthread_attr_setscope(pthread_attr_t *, int);
int   pthread_attr_setstackaddr(pthread_attr_t *, void *);
int   pthread_attr_setstacksize(pthread_attr_t *, size_t);
int   pthread_cancel(pthread_t *);
int   pthread_cond_broadcast(pthread_cond_t *);
int   pthread_cond_destroy(pthread_cond_t *);
int   pthread_cond_init(pthread_cond_t *, const pthread_condattr_t *);
int   pthread_cond_signal(pthread_cond_t *);
int   pthread_cond_timedwait(pthread_cond_t *, pthread_mutex_t *, const struct timespec *);
int   pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *);
int   pthread_condattr_destroy(pthread_condattr_t *);
int   pthread_condattr_getpshared(const pthread_condattr_t *, int *);
int   pthread_condattr_init(pthread_condattr_t *);
int   pthread_condattr_setpshared(pthread_condattr_t *, int);
int   pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
int   pthread_detach(pthread_t);
int   pthread_equal(pthread_t, pthread_t);
void  pthread_exit(void *);
int   pthread_kill(pthread_t, int sig);
int   pthread_getconcurrency(void);
int   pthread_getschedparam(pthread_t, int *, struct sched_param *);
void *pthread_getspecific(pthread_key_t);
int   pthread_join(pthread_t, void **);
int   pthread_key_create(pthread_key_t *, void (*)(void *));
int   pthread_key_delete(pthread_key_t);
int   pthread_mutex_destroy(pthread_mutex_t *);
int   pthread_mutex_getprioceiling(const pthread_mutex_t *, int *);
int   pthread_mutex_init(pthread_mutex_t *, const pthread_mutexattr_t *);
int   pthread_mutex_lock(pthread_mutex_t *);
int   pthread_mutex_setprioceiling(pthread_mutex_t *, int, int *);
int   pthread_mutex_trylock(pthread_mutex_t *);
int   pthread_mutex_unlock(pthread_mutex_t *);
int   pthread_mutexattr_destroy(pthread_mutexattr_t *);
int   pthread_mutexattr_getprioceiling(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_getprotocol(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_getpshared(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_gettype(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_init(pthread_mutexattr_t *);
int   pthread_mutexattr_setprioceiling(pthread_mutexattr_t *, int);
int   pthread_mutexattr_setprotocol(pthread_mutexattr_t *, int);
int   pthread_mutexattr_setpshared(pthread_mutexattr_t *, int);
int   pthread_mutexattr_settype(pthread_mutexattr_t *, int);
int   pthread_once(pthread_once_t *, void (*)(void));
int   pthread_rwlock_destroy(pthread_rwlock_t *);
int   pthread_rwlock_init(pthread_rwlock_t *, const pthread_rwlockattr_t *);
int   pthread_rwlock_rdlock(pthread_rwlock_t *);
int   pthread_rwlock_tryrdlock(pthread_rwlock_t *);
int   pthread_rwlock_trywrlock(pthread_rwlock_t *);
int   pthread_rwlock_unlock(pthread_rwlock_t *);
int   pthread_rwlock_wrlock(pthread_rwlock_t *);
int   pthread_rwlockattr_destroy(pthread_rwlockattr_t *);
int   pthread_rwlockattr_getpshared(const pthread_rwlockattr_t *, int *);
int   pthread_rwlockattr_init(pthread_rwlockattr_t *);
int   pthread_rwlockattr_setpshared(pthread_rwlockattr_t *, int);
pthread_t	pthread_self(void);
int   pthread_setcancelstate(int, int *);
int   pthread_setcanceltype(int, int *);
int   pthread_setconcurrency(int);
int   pthread_setschedparam(pthread_t, int , const struct sched_param *);
int   pthread_setspecific(pthread_key_t, const void *);
void  pthread_testcancel(void);
typedef void *(*thread_func)(void *);
]]
ffi.cdef(threadhead)
local thread=ffi.load("pthread")
pthread={}
for line in threadhead:gmatch("[^\r\n]+") do
	local name=line:match("^%S-%s+pthread_(.-)%(")
	if name then
		pthread[name]=thread["pthread_"..name]
	end
end
local funcs={}
for line in head:gmatch("[^\r\n]+") do
	local ret,name=line:match("^(.-)%((.-)%) %(lua_State %*L")
	if ret and not ret:match("typedef") then
		local k=name:gsub("^luaL?_","")
		funcs[funcs[k] and "L_"..k or k]=name
	end
end
ffi.cdef(head)
function newvm(L)
	local L=L or C.luaL_newstate()
	local LC={
		getglobal=function(name)
			return C.lua_getfield(L,-10002,name)
		end,
		setglobal=function(name)
			return C.lua_setfield(L,-10002,name)
		end,
		pushcfunction=function(func)
			return C.lua_pushcclosure(L,func,0)
		end,
	}
	for k,v in pairs(funcs) do
		LC[k]=function(...)
			return C[v](L,...)
		end
	end
	LC.openlibs()
	local o
	o=setmetatable({
		L=L,
		loadstring=function(txt,name)
			local res=LC.loadbuffer(txt,#txt,name or "str")
			if res~=0 then
				local err=ffi.string(LC.tolstring(-1,nil))
				LC.settop(-2)
				return false,err
			else
				return true
			end
		end,
		push=function(...)
			local p={...}
			for i=1,select("#",...) do
				local v=p[i]
				local tpe=type(v)
				if tpe=="string" then
					LC.pushlstring(v,#v)
				elseif tpe=="number" then
					LC.pushnumber(v)
				elseif tpe=="nil" then
					LC.pushnil()
				elseif tpe=="boolean" then
					LC.pushboolean(v and 1 or 0)
				elseif tpe=="function" then
					LC.pushcfunction(ffi.cast("lua_CFunction",v))
				else
					error("unsupported type "..tpe)
				end
			end
		end,
		pop=function(n)
			n=n or 1
			local o={}
			for i=-n,-1 do
				local tpe=LC.type(i)
				if tpe==0 then
					o[#o+1]=nil
				elseif tpe==1 then
					o[#o+1]=LC.toboolean(i)==1
				elseif tpe==2 or tpe==7 then
					o[#o+1]=LC.touserdata(i)
				elseif tpe==3 then
					o[#o+1]=LC.checknumber(i)
				elseif tpe==4 then
					local len=LC.objlen(-1)
					o[#o+1]=ffi.string(LC.tolstring(i,nil),len)
				elseif tpe==5 then
					o[#o+1]=LC.gettable(i)
				elseif tpe==6 then
					o[#o+1]=nope
				elseif tpe==8 then
					o[#o+1]=LC.tothread(i)
				end
			end
			LC.settop(-(n+1))
			return unpack(o,1,n)
		end,
		pcall=function(...)
			local t=LC.gettop()
			o.push(...)
			local res=LC.pcall(select("#",...),-1,0)
			if res==0 then
				return true,o.pop((LC.gettop()-t)+1)
			else
				local err=ffi.string(LC.tolstring(-1,nil))
				LC.settop(-2)
				return false,err
			end
		end,
		dostring=function(txt,...)
			local func,err=o.loadstring(txt)
			if not func then
				return false,err
			end
			return o.pcall(...)
		end,
		_G=setmetatable({},{
			__index=function(s,n)
				LC.getglobal(n)
				return o.pop()
			end,
			__newindex=function(s,n,d)
				o.push(d)
				LC.setglobal(n)
			end
		}),
		exit=function()
			LC.close()
		end,
		C=LC,
	},{
		__gc=function()
			o.exit()
		end,
		__call=function(s,...)
			return o.dostring(...)
		end
	})
	return o
end