local file=io.open("db/"..network.."/rpg","r")
local users={}
rpg={}
if file then
	users=unserialize(file:read("*a"))
	if not users then
		users={}
	end
end
local function save()
	local file=io.open("db/"..network.."/rpg","w")
	file:write(serialize(users))
	file:close()
end
rpg.users=users
local ac={
	attack={bites=true,stabs=true},
}
hook.new("msg",function(user,chan,txt,act)
	if act --[[and chan=="#dogebattles"]] then
		local action,touser=txt:match("^(.-) (%S+)$")
		touser=admin.perms[touser]
		if touser and touser.account then
			users[touser.account]=users[touser.account] or {
				hp=100,
				cd={},
			}
			atouser=users[touser.account]
			users[user.account]=users[user.account] or {
				hp=100,
				cd={},
			}
			auser=users[user.account]
			local function change(txt,user,num)
				user.hp=math.min(math.max(0,user.hp+num),100)
				save()
				if user.hp==0 then
					return txt.." and dies"
				else
					return txt.." ("..num.." hp, "..user.hp.." now)"
				end
			end
			if ac.attack[action] then
				if auser.hp==0 then
					return true,"Silly "..user.nick..", you cant attack while dead!"
				end
				if (atouser.cd.attacked or 0)>0 then
					return "Wait until they move again before attacking"
				end
				auser.cd.attacked=math.max(0,(auser.cd.attacked or 0)-2)
			end
			if action=="bites" then
				local damage=math.random(5,10)
				if user.nick==touser.nick then
					return true,change(user.nick.." bites themself",atouser,-damage)
				else
					atouser.cd.attacked=1
					return true,change(user.nick.." bites "..touser.nick,atouser,-damage)
				end
			elseif action=="stabs" then
				if math.random(1,5)==1 or user.nick==touser.nick then
					return true,change(user.nick.." flails around a bit and cuts themself",atouser,-math.random(1,10))
				else
					atouser.cd.attacked=1
					local damage=math.random(10,15)
					return true,change(user.nick.." stabs "..touser.nick,atouser,-damage)
				end
			elseif action=="" then
				
			end
		end
	end
end)

