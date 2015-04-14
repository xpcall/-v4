local function sortMarket(n)
	local opts={}
	for k,v in pairs(rpgdata.market[n] or {}) do
		local o=table.copy(v)
		o.seller=k
		table.insert(opts,o)
	end
	table.sort(opts,function(a,b)
		return a.cost<b.cost
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
		o[c.seller]=am
		tc=tc+(c.cost*am)
	end
	if a>0 then
		return false
	end
	return tc,o
end

hook.new("rpg_cost",function(dat,user,chan,txt)
	local amt,item=txt:match("^(%S+) (.-)$")
	if amt or txt=="" then
		amt=tonumber(amt)
		if not amt then
			return "Usage: cost [<amount> ]<item>"
		end
		if amt~=math.floor(amt) then
			return "Amount must be an integer"
		elseif amt<1 then
			return "Amount must be greater than 0"
		end
		local it=rpg.findItem(item)
		if not it then
			return "Could not find item "..item
		end
		local tc,to=tryBuy(it,amt)
		if not tc then
			return "Not enough "..rpg.itemName(it,true).." in the market"
		end
		if #to>1 then
			local o={}
			for k,v in pairs(to) do
				local dm=rpgdata.market[k]
				table.insert(o,(dm.cost*v).." gold / "..v.." ("..k..")")
			end
			return tc.." gold for "..amt.." "..rpg.itemName(it,amt>1).." "..paste(table.concat(o,"\n"))
		end
		return tc.." gold for "..amt.." "..rpg.itemName(it,amt>1).." ( "..next(to).." )"
	else
		local it=rpg.findItem(txt)
		if not it then
			return "Could not find item "..txt
		end
		local opts=sortMarket(it)
		local ap=0
		for k,v in pairs(opts) do
			ap=ap+v.cost
		end
		ap=math.round(ap/#opts,100)
		local o={}
		for k,v in pairs(opts) do
			table.insert(o,v.cost.." gold * "..v.count.." ("..v.seller..")")
		end
		if (#opts>5) then
			return "In stock: "..rpg.itemName(it,true).." Average cost: "..ap.." gold "..paste(table.concat(o,"\n"))
		end
		return table.concat(o," | ")
	end
end)

hook.new("rpg_buy",function(dat,user,chan,txt)
	local amt,item=txt:match("^(%S+) (.-)$")
	amt=tonumber(amt)
	if not amt then
		return "Usage: buy <amount> <item>"
	end
	local it=rpg.findItem(item)
	if not it then
		return "Could not find item "..item
	end
	local opts=sortMarket(it)
	if not next(opts) then
		return rpg.itemName(it,true).." "..(rpgdata.items[it].plural and "arent" or "is not").." in the market"
	end
	if amt~=math.floor(amt) then
		return "Amount must be an integer"
	elseif amt<1 then
		return "Amount must be greater than 0"
	end
	local tc,d=tryBuy(it,amt)
	if not tc then
		return "Not enough "..rpg.itemName(it,true).." in the market"
	end
	local cm=(dat.items.gold or {}).count or 0
	if tc>cm then
		return "You do not have "..(cm==0 and "any" or "enough").." gold"
	end
	for k,v in pairs(d) do
		local dm=rpgdata.market[it][k]
		local msg=rpg.addItem(rpgdata.users[k],"gold",v*dm.cost)
		for n,l in pairs(admin.perms) do
			if k==l.account then
				send("NOTICE "..n.." :"..user.nick.." bought "..v.." "..rpg.itemName(it,v>1).." "..msg)
			end
		end
		dm.count=dm.count-v
		if dm.count==0 then
			rpgdata.market[it][k]=nil
		end
	end
	rpg.addItem(dat,it,amt)
	return "Bought "..amt.." "..rpg.itemName(it,amt>1).." "..rpg.addItem(dat,"gold",-tc)
end)

hook.new("rpg_sell",function(dat,user,chan,txt)
	if txt=="" then
		local item=txt:match("^(.-)$")
		local mks={}
		for k,v in pairs(rpgdata.market) do
			if v[user.account] then
				mks[k]=v[user.account]
			end
		end
		if not next(mks) then
			return "You are not selling anything"
		end
		if not next(mks,next(mks)) then
			local k,c=next(mks)
			return "You are selling "..c.count.." "..rpg.itemName(next(mks),c.count>1).." for "..c.cost.." gold"..(c.count>1 and " each" or "")
		end
		local o=""
		for k,v in pairs(mks) do
			o=o..v.count.." "..rpg.itemName(k,v.count>1).."*"..v.cost.." gold\n"
		end
		return "You are selling: "..limitoutput(o)
	end
	local amt,item,cost=txt:match("^(%S+) (.-) (%S+)$")
	amt=tonumber(amt)
	if not amt then
		item,cost=txt:match("^(.-) (%S+)$")
		if not tonumber(cost) then
			return "Usage: sell [[<amount> ]<item>[ <cost>],[item]]"
		end
	else
		if amt~=math.floor(amt) then
			return "Amount must be an integer"
		elseif amt<1 then
			return "Amount must be greater than 0"
		end
	end
	cost=tonumber(cost)
	if cost~=math.floor(cost) then
		return "cost must be an integer"
	elseif cost<1 then
		return "cost must be greater than 0"
	end
	local it=rpg.findItem(item)
	if not it then
		return "Could not find item "..item
	end
	if not rpgdata.market[it] then
		rpgdata.market[it]={}
	end
	if not rpgdata.market[it][user.account] then
		if not amt then
			return "You are not selling any "..rpg.itemName(it,true)
		end
		rpgdata.market[it][user.account]={}
	end
	local mk=rpgdata.market[it][user.account]
	mk.cost=cost
	if amt then
		rpg.addItem(dat,it,-amt)
		mk.count=(mk.count or 0)+amt
		return "Put "..amt.." "..rpg.itemName(it,amt>1).." on the market for "..cost.." gold"..(amt>1 and " each" or "")
	else
		return "Set price of your "..rpg.itemName(it,mk.count>1).." to "..cost.." gold"
	end
end)

hook.new("rpg_unsell",function(dat,user,chan,txt)
	local amt,item=txt:match("^(%S+) (.-)$")
	amt=tonumber(amt)
	if not amt then
		item=txt
	else
		if amt~=math.floor(amt) then
			return "Amount must be an integer"
		elseif amt<1 then
			return "Amount must be greater than 0"
		end
	end
	local it=rpg.findItem(item)
	if not it then
		return "Could not find item "..item
	end
	if not rpgdata.market[it] then
		rpgdata.market[it]={}
	end
	if not rpgdata.market[it][user.account] then
		return "You are not selling any "..rpg.itemName(it,true)
	end
	local mk=rpgdata.market[it][user.account]
	mk.cost=cost
	amt=amt or mk.count
	if mk.count<amt then
		return "You dont have "..amt.." "..rpg.itemName(it,amt>1).." on the market"
	end
	mk.count=mk.count-amt
	if mk.count==0 then
		rpgdata.market[it][user.account]=nil
	end
	return "Took item"..(amt>1 and "s" or "").." off the market "..rpg.addItem(dat,it,amt)
end)

hook.new("rpg_market",function(dat,user,chan,txt)
	local o=""
	if txt~="" then
		local it=rpg.findItem(txt)
		if not it then
			return "Could not find item "..txt
		end
		if not rpgdata.market[it] then
			return "No "..rpg.itemName(it,true).." in the market"
		end
		o=o..rpg.itemName(it,true,true)..": \n"
		local ps={}
		for k,v in pairs(rpgdata.market[it]) do
			local o=table.copy(v)
			o.seller=k
			table.insert(ps,o)
		end
		table.sort(ps,function(a,b)
			return a.cost<b.cost
		end)
		if next(ps) then
			for k,v in pairs(ps) do
				o=o.."    "..v.cost.." * "..v.count.." ( "..v.seller..")\n"
			end
		end
		return paste(o)
	end
	for k,v in pairs(rpgdata.market) do
		o=o..rpg.itemName(k,true,true)..":\n"
		local ps={}
		for n,l in pairs(rpgdata.market[k]) do
			local o=table.copy(l)
			o.seller=n
			table.insert(ps,o)
		end
		table.sort(ps,function(a,b)
			return a.cost<b.cost
		end)
		if next(ps) then
			for n,l in pairs(ps) do
				o=o.."    "..l.cost.." gold * "..l.count.." ( "..l.seller.." )\n"
			end
		end
	end
	return paste(o)
end)
