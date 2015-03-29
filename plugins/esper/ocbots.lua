local perms
do
	local file=io.open("db/esper/perms","r")
	if file then
		perms=unserialize(file:read("*a"))
	end
	perms=perms or {
		bot={},
		user={}
	}
end

local function save()
	local file=io.open("db/esper/perms","w")
	file:write(serialize(perms))
	file:close()
end

local function getAlias(usr)
	local m=admin.perms[usr] or type(usr)=="table" and usr
	for k,v in pairs(perms.user) do
		if m and admin.match(m,k) or k==usr then
			return k,v
		end
		for n,l in pairs(v.alias) do
			if m and admin.match(m,l) or l==usr then
				return k,v
			end
		end
	end
	local dat={
		level=0,
		alias={}
	}
	local ac
	if m then
		ac=m.account
		if ac then
			ac="$a:"..ac
		end
		ac=ac or m.host
	end
	usr=ac or usr
	perms.user[usr]=dat
	return usr,dat
end

local function getLevel(usr)
	local usr,dat=getAlias(usr)
	return (dat or {}).level
end

local function setLevel(user,txt,n)
	local usr,lvl=txt:match("^(.-) (%d+)$")
	usr=usr or txt
	lvl=tonumber(lvl) or (getLevel(usr)+n)
	if getLevel(user)<=lvl then
		save()
		return "Cannot "..(n>0 and "promote" or "demote").." user"
	end
	local tusr,dat=getAlias(usr)
	dat.level=lvl
	perms.user[tusr]=dat
	print((n>0 and "Promoted " or "Demoted ")..usr.." to level "..lvl)
	save()
end

hook.new("command_promote",function(user,chan,txt)
	return setLevel(user,txt,1)
end)

hook.new("command_demote",function(user,chan,txt)
	return setLevel(user,txt,-1)
end)

hook.new("command_regbot",function(user,chan,txt)
	if perms.bots[txt] then
		return "Bot already registered"
	end
	
end)