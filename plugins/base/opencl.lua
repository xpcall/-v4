
reqplugin("base/cc.lua")
reqplugin("base/vm.lua")
opencllib=cc.load("plugins/base/opencl.c",{link={["OpenCL"]=true},include={["/usr/include/CL/"]=true}})
ffi.cdef[[
	int lcl_initGpu(lua_State* L);
	int lcl_compile(lua_State* L);
	int lcl_newBuffer(lua_State* L);
	int lcl_exec(lua_State* L);
]]

opencl={
	initGpu=cfunction(opencllib.lcl_initGpu),
	compile=cfunction(opencllib.lcl_compile),
	newBuffer=cfunction(opencllib.lcl_newBuffer),
	exec=cfunction(opencllib.lcl_exec),
}
