rpg.regItems({
	pickaxe={
		plural="pickaxes",
	},
	cobblestone={
		ore={
			weight=1000,
		},
		refine={
			{item="dust",weight=1000,minYield=1,maxYield=10},
			{item="coal",weight=200},
			{item="iron",weight=100},
			{item="gold",weight=50,minYield=10,maxYield=100},
			{item="microsaphire",weight=50},
			{item="microruby",weight=50},
			{item="microemerald",weight=50},
			{item="microdiamond",weight=10,minYield=1,maxYield=5},
			minTime=30,
			maxTime=80,
		},
		crush={
			{item="dust",weight=1,minYield=1,maxYield=100},
		},
		color=14,
	},
	dust={
		color=14,
	},
	coal={
		ore={
			weight=200,
		},
		refine={
			{item="dust",weight=10,minYield=1,maxYield=10},
			{item="gunpowder",weight=20,minYield=1,maxYield=20},
			minTime=60,
			maxTime=120,
		},
		color=1,
	},
	gunpowder={
		color=14,
	},
	iron={
		ore={
			weight=100,
		},
		color=15,
	},
	saphire={
		plural="saphires",
		ore={
			weight=50,
		},
		crush={
			{item="microsaphire",weight=1,minYield=1,maxYield=10},
		},
		color=2,
	},
	microsaphire={
		plural="microsaphires",
		color=12,
	},
	ruby={
		plural="rubies",
		ore={
			weight=50,
		},
		crush={
			{item="microruby",weight=1,minYield=1,maxYield=10},
		},
		color=4,
	},
	microruby={
		plural="microrubies",
		color=13,
	},
	emerald={
		plural="emeralds",
		ore={
			weight=50,
		},
		crush={
			{item="microemerald",weight=1,minYield=1,maxYield=10},
		},
		color=3,
	},
	microemerald={
		plural="microemeralds",
		color=9,
	},
	diamond={
		plural="diamonds",
		ore={
			weight=10,
			minYield=1,
			maxYield=5,
		},
		crush={
			{item="microdiamond",weight=1,minYield=1,maxYield=10},
		},
		color=11,
	},
	microdiamond={
		plural="microdiamonds",
		color=12,
	},
})

local function randomWeights(t)
	local wt={}
	local tw=0
	for k,v in pairs(t) do
		if tonumber(k) then
			local amt=1
			if v.minYield and v.maxYield then
				amt=math.random(v.minYield,v.maxYield)
			end
			wt[v.item]={tw+1,tw+v.weight,amt}
			tw=tw+v.weight
		end
	end
	local n=math.random(1,tw)
	local amt
	local it
	for k,v in pairs(wt) do
		if n>=v[1] and n<=v[2] then
			it=k
			amt=v[3]
			break
		end
	end
	return it,amt
end

local mineCooldown=60
hook.new("rpg_mine",function(dat,user,chan,txt)
	if not dat.lastMine then
		dat.lastMine=0
	end
	if socket.gettime()-dat.lastMine>=mineCooldown then
		dat.lastMine=socket.gettime()
		local wts={}
		for k,v in pairs(rpgdata.items) do
			if v.ore then
				table.insert(wts,{item=k,weight=v.ore.weight,minYield=v.ore.minYield,maxYield=v.ore.maxYield})
			end
		end
		local it,amt=randomWeights(wts)
		assert(it,"Fail "..serialize({n,tw,wt}))
		--[[if not dat.items.pickaxe then
			return "You do not have a pickaxe"
		end
		if math.random(1,100)==1 then
			return "Mined "..rpg.addItem(dat,it,amt).." "..rpg.addItem(dat,"pickaxe",-1)
		end]]
		return "Mined "..rpg.addItem(dat,it,amt)
	else
		return "You must wait "..toTime(mineCooldown-(socket.gettime()-dat.lastMine)).." before mining again"
	end
end)

hook.new("rpg_refine",function(dat,user,chan,txt)
	if dat.refineStart and dat.refineLength and dat.refineItem then
		if txt~="" then
			return "Refining in progress"
		end
		if socket.gettime()-dat.refineStart>=dat.refineLength then
			local ref=rpgdata.items[dat.refineItem].refine
			local it,amt=randomWeights(ref)
			dat.refineStart=nil
			dat.refineLength=nil
			dat.refineItem=nil
			return "Refined "..rpg.addItem(dat,it,amt)
		else
			return "Refining done in "..toTime(dat.refineLength-(socket.gettime()-dat.refineStart))
		end
	else
		local it=rpg.findItem(txt)
		if not it then
			return "No such item"
		end
		local ref=rpgdata.items[it].refine
		if not ref then
			return "Cannot refine item"
		end
		if not dat.items[it] or dat.items[it].count==0 then
			return "You do not have any "..rpg.itemName(it,true)
		end
		dat.refineStart=socket.gettime()
		dat.refineLength=math.random(ref.minTime,ref.maxTime)
		dat.refineItem=it
		return "Refining for "..toTime(dat.refineLength-(socket.gettime()-dat.refineStart)).." "..rpg.addItem(dat,it,-1)
	end
end)

hook.new("rpg_crush",function(dat,user,chan,txt)
	if txt=="" then
		return "Usage: crush <item>"
	end
	local it=rpg.findItem(txt)
	if not it then
		return "No such item"
	end
	local crs=rpgdata.items[it].crush
	if not crs then
		return "Cannot crush item"
	end
	if not dat.items[it] or dat.items[it].count==0 then
		return "You do not have any "..rpg.itemName(it,true)
	end
	local oit,amt=randomWeights(crs)
	return "Crushed "..rpg.addItem(dat,it,-1).." "..rpg.addItem(dat,oit,amt)
end)
