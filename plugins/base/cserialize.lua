--[==[reqplugin("base/cc.lua")
cserializelib=cc.load("plugins/base/cserialize.c")
ffi.cdef[[
int cserialize(lua_State*);
]]
cserialize=cfunction(cserializelib.cserialize)]==]