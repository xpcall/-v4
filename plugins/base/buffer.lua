ffi.cdef[[
void* malloc(int);
void* realloc(void*,int);
void memcpy(void*,void*,int);
void free(void*);
]]

local bfuncs={
	cat=function(s,txt)
		local len=type(txt)=="string" and #txt or txt.len
		if s.length==0 then
			s.ptr=C.malloc(len)
			C.memcpy(s.ptr,ffi.cast("void*",txt),len)
		else
			s.ptr=C.realloc(s.ptr,s.len+len)
			C.memcpy(ffi.cast("void*",ffi.cast("int",s.ptr)+s.len),ffi.cast("void*",txt),len)
		end
	end,
	tostring=function(s)
		return ffi.string(s.ptr,s.length)
	end,
}

local bmeta={
	__index=function(s,n)
		if type(n)=="number" then
			assert(n>0 and n<=s.len,"buffer index out of range")
			return s.ptr[n-1]
		else
			return bfuncs[n]
		end
	end,
	__newindex=function(s,n,d)
		assert(n>0 and n<=s.len,"buffer index out of range")
		s.ptr[n-1]=d
	end,
	__concat=function(a,b)
		local ptr=c.malloc
	end,
	_gc=function(s)
		if s.gc then
			C.free(s.ptr)
		end
	end,
}

function buffer(txt,gc)
	if not txt then
		return setmetatable({len=0,ptr=0,gc=gc},bmeta)
	end
	local len=type(txt)=="string" and #txt or txt.len
	local ptr=C.malloc(len)
	C.memcpy(ptr,ffi.cast("void*",txt),len)
	return setmetatable({ptr=ptr,len=len},bmeta)
end
