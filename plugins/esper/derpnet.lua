--[[local info,save
local pub,priv
local p_network,p_master

do
	local file=io.open("pass/derpnet_master.txt","r")
	p_master=file:read("*a"):match("[^\r\n]+")
	file:close()
	local file=io.open("pass/derpnet_network.txt","r")
	p_network=file:read("*a"):match("[^\r\n]+")
	file:close()
	local function default()
		local pub,priv=1
		return {
			pub=1,
			priv=1,
			peers={},
		}
	end
	local file=io.open("db/derpnet","r")
	if file then
		info=unserialize(file:read("*a")) or default()
	else
		info=default()
	end
	local function save()
		local file=io.open("db/derpnet","w")
		file:write(serialize(info))
		file:close()
	end
end

local port=56384
local sv=server.listen(port,function(cl)
	local authed
	while true do
		local line=cl.receive()
		local data=unserialize(line)
		local tpe=data[1]
		if type(data)~="table" then
			cl.close()
			return
		end
		if not authed then
			if tpe=="start" then
				
			end
		else
			
		end
	end
end)]]