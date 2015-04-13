if reqplugin then
	reqplugin("base/vm.lua")
	pipelib=cc.load("plugins/base/pipe.c")
	ffi.cdef[[
		int pipe_new(lua_State* L);
		int pipe_close(lua_State* L);
		int pipe_read(lua_State* L);
		int pipe_write(lua_State* L);
		int pipe_test(lua_State* L);
	]]
	pipe={
		new=cfunction(pipelib.pipe_new),
		close=cfunction(pipelib.pipe_close),
		read=cfunction(pipelib.pipe_read),
		write=cfunction(pipelib.pipe_write),
		test=cfunction(pipelib.pipe_test),
	}
end
local ffi=require("ffi")
local C=ffi.C
ffi.cdef[[
	char* strerror(int);
	int pipe(int[2]);
	int fcntl(int,int,...);
	int close(int);
	long read(int,void*,size_t);
	long write(int,void*,size_t);
]]
local function passert(n)
	if n==-1 then
		error(ffi.string(C.strerror(ffi.errno())),3)
	end
end
local F_SETFL=4
local O_RDONLY=0
local O_WRONLY=1
local O_NONBLOCK=2048
local EAGAIN=11
pipe2={
	new=function()
		local pipes=ffi.new("int[2]")
		passert(C.pipe(pipes))
		passert(C.fcntl(pipes[0],F_SETFL,ffi.cast("int",O_NONBLOCK+O_RDONLY)))
		return pipes[0],pipes[1]
	end,
	close=function(fd)
		passert(C.close(fd))
	end,
	read=function(fd,block)
		local buffer=ffi.new("char[64]")
		local lbuffer=""
		local w
		while true do
			local rs=C.read(fd,buffer,ffi.sizeof(buffer))
			if rs==-1 then
				if ffi.errno()==EAGAIN then
					if w or not block then
						break
					end
					C.fcntl(fd,F_SETFL,ffi.cast("int",O_RDONLY))
					passert(C.read(fd,nil,0))
					C.fcntl(fd,F_SETFL,ffi.cast("int",O_NONBLOCK+O_RDONLY))
				else
					passert(rs)
				end
			else
				w=true
				lbuffer=lbuffer..ffi.string(buffer,rs)
			end
		end
		return lbuffer
	end,
	write=function(fd,data,block)
		if block then
			C.fcntl(fd,F_SETFL,ffi.cast("int",O_WRONLY))
		else
			C.fcntl(fd,F_SETFL,ffi.cast("int",O_WRONLY+O_NONBLOCK))
		end
		local rs=C.write(fd,ffi.cast("void*",data),#data)
		if rs==-1 then
			if ffi.errno()==EAGAIN then
				return 0
			end
			passert(rs)
		end
		return rs
	end,
}


