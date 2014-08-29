tells={}
local file=io.open("db/"..network.."/tells","r")
if file then
	tells=unserialize(file:read("*a"))
	if not tells then
		tells={}
	end
end
local function update()
	local file=assert(io.open("db/"..network.."/tells","w"))
	file:write(serialize(tells))
	file:close()
end
hook.new("command_tell",function(user,chan,txt)
	local usr,txt=txt:match("(.-) (.+)")
	
	if not usr then
		return "Usage: .tell (<user>|$a:<account>|$h:<host>) <txt>"
	end
	local ntype,susr=usr:match("^%$(.):(.+)")
	if not ntype or ntype=="$n" then
		usr=usr:gsub("[,:]$","")
	end
	if not ntype then
		if admin.perms[usr] and admin.perms[usr].account then
			ntype,susr="a",admin.perms[usr].account
		else
			ntype,susr="n",usr
		end
	end
	local meta="$"..ntype..":"..susr
	tells[meta]=tells[meta] or {}
	table.insert(tells[meta],"From "..user.nick..": "..txt)
	update()
	return "Message queued."
end,{
	desc="tells a person something the next time they talk",
	group="help",
})
local function get(usr,o)
	if tells[usr] then
		for k,v in pairs(tells[usr]) do
			table.insert(o,v)
		end
		tells[usr]=nil
		update()
	end
end
hook.new("msg",function(user,chan,txt)
	local o={}
	get("$n:"..user.nick,o)
	get("$a:"..(user.account or 0),o)
	get("$h:"..user.host,o)
	if #o>0 then
		send("NOTICE "..user.nick.." :"..table.concat(o," | "))
	end
end)
