rpg.regItems({
	pickaxe={
		plural="pickaxes",
	},
	cobblestone={
		ore={
			weight=1000,
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
			if n>v[1] and n<v[2] then
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
