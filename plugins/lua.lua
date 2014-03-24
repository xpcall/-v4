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
		local err,res=coroutine.resume(func)
		return res or "nil"
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

hook.new({"command_cmd"},function(user,chan,txt)
	if admin.auth(user) then
		local cm=io.popen(txt,"r")
		return cm:read("*a")
	end
end)
