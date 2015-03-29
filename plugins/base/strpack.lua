reqplugin("base/cc.lua")
reqplugin("base/vm.lua")
strpacklib=cc.load("plugins/base/strpack.c",{link={["OpenCL"]=true}})
ffi.cdef[[
	int str_pack(lua_State*);
	int str_packsize(lua_State*);
	int str_unpack(lua_State*);
]]
string.pack=cfunction(strpacklib.str_pack)
string.packsize=cfunction(strpacklib.str_packsize)
string.unpack=cfunction(strpacklib.str_unpack)