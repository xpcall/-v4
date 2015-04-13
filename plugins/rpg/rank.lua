hook.new("rpg_rank",function(dat,user,chan,txt)
	local it="gold"
	if txt~="" then
		it=rpg.findItem(txt)
		if not it then
			return "Could not find item "..txt
		end
	end
	local o={}
	for k,v in pairs(rpgdata.users) do
		if not v.items then
			v.items={}
		end
		if v.items[it] then
			table.insert(o,{v.items[it].count,k})
		end
	end
	table.sort(o,function(a,b)
		return a[1]>b[1]
	end)
	local ot={}
	for l1=1,math.min(10,#o) do
		table.insert(ot,l1..") "..o[l1][2].." "..o[l1][1])
	end
	return "Rankings for "..it..": "..limitoutput(table.concat(ot,"\n"))
end)