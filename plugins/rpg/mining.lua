rpg.regItems({
	pickaxe={
		plural="pickaxes",
	},
	cobblestone={
		ore={
			weight=1000,
		},
		refine={
			{item="dust",weight=1000},
			{item="coal",weight=200},
			{item="iron",weight=100},
			{item="saphire",weight=50},
			{item="ruby",weight=50},
			{item="emerald",weight=50},
			{item="gold",weight=25,minYield=1,maxYield=50},
			{item="diamond",weight=10,minYield=1,maxYield=5},
			minRefineTime=60*60*5, --five minutes
			maxRefineTime=60*60*15, --fifteen minutes
		},
		color=14,
	},
	coal={
		ore={
			weight=200,
		},
		color=1,
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
		color=2,
	},
	ruby={
		plural="rubies",
		ore={
			weight=50,
		},
		color=4,
	},
	emerald={
		plural="emeralds",
		ore={
			weight=50,
		},
		color=3,
	},
	diamond={
		plural="diamonds",
		ore={
			weight=10,
			minYield=1,
			maxYield=5,
		},
		color=12,
	},
})

local mineCooldown=60
hook.new("rpg_mine",function(dat,user,chan,txt)
	if not dat.lastMine then
		dat.lastMine=0
	end
	if socket.gettime()-dat.lastMine>=mineCooldown then
		dat.lastMine=socket.gettime()
		local wt={}
		local tw=0
		for k,v in pairs(rpgdata.items) do
			if v.ore then
				local amt=1
				if v.ore.minYield and v.ore.maxYield then
					amt=math.random(v.ore.minYield,v.ore.maxYield)
				end
				wt[k]={tw+1,tw+v.ore.weight,amt}
				tw=tw+v.ore.weight
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
	if dat.beginRefine and dat.refineLength and dat.refineItem then
		if socket.gettime()-dat.beginRefine >= dat.refineLength then
			local it=rpg.findItem(txt)
			local wt={}
			local tw=0
			for k,v in ipairs(it.refine) do
				local amt=1
				if v.minYield and v.maxYield then
					amt=math.random(v.minYield,v.maxYield)
				end
				wt[k]={tw+1,tw+v.weight,amt}
				tw=tw+v.weight
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
			dat.beginRefine = nil
			dat.refineLength = nil
			dat.refineItem = nil
			return "Refined "..rpg.addItem(dat,it,amt)
		else
			return "Refining will finish in "..toTime(dat.refineLength-(socket.gettime()-dat.beginRefine))
		end
	else
		local it=rpg.findItem(txt)
		if not it then
			return "No such item"
		end
		if not it.refine then
			return "Cannot refine item"
		end
		dat.beginRefine = socket.gettime()
		dat.refineLength = math.random(it.minRefineTime,it.maxRefineTime)
		dat.refineItem = txt
		return "Refining will take "..toTime(dat.refineLength-(socket.gettime()-dat.beginRefine))
	end
end)
