pipe={}
ffi.cdef[[
	void* fdopen(int,const char*);
	int fclose(void*);
	size_t fread(void*,int,int,void*);
	size_t fwrite(void*,int,int,void*);
	void clearerr(void*);
	int feof(void*);
	int ferror(void*);
	
	int pipe(int*);
	int close(int);
]]

local buffersize=256

function pipe.read(fd)
	return function()
		local file=C.fdopen(fd,"rb")
		local buffer=ffi.new("char[?]",buffersize)
		local o=""
		while true do
			local r=C.fread(buffer,buffersize,1,file)
			local err=C.ferror(file)
			if err~=0 then
				error("Error reading: "..err)
			elseif r<1 then
				break
			end
			clearerr(file)
			o=o..ffi.string(buffer,r)
		end
		C.fclose(file)
		return o
	end
end

function pipe.write(fd)
	return function(txt)
		local file=C.fdopen(fd,"wb")
		local r=C.fwrite(ffi.cast("char*",txt),#txt,1,file)
		local err=C.ferror(file)
		if err~=0 then
			error("Error writing: "..err)
		end
		C.fclose(file)
	end
end

function pipe.close(fd)
	local err=C.close(fd)
	if err~=0 then
		error("Error closing pipe: "..err)
	end
end

function pipe.new(fd)
	local fdes=ffi.new("int[2]")
	local err=C.pipe(fdes)
	if err~=0 then
		error("Error creating pipe: "..err)
	end
	return {
		readf=fdes[0],
		read=pipe.read(fdes[0]),
		writef=fdes[1],
		write=pipe.write(fdes[1]),
	}
end
