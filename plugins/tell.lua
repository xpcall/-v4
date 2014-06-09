tells={}
local file=io.open("db/tells","r")
if file then
	tells=unserialize(file:read("*a"))
	if not tells then
		tells={}
	end
end
local function update()
	local file=io.open("db/tells","w")
	file:write(serialize(tells))
	file:close()
end
hook.new("command_tell",function(user,chan,txt)
	local usr,txt=txt:match("(%S+) (.+)")
	if not usr then
		return "Usage: .tell (<user>|$a:<account>|$h:<host>) <txt>"
	end
	local ntype,susr=usr:match("^%$(.):(.+)")
	if not ntype then
		ntype,susr="n",usr
	end
	local meta="$"..ntype..":"..susr
	tells[meta]=tells[meta] or {}
	table.insert(tells[meta],"From "..user.nick..": "..txt)
	update()
	if user.account=="gamax92" then
		return "Will send the message over irc the next time they talk and then remove it from my list of message that i need to send to people who talk."
	end
	return "Message queued."
end)
local function get(usr,o)
	if tells[usr] then
		for k,v in pairs(tells[usr]) do
			table.insert(o,v)
		end
		tells[usr]=nil
	end
end
hook.new("msg",function(user,chan,txt)
	local o={}
	get("$n:"..user.nick,o)
	get("$a:"..(user.account or 0),o)
	get("$h:"..user.host,o)
	update()
	if #o>0 then
		send("NOTICE "..user.nick.." :"..table.concat(o," | "))
	end
end)
