rpgdata=persistf(network.."-rpg")
local data=rpgdata
if not data.active then data.active={} end
if not data.items then data.items={} end
if not data.users then data.users={} end
if not data.market then data.market={} end
rpg={}

hook.new("msg",function(user,chan,txt)
	local cmd,param=txt:match("^%)(%S+) ?(.*)")
	if cmd and data.active[chan] then
		if not user.account then
			return respond(user,user.nick..", you are not logged in")
		end
		if not data.users[user.account] then
			data.users[user.account]={}
		end
		local dat=data.users[user.account]
		if not dat.items then
			dat.items={soul={count=1}}
		end
		local rs,err=xpcall(function()
			local res=hook.queue("rpg_"..cmd,data.users[user.account],user,chan,param)
			if res then
				respond(user,"\15"..user.nick..", "..res)
			end
		end,debug.traceback)
		if not rs then
			respond(user,"crash "..limitoutput(err))
		end
	end
end)

local floor=math.floor
local rt={
	["millisecond"]=0.001,
	["second"]=1,
	["minute"]=60,
	["hour"]=3600,
	["day"]=86400,
	["week"]=604800,
	["month"]=2629800,
}
local wt={
	["milisecond"]=1000,
	["second"]=60,
	["minute"]=60,
	["hour"]=24,
	["day"]=7,
	["week"]=7,
	["month"]=12,
}

function toTime(s)
	if s==math.huge then
		return "Never"
	elseif s==1/0 or s~=s then
		return "Unknown"
	end
	local sr=""
	if s<0 then
		sr=" ago"
		s=math.abs(s)
	end
	local function c(n)
		local t=floor(s/rt[n])
		if wt[n] then
			t=t%wt[n]
		end
		return t.." "..n..(t>1 and "s" or "")
	end
	if s<1 then
		return c("millisecond")..sr
	elseif s<60 then
		return c("second")..sr
	elseif s<3600 then
		if (s/60<5) then
			return c("minute").." "..c("second")..sr
		end
		return c("minute")..sr
	elseif s<86400 then
		return c("hour").." "..c("minute")..sr
	elseif s<604800 then
		return c("day").." "..c("hour")..sr
	else
		return c("week").." "..c("day")..sr
	end
end

local function itemName(n,p,f)
	local i=data.items[n]
	if not i then
		return false
	end
	if not f then
		local clr=""
		if i.color then
			clr="\3"..("0"):rep(2-(#tostring(i.color)))..i.color
		end
		return "\2"..clr..((p and i.plural or i.name) or n).."\15"
	else
		return (p and i.plural or i.name) or n
	end
end
rpg.itemName=itemName

local function findItem(n)
	for k,v in pairs(data.items) do
		if n:lower()==v.plural or (v.name or k):lower()==n:lower() then
			return k
		end
	end
	return false
end
rpg.findItem=findItem

local function findUser(n)
	local o=admin.perms[n]
	if not o then
		return false
	end
	return o.account
end
rpg.findUser=findUser

local function purgeItem(n)
	data.items[n]=nil
	data.market[n]=nil
	for k,v in pairs(rpgdata.users) do
		if (v.items or {})[n] then
			v.items[n]=nil
		end
	end
end
rpg.purgeItem=purgeItem

local function renameItem(n,ni)
	data.items[n]=nil
	data.market[n]=nil
	for k,v in pairs(rpgdata.users) do
		if (v.items or {})[n] then
			v.items[n]=nil
		end
	end
end
rpg.purgeItem=purgeItem

local function addItem(d,n,a)
	if a==0 then
		return ""
	end
	if not data.items[n] then
		data.items[n]={}
	end
	if not d.items then
		d.items={soul={count=1}}
	end
	if not d.items[n] then
		d.items[n]={count=0}
	end
	local it=d.items[n]
	if not it.count then
		it.count=0
	end
	it.count=it.count+a
	if it.count==0 then
		d.items[n]=nil
	end
	return "( "..(a>0 and "+" or "")..a.." "..itemName(n,a>1).." )"
end
rpg.addItem=addItem

function rpg.regItems(t)
	for k,v in pairs(t) do
		if not rpgdata.items[k] then
			rpgdata.items[k]=v
		end
	end
end

rpg.regItems({
	gold={
		color=8,
	},
	soul={
		plural="souls",
		color=0,
	},
})

hook.new("rpg_give",function(dat,user,chan,txt)
	local usr,amt,item=txt:match("^(%S+) (%S+) (.-)$")
	if not user or not tonumber(amt) then
		return "Usage: give <user> <amount> <item>"
	end
	local ut=findUser(usr)
	if not ut then
		return "Could not find user "..usr
	end
	amt=tonumber(amt)
	if amt~=floor(amt) then
		return "Amount must be an integer"
	elseif amt<1 then
		return "Amount must be greater than 0"
	end
	local it=findItem(item)
	if not it then
		return "Could not find item "..item
	end
	if not dat.items[it] or dat.items[it].count<amt then
		return "You do not have "..((dat.items[it] and amt>1) and "enough" or (data.items[it].plural and "a" or "any")).." "..itemName(it,amt>1)
	end
	
	addItem(dat,it,-amt)
	if not data.users[ut] then
		data.users[ut]={}
	end
	addItem(data.users[ut],it,amt)
	return "Gave "..usr.." "..amt.." "..itemName(it,amt>1)
end)

hook.new("rpg_inv",function(dat,user,chan,txt)
	if not dat.items then
		dat.items={soul={count=1}}
	end
	local o={}
	for k,v in pairs(dat.items) do
		local amt=v.count or 0
		if amt~=0 then
			table.insert(o,amt.." "..itemName(k,amt>1))
		end
	end
	if not next(o) then
		return "Nothing"
	end
	return table.concat(o," ")
end)

hook.new("rpg_pinv",function(dat,user,chan,txt)
	if not dat.items then
		dat.items={soul={count=1}}
	end
	local o={}
	for k,v in pairs(dat.items) do
		local amt=v.count or 0
		if amt~=0 then
			table.insert(o,amt.." "..itemName(k,amt>1))
		end
	end
	if not next(o) then
		return "Nothing"
	end
	send("NOTICE "..user.nick.." :"..table.concat(o," "))
end)

for k,v in pairs(fs.list("plugins/rpg")) do
	reqplugin("rpg/"..v)
end
