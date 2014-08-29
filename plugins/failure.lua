local fails={}
local file=io.open("db/"..network.."/fails","r")
if file then
	fails=unserialize(file:read("*a")) or {}
end
local function save()
	io.open("db/"..network.."/fails","w"):write(serialize(fails,math.huge)):close()
end

hook.new("command_fail",function(user,chan,txt)
	if txt~="" and not tonumber(txt) then
		return "["..txt.."] "..user.nick
	end
	if tonumber(txt) then
		if fails[tonumber(txt)] then
			return "["..tonumber(txt).."] "..fails[tonumber(txt)]
		end
		return "Not found"
	end
	local m=1
	for k,v in pairs(fails) do
		m=math.max(k,m)
	end
	local o,n
	while not o do
		n=math.random(1,m)
		o=fails[n]
	end
	return "["..n.."] "..o
end)

hook.new("command_addfail",function(user,chan,txt)
	if txt=="" then
		return "Usage: .addfail <failure>"
	end
	local i=0
	while true do
		i=i+1
		if not fails[i] then
			fails[i]=txt
			break
		elseif fails[i]==txt then
			return "Fail already exists"
		end
	end
	save()
	return "Fail "..i.." added"
end)

hook.new("command_delfail",function(user,chan,txt)
	if not tonumber(txt) then
		return "Error removing "..user.nick
	elseif not fails[tonumber(txt)] then
		return "No such fail"
	end
	fails[tonumber(txt)]=nil
	save()
	return "Deleted fail "..tonumber(txt)
end)

