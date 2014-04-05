local whois=db.new("whois")
local conv={
	["a"]="account",
	["h"]="host",
	["n"]="nick",
}
hook.new("command_whois",function(user,chan,txt)
	local user=admin.perms[txt]
	local o={}
	for k,v in pairs(whois) do
		if user then
			local m
			local px,mt=k:match("^%$([^:]+):(.+)")
			if px=="a" then
				m=user.account or "0"
			elseif px=="h" then
				m=user.host
			elseif px=="n" then
				m=txt
			end
			if mt and m and m:match(mt) then
				table.insert(o,conv[px]..":"..v)
			end
		else
			if txt:match(k:match("^%$[^:]+:(.+)")) then
				table.insert(o,v)
			end
		end
	end
	if #o==0 then
		return "No results."
	end
	return table.concat(o,", ")
end)

hook.new("command_autowho",function(user,chan,txt)
	local suser,nuser=txt:match("^(%S+) (%S+)")
	if not suser then
		suser=txt:match("^(%S+)")
		nuser=suser
	end
	local tuser=admin.perms[suser or ""]
	if not tuser then
		return "User not found."
	end
	whois["$n:"..pescape(suser)]=nuser
	whois["$h:"..pescape(tuser.host)]=nuser
	if tuser.account then
		whois["$a:"..pescape(tuser.account)]=nuser
	end
	return "Who set."
end)

hook.new("command_setwho",function(user,chan,txt)
	local user,px,dat=txt:match("^(%S+) %$([iahn]):(.+)")
	if not user then
		return "Usage: .setwho <user> $[ahn]:<match>"
	end
	whois["$"..px..":"..pescape(dat):gsub("%%%*",".-")]=user
	return "Who set."
end)