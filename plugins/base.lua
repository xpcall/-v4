reqplugin("tcpnet.lua")
local auth={
	["infinikiller64"]=true
}
if tcpnet then
	tcpnet.open("base_door")
	hook.new("tcpnet_message",function(port,dat)
		if port=="base_door" then
			local log=io.open("www/base_log.txt","a")
			log:write(timestamp().." "..dat.."\n")
			log:close()
			if auth[dat] then
				tcpnet.send("base_door","open")
			end
		end
	end)
	hook.new("page_base_cp",function(cl)
		
	end)
end
