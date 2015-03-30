liblib=cc.load("plugins/base/lib.c")
ffi.cdef[[
	int lib_udataptr(lua_State*);
	int lib_dump(lua_State*);
	int lib_udump(lua_State*);
]]
udataptr=cfunction(liblib.lib_udataptr)
ffi.dump=cfunction(liblib.lib_dump)
ffi.udump=cfunction(liblib.lib_udump)
