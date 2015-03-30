rpgdata=persistf(network.."-rpg")
local data=rpgdata
if not data.active then data.active={} end
if not data.items then data.items={} end
if not data.users then data.users={} end
if not data.users then data.market={} end

hook.new("msg",function(user,chan,txt)
	local cmd,param=txt:match("^%)(%S+) ?(.*)")
	if cmd and data.active[chan] then
		if not user.account then
			return respond(user,user.nick..", you are not logged in")
		end
		if not data.users[user.account] then
			data.users[user.account]={}
		end
		local rs,err=xpcall(function()
			local res=hook.queue("rpg_"..cmd,data.users[user.account],user,chan,param)
			if res then
				respond(user,user.nick..", "..res)
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

local function itemName(n,p)
	local i=data.items[n]
	if not i then
		return false
	end
	return (p and i.plural or i.name) or n
end

local function findItem(n)
	for k,v in pairs(data.items) do
		if n:lower()==v.plural or (v.name or k):lower()==n:lower() then
			return k
		end
	end
	return false
end

local function findUser(n)
	local o=admin.perms[n]
	if not o or not o.account then
		return false
	end
	return o.account
end

local function purgeItem(n)
	data.items[n]=nil
	for k,v in pairs(market[n] or {}) do
		
	end
end

local function addItem(d,n,a)
	if a==0 then
		return ""
	end
	if not data.items[n] then
		data.items[n]={}
	end
	if not d.items then
		d.items={}
	end
	if not d.items[n] then
		d.items[n]={}
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

local begCooldown=3600
hook.new("rpg_beg",function(dat,user,chan,txt)
	if not dat.lastbeg then dat.lastbeg=0 end
	if socket.gettime()-dat.lastbeg<begCooldown then
		return "You must wait "..toTime(begCooldown-(socket.gettime()-dat.lastbeg)).." before begging again"
	end
	dat.lastbeg=socket.gettime()
	return "You get some change "..addItem(dat,"gold",math.random(1,100))
end)

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
		dat.items={}
	end
	local o={}
	for k,v in pairs(dat.items) do
		local amt=v.count or 0
		if amt~=0 then
			table.insert(o,amt.." "..itemName(k,amt<1))
		end
	end
	if not next(o) then
		return "Nothing"
	end
	return limitoutput(table.concat(o," "))
end)

local function sortMarket(n)
	local opts={}
	for k,v in pairs(data.market[it]) do
		local o=table.copy(v)
		o.seller=k
		table.insert(opts,o)
	end
	table.sort(opts,function(a,b)
		return a.price<b.price
	end)
	return opts
end

local function tryBuy(n,a)
	local opts=sortMarket(n)
	local o={}
	local tc=0
	while #opts>0 and a>0 do
		local c=opts[1]
		table.remove(opts,1)
		local am=math.min(c.count,a)
		a=a-am
		o[c.seller]=c.cost*am
		tc=tc+(c.cost*am)
	end
	if a>0 then
		return false
	end
	return tc,o
end

hook.new("rpg_cost",function(dat,user,chan,txt)
	local amt,item=txt:match("^(%S+) (.-)$")
	if amt then
		amt=tonumber(amt)
		if not amt then
			return "Usage: cost [<amount> ]<item>"
		end
		if amt~=floor(amt) then
			return "Amount must be an integer"
		elseif amt<1 then
			return "Amount must be greater than 0"
		end
		local it=findItem(item)
		if not item then
			return "Could not find item "..item
		end
		local tc,to=tryBuy()
		if #to>1 then
			local o={}
			for k,v in pairs(to) do
				local dm=data.market[k]
				table.insert(o,(dm.price*v).." gold / "..v.." ("..k..")")
			end
			return tc.." gold for "..amt.." "..itemName(it,amt>1).." "..paste(table.concat(o,"\n"))
		end
		return 
	else
		local it=findItem(item)
		if not item then
			return "Could not find item "..item
		end
		local opts=sortMarket(it)
		local ap=0
		for k,v in pairs(opts) do
			ap=ap+v.price
		end
		ap=math.round(ap/#opts,100)
		local o={}
		for k,v in pairs(opts) do
			table.insert(o,v.price.." gold * "..v.count.." ("..k..")")
		end
		if (#opts>5) then
			return "In stock: "..itemName(it,true).." Average price: "..ap.." gold "..paste(table.concat(o,"\n"))
		end
		return table.concat(o," | ")
	end
end)

hook.new("rpg_buy",function(dat,user,chan,txt)
	local amt,item=txt:match("^(%S+) (.-)$")
	if amt then
		if not tonumber(amt) then
			return "Usage: buy [<amount> ]<item>"
		end
	else
		item=txt
	end
	local it=findItem(item)
	if not item then
		return "Could not find item "..item
	end
	local opts=sortMarket(it)
	if not next(opts) then
		return itemName(it,true).." "..(data.items[it].plural and "arent" or "is not").." in the market"
	end
	if amt then
		amt=tonumber(amt)
		if amt~=floor(amt) then
			return "Amount must be an integer"
		elseif amt<1 then
			return "Amount must be greater than 0"
		end
		local tc,d=tryBuy(it,amt)
		if not tct then
			return "Not enough "..itemName(it,true).." in the market"
		end
		local cm=(dat.items.gold or {}).count or 0
		if tc>cm then
			return "You do not have "..(cm==0 and "any" or "enough").." gold"
		end
		for k,v in pairs(d) do
			local dm=data.market[k]
			local msg=addItem(data.users[k],"gold",v*dm.cost)
			for n,l in pairs(admin.perms) do
				if k==l.account then
					send("NOTICE "..n.." :"..user.nick.." bought "..v.." "..itemName(it,v>1).." "..msg)
				end
			end
			dm.count=dm.count-v
			if dm.count==0 then
				data.market[k]=nil
			end
		end
		addItem(dat,it,amt)
		return "Bought "..amt.." "..itemName(it,v>1).." for "..tc.." gold"
	else
		local ap=0
		for k,v in pairs(opts) do
			ap=ap+v.price
		end
		ap=ap/#opts
		local o={}
		for k,v in pairs(opts) do
			table.insert(o,v.price.." gold * "..v.count.." ("..k..")")
		end
		if (#opts>5) then
			return "In stock: "..itemName(it,true).." Average price: "..ap.." gold "..paste(table.concat(o,"\n"))
		end
		return table.concat(o," | ")
	end
end)


