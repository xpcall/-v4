local function maxval(tbl)
	local mx=0
	for k,v in pairs(tbl) do
		if type(k)=="number" then
			mx=math.max(k,mx)
		end
	end
	return mx
end

function limitoutput(txt)
	if #txt>250 then
		return paste(txt)
	end
	return txt
end

do
	local c={}
	hook.new({"command_a>"},function(user,chan,txt)
		if admin.auth(user) then
			if txt:sub(1,1)=="\27" then
				return "Nope."
			end
			local func,err=loadstring("return "..txt,"=lua")
			if not func then
				func,err=loadstring(txt,"=lua")
				if not func then
					return err
				end
			end
			async.new(setfenv(func,_G))
			return "Running."
		end
	end,{
		desc="asyncronous admin lua",
		group="admin",
	})
end

hook.new("command_rpi",function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	local rpi=assert(socket.connect("192.168.2.137",1337))
	rpi:send(txt.."\n")
	local s,_,res=rpi:receive("*a")
	return s or res
end)

hook.new({"command_>"},function(user,chan,txt)
	if admin.auth(user) then
		if txt:sub(1,1)=="\27" then
			return "Nope."
		end
		local func,err=loadstring("return "..txt,"=lua")
		if not func then
			func,err=loadstring(txt,"=lua")
			if not func then
				return err
			end
		end
		local o=""
		local res={pcall(setfenv(func,setmetatable({
			print=function(...)
				for k,v in pairs({...}) do
					o=o..tostring(v).."\n"
				end
			end,
		},{
			__index=_G,
			__newindex=_G
		})))}
		for l1=2,math.max(2,maxval(res)) do
			o=o..tostring(res[l1]).."\n"
		end
		return limitoutput(o or "nil")
	end
end,{
	desc="admin lua",
	group="admin",
})

hook.new({"command_<"},function(user,chan,txt)
	if admin.auth(user) then
		if txt:sub(1,1)=="\27" then
			return "Nope."
		end
		local func,err=loadstring("return "..txt,"=lua")
		if not func then
			func,err=loadstring(txt,"=lua")
			if not func then
				return err
			end
		end
		local res={pcall(setfenv(func,_G))}
		local o
		for l1=2,maxval(res) do
			o=(o or "")..tostring(res[l1]).."\n"
		end
		return limitoutput(o or "nil")
	end
end,{
	desc="admin lua",
	group="admin",
})

hook.new({"command_l","command_lua"},function(user,chan,txt)
	if txt:sub(1,1)=="\27" then
		return "Nope."
	end
	local file=io.open("sbox.tmp","w")
	file:write(txt)
	file:close()
	local fi=assert(io.popen("timelimit -t 0.5 ./bin/lua52 sbox.lua"))
	local out=fi:read("*a")
	if out:match("Program done%.\n$") then
		out=out:gsub("Program done%.\n$","")
	else
		out=out.."Time limit exeeded."
	end
	return limitoutput(out)
end,{
	desc="executes lua 5.2 code",
	group="help",
})

hook.new({"command_lj","command_luaj"},function(user,chan,txt)
	if txt:sub(1,1)=="\27" then
		return "Nope."
	end
	local file=io.open("sbox.tmp","w")
	file:write(txt)
	file:close()
	local fi=assert(io.popen("timelimit -t 1 java -cp ./bin/OCLuaJ.jar lua sbox.lua"))
	local out=fi:read("*a")
	if out:match("Program done%.\n$") then
		out=out:gsub("Program done%.\n$","")
	else
		out=out.."Time limit exeeded."
	end
	return limitoutput(out)
end,{
	desc="executes lua 5.2 code",
	group="help",
})

hook.new({"command_blj","command_borkluaj"},function(user,chan,txt)
	if txt:sub(1,1)=="\27" then
		return "Nope."
	end
	local file=io.open("sbox.tmp","w")
	file:write(txt)
	file:close()
	local fi=assert(io.popen("timelimit -t 1 java -cp ./bin/BorkLuaJ.jar lua sbox.lua"))
	local out=fi:read("*a")
	if out:match("Program done%.\n$") then
		out=out:gsub("Program done%.\n$","")
	else
		out=out.."Time limit exeeded."
	end
	return limitoutput(out)
end,{
	desc="executes lua 5.2 code",
	group="help",
})

hook.new({"command_l53","command_lua53"},function(user,chan,txt)
	if txt:sub(1,1)=="\27" then
		return "Nope."
	end
	local file=io.open("sbox.tmp","w")
	file:write(txt)
	file:close()
	local fi=assert(io.popen("timelimit -t 0.5 ./bin/lua53 sbox.lua"))
	local out=fi:read("*a")
	if out:match("Program done%.\n$") then
		out=out:gsub("Program done%.\n$","")
	else
		out=out.."Time limit exeeded."
	end
	return limitoutput(out)
end,{
	desc="executes lua 5.3 code",
	group="help",
})

hook.new({"command_ips"},function(user,chan,txt)
	local p=coroutine.create(function()
		while true do
			local a={}
			for l1=1,1000 do
				table.insert(a,1234)
			end
		end
	end)
	local ltime=socket.gettime()
	local rt
	debug.sethook(p,function()
		local tme=socket.gettime()
		local dt=tme-ltime
		rt=1000000/dt
		error()
	end,"",1000000)
	coroutine.resume(p)
	return rt
end,{
	desc="benchmarks instructions per second",
	group="fun",
})

hook.new({"command_bm","command_benchmark"},function(user,chan,txt)
	local t=socket.gettime()
	local o=hook.queue("command_lua51",user,chan,txt) or ""
	return socket.gettime()-t.."\n"..o
end,{
	desc="benchmarks lua 5.1 code",
	group="fun",
})

hook.new({"command_cmd"},function(user,chan,txt)
	if admin.auth(user) then
		local cm=io.popen(txt,"r")
		return cm:read("*a")
	end
end,{
	desc="executes batch",
	group="admin",
})

--[[hook.new({"command_calc"},function(user,chan,txt)
	local erro
	txt=txt:gsub("[^%s%.%/%+%-%^%*%%%(%)%d]+",function(t)
		erro="Unexpected "..t
		return "error()"
	end)
	txt=txt:gsub("[%d%.]+",function(t) return "new(\""..t.."\")" end)
	local func,err=loadstring("return "..txt,"=lua")
	if not func then
		func,err=loadstring(txt,"=lua")
		if not func then
			return limitoutput(erro or err)
		end
	end
	local meta
	meta={
		__add=function(a,b)
			return setmetatable({val=bc.add(a.val,b.val)},meta)
		end,
		__sub=function(a,b)
			return setmetatable({val=bc.sub(a.val,b.val)},meta)
		end,
		__mul=function(a,b)
			return setmetatable({val=bc.mul(a.val,b.val)},meta)
		end,
		__div=function(a,b)
			return setmetatable({val=bc.div(a.val,b.val)},meta)
		end,
		__mod=function(a,b)
			return setmetatable({val=bc.mod(a.val,b.val)},meta)
		end,
		__unm=function(a)
			return setmetatable({val=bc.neg(a.val)},meta)
		end,
		__pow=function(a,b)
			if bc.compare(b.val,1000)==1 then
				error("exponent too big")
			end
			return setmetatable({val=bc.pow(a.val,b.val)},meta)
		end,
		__tostring=function(s)
			return tostring(s.val)
		end,
	}
	local func=coroutine.create(setfenv(func,{new=function(t)
		return setmetatable({val=t},meta)
	end}))
	debug.sethook(func,function() error("Time limit exeeded.",0) end,"",10000000)
	bc.digits(10)
	local res={coroutine.resume(func)}
	local o=""
	for l1=2,#res do
		o=o..tostring(res[l1]).."\n"
	end
	return limitoutput((erro or o):gsub("%.0+\n$",""))
end,{
	desc="calculates large numbers",
	group="help",
})]]

hook.new({"command_calc","command_bc"},function(user,chan,txt,nolimit)
	local file=io.open("sbox.tmp","w")
	file:write(txt.."\nquit")
	file:close()
	local fi=io.popen("timelimit -t 0.5 lua bcsbox.lua")
	local out=fi:read("*a")
	if out:match("Program done%.\n$") then
		out=out:gsub("Program done%.\n$","")
	else
		out=out.."Time limit exeeded."
	end
	if nolimit then return out end
	return limitoutput(out)
end,{
	desc="calculates large numbers",
	group="help",
})

--[[do
	local sbox
	local usr
	local out
	local function rst()
		local str={}
		for k,v in pairs(getmetatable("")) do
			str[k]=v
		end
		local tsbox={}
		sbox={
			_VERSION=_VERSION,
			assert=assert,
			error=error,
			getfenv=function(func)
				if tsbox[func] then
					return sbox
				end
				local res=getfenv(func)
				if res==_G or res==getfenv(0) or (res or {}).io==io then
					return sbox
				end
				return res
			end,
			getmetatable=function(obj)
				if type(obj)=="string" then
					return str
				end
				return getmetatable(obj)
			end,
			ipairs=ipairs,
			load=function(func,name)
				local out=""
				while true do
					local n=func()
					if not n or n=="" then
						return out
					end
					out=out..n
				end
				return sbox.loadstring(out,name)
			end,
			loadstring=function(txt,name)
				if txt:sub(1,1)=="\27" then
					return false,"Nope."
				end
				local func,err=loadstring(txt,name)
				if func then
					setfenv(func,sbox)
				end
				return func,err
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
			rawset=rawset,
			select=select,
			setfenv=function(func,env)
				if tsbox[func] then
					return false,"Nope."
				end
				return setfenv(func,env)
			end,
			setmetatable=setmetatable,
			tonumber=tonumber,
			tostring=tostring,
			type=type,
			unpack=unpack,
			xpcall=xpcall,
			os={
				clock=os.clock,
				date=os.date,
				difftime=os.difftime,
				execute=function(txt)
					local cmd,tx=txt:match("^(.-) (.+)$")
					cmd=cmd or txt
					if cmd=="slap" or cmd=="jenkins" or cmd=="j" or cmd=="beta" or cmd=="build" or cmd=="short" or cmd=="s" then -- spammy / slow
						return false,"Nope."
					end
					if not hook.hooks["command_"..(cmd or txt)] then
						return false,"No such command."
					end
					return ({hook.queue("command_"..(cmd or txt),usr,usr.chan,tx or "")})[1]
				end,
				exit=function()
					error()
				end,
				time=os.time,
			},
			io={
				write=function(...)
					out=out..table.concat({...})
				end,
			},
			serialize=serialize,
			unserialize=unserialize,
		}
		for k,v in pairs({
			coroutine=coroutine,
			math=math,
			table=table,
			string=string,
			bit=bit,
			bc=bc,
		}) do
			sbox[k]={}
			for n,l in pairs(v) do
				sbox[k][n]=l
			end
		end
		for k,v in pairs(sbox) do
			if type(v)=="table" then
				for n,l in pairs(v) do
					tsbox[l]=true
				end
			elseif type(v)=="function" then
				tsbox[v]=true
			end
		end
		sbox._G=sbox
	end
	rst()
	hook.new({"command_rstl51","command_resetlua51"},function(user,chan,txt)
		rst()
		return "Sandbox reset."
	end,{
		desc="resets the lua 5.1 sandbox",
		group="help",
	})
	hook.new({"command_l51","command_lua51"},function(user,chan,txt)
		if txt:sub(1,1)=="\27" then
			return "Nope."
		end
		usr=user
		sbox.user={}
		sbox.chan={}
		for k,v in pairs(admin.chans[chan] or {}) do
			sbox.chan[k]={nick=k}
			local u=sbox.chan[k]
			for k,v in pairs(admin.perms[k]) do
				u[k]=v
			end
			u.op=u.op[chan] or false
			u.voice=u.voice[chan] or false
		end
		sbox.chan[user.nick]=sbox.user
		for k,v in pairs(user) do
			sbox.user[k]=v
		end
		out=""
		local func,err=loadstring("return "..txt,"=lua51")
		if not func then
			func,err=loadstring(txt,"=lua51")
			if not func then
				return limitoutput(err)
			end
		end
		local func=coroutine.create(setfenv(func,sbox))
		debug.sethook(func,function()
			debug.sethook(func)
			debug.sethook(func,function()
				error("Time limit exeeded.",0)
			end,"",1)
			error("Time limit exeeded.",0)
		end,"",10000)
		local res={coroutine.resume(func)}
		local o
		for l1=2,maxval(res) do
			o=(o or "")..tostring(res[l1]).."\n"
		end
		return limitoutput(out..(o or "nil"))
	end,{
		desc="executes lua 5.1 code",
		group="help",
	})
end]]

if tcpnet then
	tcpnet.open(1338)
end
hook.new("command_oc",function(user,chan,txt)
	if not tcpnet then
		return "tcpnet not running."
	end
	tcpnet.send(1337,txt)
	async.pull()
end)
