admin={}
admin.perms={}

function admin.auth(user,resp)
	if admin.perms[user.nick]==nil or admin.perms[user.nick].account~="ping" then
		if not resp then
			respond(user,"Nope.")
		end
		return false
	end
	return true
end

hook.new("raw",function(txt)
	txt:gsub("^:%S+ 354 "..cnick.." (%S+) (%S+) (%S+)",function(host,nick,account)
		admin.perms[nick]={
			host=host,
		}
		if account~="0" then
			admin.perms[nick].account=account
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@(%S+) JOIN #oc",function(nick,host)
		if nick==cnick then
			send("WHO #oc %hna")
		end
		admin.perms[nick]={
			host=host,
		}
		send("WHOIS "..nick)
	end)
	txt:gsub("^:%S+ 330 "..cnick.." (%S+) (%S+)",function(nick,account)
		local p=admin.perms[nick]
		if p and account~="0" then
			p.account=account
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ PART #oc :.*",function(nick)
		hook.queue("part",nick)
		admin.perms[nick]=nil
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ PART #oc$",function(nick)
		hook.queue("part",nick)
		admin.perms[nick]=nil
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ KICK #oc :(%S+)",function(fnick,nick)
		hook.queue("kick",fnick,nick)
		admin.perms[nick]=nil
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ NICK :(.+)",function(nick,tonick)
		hook.queue("nick",nick,tonick)
		if admin.perms[nick] then
			admin.perms[tonick]=admin.perms[nick]
			admin.perms[nick]=nil
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@(%S+) QUIT :.*",function(nick)
		hook.queue("quit",nick)
		admin.perms[nick]=nil
	end)
end)

hook.new("raw",function(txt)
	txt:gsub("^:([^!]+)!([^@]+)@(%S+) PRIVMSG (%S+) :(.+)",function(nick,real,host,chan,txt)
		local ctcp=txt:match("^\1(.-)\1?$")
		local user={txt=txt,chan=chan,nick=nick,real=real,host=host}
		if admin.perms[nick] then
			for k,v in pairs(admin.perms[nick]) do
				user[k]=v
			end
		end
		hook.callback=function(st,dat)
			if st==true then
				print("responding with "..tostring(dat))
				respond(user,tostring(dat))
			elseif st then
				print("responding with "..tostring(st))
				respond(user,user.nick..", "..tostring(st))
			end
		end
		if ctcp and ctcp:sub(1,7)~="ACTION " and chan==cnick then
			hook.queue("ctcp",user,chan,ctcp)
		else
			if ctcp and ctcp:sub(1,7)=="ACTION " then
				hook.queue("msg",user,chan,txt:sub(9,-2),true)
			else
				hook.queue("msg",user,chan,txt)
			end
		end
	end)
end)

hook.new("command_account",function(user,chan,txt)
	if txt=="" then
		return (admin.perms[user.nick] or {}).account or "none"
	end
	return (admin.perms[txt] or {}).account or "none"
end)

hook.new({"command_ip"},function(user,chan,txt)
	if txt=="" then
		return (admin.perms[user.nick] or {}).ip or "none"
	end
	return (admin.perms[txt] or {}).ip or "none"
end)

hook.new({"command_host"},function(user,chan,txt)
	if txt=="" then
		return (admin.perms[user.nick] or {}).host or "none"
	end
	return (admin.perms[txt] or {}).host or "none"
end)