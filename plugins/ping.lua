local pings={}
hook.new({"command_ping","command_v^","command_p"},function(user,chan,txt)
	local un=txt
	if not admin.perms[txt] then
		un=user.nick
	end
	send("PRIVMSG "..un.." :\1PING\1")
	pings[un]={user.chan==cnick and "NOTICE "..user.nick or "PRIVMSG "..user.chan,socket.gettime(),un}
end,{
	desc="CTCP pings someone",
	group="misc",
})
hook.new("raw",function(txt)
	local usr,nt=txt:match("^:([^%s!]+)![^%s@]+@%S+ NOTICE "..cnick.." :\1PING.-\1")
	if usr and pings[usr] then
		local png=pings[usr]
		pings[usr]=nil
		send(png[1].." :Ping reply from "..png[3].." "..math.round(socket.gettime()-png[2],2).."s")
	end
end)
local last=socket.gettime()
hook.new("raw",function()
	
end)
async.new(function()
	while true do
		async.wait(20)
		if socket.gettime()-last>20 then
			send("PING POTATO"..math.random(100000,999999))
		end
	end
end)

