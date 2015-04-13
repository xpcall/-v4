local crops={
	potato={
		plural="potatoes",
		crop={
			minYield=1,
			maxYield=5,
			growTime=14400,
		},
		color=5,
	},
	carrot={
		plural="carrots",
		crop={
			minYield=1,
			maxYield=10,
			growTime=7200,
		},
		color=7,
	},
	wheat={
		crop={
			minYield=1,
			maxYield=5,
			growTime=3600,
		},
		color=8,
	},
}
for k,v in pairs(crops) do
	if not rpgdata.items[k] then
		rpgdata.items[k]=v
	end
end
local function farmInfo(dat,crop)
	if not dat.farm then
		dat.farm={}
	end
	if crop then
		return dat.farm[crop]
	else
		return dat.farm
	end
end

hook.new("rpg_plant",function(dat,user,chan,txt)
	local it=rpg.findItem(txt)
	if not it then
		return "No such item"
	end
	if farmInfo(dat,it) then
		return "You are already farming "..rpg.itemName(it,true)
	end
	if not rpgdata.items[it].crop then
		return "Not a crop"
	end
	if not dat.items[it] then
		return "You do not have any "..rpg.itemName(it,true)
	end
	dat.farm[it]=socket.gettime()+rpgdata.items[it].crop.growTime
	return "Planted "..rpg.addItem(dat,it,-1)
end)

color=8,
hook.new("rpg_farm",function(dat,user,chan,txt)
	if txt=="" then
		local fm=farmInfo(dat)
		local o={}
		for k,v in pairs(fm) do
			local t=v-socket.gettime()
			if t>0 then
				table.insert(o,k..": "..toTime(t))
			else
				table.insert(o,k..": ready")
			end
		end
		if not next(o) then
			return "You are not farming anything"
		end
		return table.concat(o,", ")
	end
	local it=rpg.findItem(txt)
	if not it then
		return "No such item"
	end
	local cr=farmInfo(dat,it)
	if not cr then
		return "You arent farming that crop"
	end
	if cr<=socket.gettime() then
		dat.farm[it]=nil
		local c=rpgdata.items[it].crop
		local yield=math.random(c.minYield,c.maxYield)
		return "You harvest "..rpg.addItem(dat,it,yield)
	else
		return "You must wait "..toTime(cr-socket.gettime()).." until farming your "..rpg.itemName(it,true)
	end
end)
