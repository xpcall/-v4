local programs=db.new("programs")
hook.new({"command_addprogram"},function(user,chan,txt)
	local name,desc,url=txt:match("(%S+) (.+) (%S+)")
	if not desc then
		return "Usage: .addprogram <name> <description> <url>"
	end
	programs[name]={desc=desc,url=url}
	return "Program added!"
end)
hook.new({"command_program"},function(user,chan,txt)
	local cb
	hook.callback=function(c)
		cb=c
	end
	local c=false
	if txt:match("^add ") then
		c=true
		hook.queue("command_addprogram",user,chan,txt:match("^add (.+)"))
	elseif txt:match("^rand") then
		c=true
		hook.queue("command_randomprogram",user,chan,"")
	elseif programs[txt] then
		local pr=programs[txt]
		cb=pr.desc.." "..pr.url
	end
	if not c then
		hook.callback=nil
	end
	return cb or "Usage: .program (<name>|add <name> <desc> <url>|rand)"
end)
hook.new({"command_randomprogram"},function(user,chan,txt)
	local c={}
	for k,v in pairs(programs) do
		c[#c+1]=k
	end
	local r
	hook.callback=function(c)
		r=c
	end
	hook.queue("command_program",user,chan,c[math.random(1,#c)])
	return r
end)