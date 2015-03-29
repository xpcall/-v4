reqplugin("base/cc.lua")
reqplugin("base/vm.lua")
local lib=cc.load("plugins/base/thread.c",{link={["pthread"]=true}})
ffi.cdef[[
	void* lthread_callback(void*);
]]
thread={}

local tfuncs={
	join=function(s)
		local r=pthread.join(s.ptr[0],nil)
		if r~=0 then
			error("error "..r.." joining thread",2)
		end
		s:free()
	end,
	kill=function(s)
		pthread.kill(s.ptr[0],9)
		ffi.C.free(ffi.gc(s.ptr,nil))
		s:free()
	end,
	free=function(s)
		if not s.freed then
			ffi.C.free(ffi.gc(s.ptr,nil))
			s.freed=true
		end
	end,
}

function thread.new(func,...)
	if type(func)=="function" then
		func=string.dump(func)
	end
	local vm=newvm()
	vm.loadstring(func)
	vm.push(...)
	local thread=ffi.new("pthread_t[1]")
	local r=pthread.create(thread,nil,lib.lthread_callback,vm.L)
	if r~=0 then
		error("error "..r.." creating thread",2)
	end
	return setmetatable({
		ptr=thread,
	},{__index=tfuncs})
end