rpg={}
local file=io.open("db/rpg","r")
if file then
	rpg=unserialize(file:read("*a"))
	if not rpg then
		srpg={}
	end
end
local function update()
	local file=io.open("db/rpg","w")
	file:write(serialize(rpg))
	file:close()
end
hook.new("msg",function(user,chan,txt,act)
	for k,v in pairs(rpg) do
		v.food=math.max(0,v.food-1)
		if math.random(1,10)==1 then
			v.fat=math.max(0,v.fat-1)
		end
	end
	if act and user.account and (chan=="#ocbots" or chan=="#ccbots") then
		local action,usr=txt:match("^(%S+) (.-)%s*$")
		action=string.lower(action or "")
		local uacc=user.account
		rpg[uacc]=rpg[uacc] or {hp=1000,food=0,fat=100}
		uacc=rpg[uacc]
		if action=="eats" then
			uacc.food=uacc.food+100
			local cn=math.random(-20,50)
			if uacc.food>=600 then
				uacc.hp=uacc.hp-100
				uacc.fat=uacc.fat+50
				update()
				return true,({
					user.nick.." falls through the floor",
					user.nick.." falls down stairs",
					user.nick.." fell because he forgot to tie his shoes",
					"mcdonalds gave "..user.nick.." the wrong meal",
					user.nick.." gets sick from eating too much",
				})[math.random(1,5)].." and loses 100 hp ( "..uacc.hp.." now )"
			elseif uacc.food>=500 then
				uacc.fat=uacc.fat+50
				update()
				return true,user.nick.." gains 50 fat ( "..uacc.fat.." now )"
			elseif uacc.food>=400 then
				uacc.fat=uacc.fat+10
				update()
				return true,user.nick.." gains 10 fat ( "..uacc.fat.." now )"
			end
			uacc.hp=uacc.hp+cn
			if cn>0 then
				update()
				return true,user.nick.." gains "..cn.." hp ( "..uacc.hp.." now )"
			elseif cn<0 then
				update()
				return true,usr.." makes "..user.nick.." constipated and loses "..math.abs(cn).." hp ( "..uacc.hp.." now )"
			end
		elseif admin.perms[usr] then
			local acc=(admin.perms[usr] or {}).account
			if acc then
				rpg[acc]=rpg[acc] or {hp=1000,food=0,fat=0}
				acc=rpg[acc]
				if action=="slaps" then
					if math.random(1,10)==1 then
						return true,user.nick.." misses."
					else
						local cn=math.random(1,10)
						acc.hp=acc.hp-cn
						update()
						return true,usr.." Loses "..cn.." hp ( "..acc.hp.." now )"
					end
				elseif action=="stabs" then
					if acc==uacc then
						local cn=math.random(10,100)
						uacc.hp=uacc.hp-cn
						return true,({
							user.nick.." likes cutting himself",
							user.nick.." opens the box of razors",
							user.nick.." jumps into a pit full of spikes",
							user.nick.." tried to cut a potato",
						})[math.random(1,4)].." and loses "..cn.." hp ( "..uacc.hp.." now )"
					elseif math.random(1,5)==1 then
						local cn=math.random(1,10)
						uacc.hp=uacc.hp-cn
						update()
						return true,({
							user.nick.." flails around a bit",
							user.nick.." misses",
							user.nick.." accidentally cut himselfs",
							user.nick.." held the knife the wrong way",
						})[math.random(1,4)].." and loses "..cn.." hp ( "..uacc.hp.." now )"
					else
						local cn=math.random(1,30)
						acc.hp=acc.hp-cn
						update()
						return true,({
							usr.." is cut into peices",
							usr.." looks like swiss cheeze",
							usr.." sits in a pool of his blood",
							usr.." was defenseless",
						})[math.random(1,4)].." and loses "..cn.." hp ( "..acc.hp.." now )"
					end
				elseif action=="dinifys" or action=="dinifies" then
					return true,"The universe breaks. Score: &e0"
				end
			end
		end
	end
end)

