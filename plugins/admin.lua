admin={}
admin.perms={}
admin.chans={}
admin.cmd={}

function admin.match(user,txt)
	local pfx,mt=txt:match("^$([ar]):(.+)")
	mt="^"..pescape(mt or txt):gsub("%%%*",".-").."$"
	return (pfx=="a" and user.account:match(mt)~=nil)
		or (pfx=="r" and user.realname:match(mt)~=nil)
		or (not pfx and (user.nick.."!"..user.username.."@"..user.host):match(mt)~=nil)
end

function admin.find(txt)
	local o={}
	for k,v in pairs(admin.perms) do
		if admin.match(v,txt) then
			table.insert(o,k)
		end
	end
	return o
end

function admin.auth(user,resp)
	if admin.perms[user.nick]==nil or admin.perms[user.nick].account~="ping" then
		if not resp then
			respond(user,"Nope.")
		end
		return false
	end
	return true
end

do
	admin.ignore={}
	local file=io.open("db/ignore","r")
	if file then
		admin.ignore=unserialize(file:read("*a"))
		if not ignore then
			admin.ignore={}
		end
	end
	local function save()
		local file=io.open("db/ignore","w")
		file:write(serialize(ignore))
		file:close()
	end
	hook.new("command_ignore",function(user,chan,txt)
		if admin.perms[txt] then
			txt="*!*@"..admin.perms[txt].host
		end
		if admin.ignore[txt] then
			return "Ignore unchanged."
		else
			admin.ignore[txt]=true
			save()
			return "Ignored "..txt
		end
	end)
	hook.new("command_unignore",function(user,chan,txt)
		if admin.perms[txt] then
			local u=false
			for k,v in tpairs(admin.ignore) do
				if admin.match(admin.perms[txt],k) then
					admin.ignore[k]=nil
					u=true
				end
			end
			if u then
				return "Unignored."
			else
				return "Ignore unchanged."
			end
		else
			if admin.ignore[txt] then
				admin.ignore[txt]=nil
				save()
				return "Unignored."
			else
				return "Ignore unchanged."
			end
		end
	end)
end

hook.new("raw",function(txt)
	txt:gsub("^:%S+ 319 "..cnick.." "..cnick.." :(.*)",function(chans)
		for chan in chans:gmatch("#%S+") do
			admin.chans[chan]={}
			send("WHO "..chan.." %cuihsnfar")
		end
	end)
	txt:gsub("^:%S+ 353 "..cnick.." . (%S+) :(.+)",function(chan,txt)
		print("ulist "..chan.." , "..txt)
		for user in txt:gmatch("%S+") do
			local pfx,nick=user:match("^([@%+]?)(.+)$")
			admin.perms[nick]=admin.perms[nick] or {op={},voice={}}
			if pfx=="@" then
				admin.perms[nick].op[chan]=true
			elseif pfx=="+" then
				admin.perms[nick].voice[chan]=true
			end
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ MODE (%S+) (.)(%a) (.+)",function(nick,chan,pm,mode,user)
		if mode=="o" then
			admin.perms[user].op[chan]=pm=="+" or nil
		elseif mode=="v" then
			admin.perms[user].voice[chan]=pm=="+" or nil
		end
	end)
	txt:gsub("^:%S+ 354 "..cnick.." (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) :(.+)",function(chan,username,ip,host,server,nick,modes,account,realname)
		if admin.chans[chan] then
			admin.chans[chan][nick]=true
			admin.perms[nick]=admin.perms[nick] or {}
			local perms=admin.perms[nick]
			perms.op=perms.op or {}
			perms.voice=perms.voice or {}
			perms.host=host
			perms.server=server
			perms.ip=ip
			perms.nick=nick
			perms.realname=realname
			perms.username=username
			if account~="0" then
				admin.perms[nick].account=account
			end
			if modes:match("@") then
				admin.perms[nick].op[chan]=true
			elseif modes:match("%+") then
				admin.perms[nick].voice[chan]=true
			end
		end
	end)
	txt:gsub("^:([^%s!]+)!([^%s@]+)@(%S+) JOIN (%S+)",function(nick,username,host,chan)
		if nick==cnick then
			admin.chans[chan]={}
			send("WHO "..chan.." %cuihsnfar")
		else
			send("WHOIS "..nick)
		end
		admin.chans[chan]=admin.chans[chan] or {}
		admin.chans[chan][nick]=admin.chans[chan][nick] or 0
		admin.perms[nick]=admin.perms[nick] or {}
		local perms=admin.perms[nick]
		perms.op=perms.op or {}
		perms.voice=perms.voice or {}
		perms.host=host
		perms.ip=socket.dns.toip(host)
		perms.nick=nick
		perms.username=username
		hook.queue("join",nick,chan)
	end)
	txt:gsub("^:%S+ 311 "..cnick.." (%S+) .- :(.+)",function(nick,realname)
		if admin.perms[nick] then
			admin.perms[nick].realname=realname
		end
	end)
	txt:gsub("^:%S+ 312 "..cnick.." (%S+) (%S+)",function(nick,server)
		local p=admin.perms[nick]
		if p then
			p.server=server
		end
	end)
	txt:gsub("^:%S+ 330 "..cnick.." (%S+) (%S+)",function(nick,account)
		local p=admin.perms[nick]
		if p and account~="0" then
			p.account=account
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ PART (%S+) ?:?.*",function(nick,chan)
		admin.chans[chan][nick]=nil
		if nick==cnick then
			admin.chans[chan]=nil
		end
		hook.queue("part",chan,nick)
		for k,v in pairs(admin.chans) do
			if v[nick] then
				return
			end
		end
		admin.perms[nick]=nil
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ KICK (%S+) :(%S+)",function(fnick,chan,nick)
		admin.chans[chan][nick]=nil
		if nick==cnick then
			admin.chans[chan]=nil
		end
		hook.queue("kick",chan,nick)
		for k,v in pairs(admin.chans) do
			if v[nick] then
				return
			end
		end
		admin.perms[nick]=nil
		hook.queue("kick",chan,nick,fnick)
		admin.perms[nick]=nil
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ NICK :(.+)",function(nick,tonick)
		if admin.perms[nick] then
			for k,v in pairs(admin.chans) do
				v[tonick]=v[nick]
				v[nick]=nil
			end
			admin.perms[nick].nick=tonick
			admin.perms[tonick]=admin.perms[nick]
			admin.perms[nick]=nil
			hook.queue("nick",nick,tonick)
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@(%S+) QUIT :.*",function(nick)
		hook.queue("quit",nick)
		admin.perms[nick]=nil
		for k,v in pairs(admin.chans) do
			v[nick]=nil
		end
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
		user.op=(user.op or {})[chan]==true
		user.voice=(user.voice or {})[chan]==true
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

hook.new("msg",function(user,chan,txt)
	for k,v in pairs(admin.ignore) do
		if v and admin.match(user,k) then
			return
		end
	end
	if chan~="#computercraft" then -- no bawts allowed
		txt=txt:gsub("%s+$","")
		if txt:sub(1,1)=="." then
			async.new(function()
				local err,res=xpcall(function()
					print(user.nick.." used "..txt)
					local cb=function(st,dat)
						if st==true then
							print("responding with "..tostring(dat))
							respond(user,tostring(dat))
						elseif st then
							print("responding with "..tostring(st))
							respond(user,user.nick..", "..tostring(st))
						end
					end
					hook.callback=cb
					hook.queue("command",user,chan,txt:sub(2))
					local cmd,param=txt:match("^%.(%S+) ?(.*)")
					if cmd then
						hook.callback=cb
						hook.queue("command_"..cmd,user,chan,param)
					end
				end,debug.traceback)
				if not err then
					print(res)
					respond(user,"Oh noes! "..paste(res))
				end
			end)
		end
	end
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

hook.new({"command_find"},function(user,chan,txt)
	local a,b=txt:match("^(%S+) (.+)")
	local o={}
	for k,v in pairs(admin.perms) do
		if v[a]==b then
			table.insert(o,k)
		end
	end
	return limitoutput(table.concat(o,","))
end)

hook.new({"command_pfind"},function(user,chan,txt)
	local a,b=txt:match("^(%S+) (.+)")
	local o={}
	for k,v in pairs(admin.perms) do
		if v[a]:match(b) then
			table.insert(o,k)
		end
	end
	return limitoutput(table.concat(o,","))
end)