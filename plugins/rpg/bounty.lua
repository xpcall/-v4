if not rpgdata.bounty then
	rpgdata.bounty={}
end

hook.new("msg",function(user,chan,txt)
	if rpgdata.active[chan] and user.account then
		if not rpgdata.users[user.account] then
			rpgdata.users[user.account]={}
		end
		local dg={}
		local o={}
		for k,v in tpairs(rpgdata.bounty) do
			local dtype,digest=k:match("^(.-):(.-)$")
			if not dg[dtype] then
				assert(crypt.hash[dtype],"invalid hash "..dtype)
				dg[dtype]=crypt.hash[dtype](txt)
				print("hash of \""..txt.."\" is "..dg[dtype])
			end
			if digest==dg[dtype] then
				for n,l in pairs(v) do
					table.insert(o,rpg.addItem(rpgdata.users[user.account],l[1],l[2]))
				end
				rpgdata.bounty[k]=nil
			end
		end
		if next(o) then
			respond(user,user.nick..", That phrase had a bounty "..table.concat(o," "))
		end
	end
end)

hook.new("rpg_bounty",function(dat,user,chan,txt)
	local dtype,digest,amt,item=txt:match("^(%S+) (%S+) (%S+) (.-)$")
	amt=tonumber(amt)
	if not amt then
		return "Usage: bounty <type> <hash> <amount> <item>"
	end
	dtype=dtype:lower()
	if not crypt.hash[dtype] then
		return "No such hash"
	end
	if #crypt.hash[dtype]("")~=#digest then
		return "Invalid hash"
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
	local cm=(dat.items[it] or {}).count or 0
	if amt>cm then
		return "You do not have "..(cm==0 and "any" or "enough").." "..rpg.itemName(it,true)
	end
	if not rpgdata.bounty[dtype..":"..digest] then
		rpgdata.bounty[dtype..":"..digest]={}
	end
	local bt=rpgdata.bounty[dtype..":"..digest]
	bt[#bt+1]={it,amt}
	return "Set bounty "..rpg.addItem(dat,it,-amt)
end)

