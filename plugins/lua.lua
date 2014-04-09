local function maxval(tbl)
	local mx=0
	for k,v in pairs(tbl) do
		if type(k)=="number" then
			mx=math.max(k,mx)
		end
	end
	return mx
end
hook.new({"command_>"},function(user,chan,txt)
	if admin.auth(user) then
		local func,err=loadstring("return "..txt,"=lua")
		if not func then
			func,err=loadstring(txt,"=lua")
			if not func then
				return err
			end
		end
		local func=coroutine.create(setfenv(func,_G))
		debug.sethook(func,function() error("Time limit exeeded.",0) end,"",1000000)
		local res={coroutine.resume(func)}
		local o
		for l1=2,maxval(res) do
			o=(o or "")..tostring(res[l1]).."\n"
		end
		return o or "nil"
	end
end)

hook.new({"command_<"},function(user,chan,txt)
	if admin.auth(user) then
		local func,err=loadstring("return "..txt,"=lua")
		if not func then
			func,err=loadstring(txt,"=lua")
			if not func then
				return err
			end
		end
		local func=coroutine.create(setfenv(func,_G))
		local res={coroutine.resume(func)}
		local o
		for l1=2,maxval(res) do
			o=(o or "")..tostring(res[l1]).."\n"
		end
		return o or "nil"
	end
end)

hook.new({"command_l","command_lua"},function(user,chan,txt)
	local file=io.open("sbox.tmp","w")
	file:write(txt)
	file:close()
	local fi=io.popen("lua52.exe sbox.lua")
	local o={}
	local line=fi:read("*l")
	while line do
		table.insert(o,line)
		line=fi:read("*l")
	end
	return table.concat(o," | ")
end)

hook.new({"command_l53","command_lua53"},function(user,chan,txt)
	local file=io.open("sbox.tmp","w")
	file:write(txt)
	file:close()
	local fi=io.popen("lua53.exe sbox.lua")
	local o={}
	local line=fi:read("*l")
	while line do
		table.insert(o,line)
		line=fi:read("*l")
	end
	return table.concat(o," | ")
end)

hook.new({"command_l32","command_lua32"},function(user,chan,txt)
	if admin.auth(user) then
		local file=io.open("sbox.tmp","w")
		file:write(txt)
		file:close()
		local fi=io.popen("lua32.exe sbox32.lua")
		local o={}
		local line=fi:read("*l")
		while line do
			table.insert(o,line)
			line=fi:read("*l")
		end
		return table.concat(o," | ")
	end
end)

hook.new({"command_cmd"},function(user,chan,txt)
	if admin.auth(user) then
		local cm=io.popen(txt,"r")
		return cm:read("*a")
	end
end)

hook.new({"command_calc"},function(user,chan,txt)
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
			return erro or err
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
				error("exponent too big "..b.val)
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
	local res={coroutine.resume(func)}
	local o=""
	for l1=2,#res do
		o=o..tostring(res[l1]).."\n"
	end
	return erro or o
end)

do
	local sbox
	local usr
	local out
	local function rst()
		local tsbox={}
		sbox={
			_VERSION=_VERSION,
			assert=assert,
			error=error,
			getfenv=function(func)
				if tsbox[func] then
					return false,"Nope."
				end
				local res=getfenv(func)
				if res==_G then
					return sbox
				end
				return res
			end,
			getmetatable=getmetatable,
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
					return hook.queue("command_"..(cmd or txt),usr,usr.chan,tx or "")
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
		}
		for k,v in pairs({
			coroutine=coroutine,
			math=math,
			table=table,
			string=string,
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
	if not sbox then
		error("wtf")
	end
	hook.new({"command_resetl51","command_resetlua51"},function(user,chan,txt)
		rst()
		return "Sandbox reset."
	end)
	hook.new({"command_l51","command_lua51"},function(user,chan,txt)
		usr=user
		sbox.irc={}
		for k,v in pairs(user) do
			sbox.irc[k]=v
		end
		out=""
		local func,err=loadstring("return "..txt,"=lua51")
		if not func then
			func,err=loadstring(txt,"=lua51")
			if not func then
				return err
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
		return out..(o or "nil")
	end)
end
