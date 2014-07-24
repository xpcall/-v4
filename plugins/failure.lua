local fails={}
local file=io.open("db/"..network.."/fails","r")
if file then
	fails=unserialize(file:read("*a")) or {}
end
local function save()
	io.open("db/"..network.."/fails","w"):write(serialize(admin.ignore)):close()
end
hook.new("command_fail",function(user,chan,txt)
	return fails[math.random(1,#fails)]
end)
hook.new("command_addfail",function(user,chan,txt)
	if txt=="" then
		return "Usage: .addfail <failure>"
	end
	for k,v in pairs(fails) do
		if v==txt then
			return "Fail already exists"
		end
	end
	table.insert(fails,txt)
	save()
	return "Fail added"
end)