liblib=cc.load("plugins/base/lib.cpp")
ffi.cdef[[
	int lib_udataptr(lua_State*);
	int lib_dump(lua_State*);
	int lib_udump(lua_State*);
	int lib_test(lua_State*);
	int lib_nanosecond(lua_State*);
	int lib_fdump(lua_State*);
]]
udataptr=cfunction(liblib.lib_udataptr)
ffi.dump=cfunction(liblib.lib_dump)
ffi.udump=cfunction(liblib.lib_udump)
ffi.test=cfunction(liblib.lib_test)
nanosecond=cfunction(liblib.lib_nanosecond)
fdump=cfunction(liblib.lib_fdump)