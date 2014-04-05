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
		local o=""
		for l1=2,#res do
			o=o..tostring(res[l1]).."\n"
		end
		return o
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
		local o=""
		for l1=2,#res do
			o=o..tostring(res[l1]).."\n"
		end
		return o
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
	local func=coroutine.create(setfenv(func,{new=function(t)
		return bc.add(t,0)
	end}))
	debug.sethook(func,function() error("Time limit exeeded.",0) end,"",10000000)
	local res={coroutine.resume(func)}
	local o=""
	for l1=2,#res do
		o=o..tostring(res[l1]).."\n"
	end
	return erro or o
end)
