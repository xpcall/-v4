local vm
local function new()
	if vm then
		vm.exit()
	end
	vm=newvm()
	vm52=vm
	assert(vm.dostring([[
		local ffi=require("ffi")
		local jit=require("jit")
		local socket=require("socket")
		local sbox
		local function to32(func)
			return function(...)
				return tonumber(bit.tohex(func(...)),16)
			end
		end
		sbox={
			_VERSION="Lua 5.2 (LuaJIT hax)",
			assert=assert,
			error=error,
			getmetatable=getmetatable,
			ipairs=ipairs,
			load=function(ld,source,env)
				return load(ld,source,"t",env or sbox)
			end,
			next=next,
			pairs=pairs,
			pcall=pcall,
			print=function(...)
				for k,v in pairs({...}) do
					out=out..tostring(v).."\n"
				end
			end,
			rawequal=rawequal,
			rawget=rawget,
			rawlen=rawlen,
			rawset=rawset,
			select=select,
			getmetatable=getmetatable,
			tonumber=tonumber,
			tostring=tostring,
			type=type,
			xpcall=xpcall,
			bit32={
				arshift=to32(bit.arshift),
				band=to32(bit.band),
				bnot=to32(bit.bnot),
				bor=to32(bit.bor),
				btest=function(...)
					return bit.band(...)~=0
				end,
				bxor=to32(bit.bxor),
				lrotate=to32(bit.rol),
				lshift=to32(bit.lshift),
				rrotate=to32(bit.ror),
				rshift=to32(bit.rshift),
			},
			coroutine={
				create=coroutine.create,
				resume=coroutine.resume,
				running=coroutine.running,
				status=coroutine.status,
				wrap=coroutine.wrap,
				yield=coroutine.yield,
			},
			debug={
				traceback=debug.traceback,
				no=true,
			},
			io={
				write=function(...)
					out=out..table.concat({...})
				end,
				no=true,
			},
			math={
				abs=math.abs,
				acos=math.acos,
				asin=math.asin,
				atan=math.atan,
				atan2=math.atan2,
				ceil=math.ceil,
				cos=math.cos,
				cosh=math.cosh,
				deg=math.deg,
				exp=math.exp,
				floor=math.floor,
				fmod=math.fmod,
				frexp=math.frexp,
				huge=math.huge,
				ldexp=math.ldexp,
				log=math.log,
				max=math.max,
				min=math.min,
				modf=math.modf,
				pi=math.pi,
				pow=math.pow,
				rad=math.rad,
				random=math.random,
				randomseed=math.randomseed,
				sin=math.sin,
				sinh=math.sinh,
				sqrt=math.sqrt,
				tan=math.tan,
				tanh=math.tanh,
			},
			os={
				clock=os.clock,
				date=os.date,
				difftime=os.difftime,
				time=os.time,
				no=true,
			},
			string={
				byte=string.byte,
				char=string.char,
				dump=string.dump,
				find=string.find,
				format=string.format,
				gmatch=string.gmatch,
				gsub=string.gsub,
				len=string.len,
				lower=string.lower,
				match=string.match,
				rep=string.rep,
				reverse=string.reverse,
				sub=string.sub,
				upper=string.upper,
			},
			table={
				concat=table.concat,
				insert=table.insert,
				pack=table.pack,
				remove=table.remove,
				sort=table.sort,
				unpack=table.unpack,
			},
		}
		sbox._G=sbox
		function exec()
			local func,err=loadstring("return "..code)
			if not func then
				func,err=loadstring(code)
				out=err
			end
			out=""
			timeout=true
			local res=table.pack(pcall(setfenv(func,sbox)))
			timeout=false
			for i=2,res.n do
				out=out..tostring(res[i]).."\n"
			end
			socket.sleep(10)
		end
	]]))
end
hook.new("command_l52",function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	if not vm then
		new()
	end
	vm._G.code=txt
	local thread=ffi.new("pthread_t[1]")
	local nc=coroutine.wrap(loadstring([[
		C.lua_getglobal
	]]))
	pthread.create(
		thread,
		nil,
		nc,
		nil
	)
	socket.sleep(0.1)
	async.wait(1)
	pthread.kill(thread,15)
	pthread.join(thread,nil)
	nc()
	return vm._G.timeout and "Time limit exeeded." or vm._G.out or "D: nothing"
end)
