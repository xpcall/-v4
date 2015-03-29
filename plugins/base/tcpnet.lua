--[[reqplugin("tcpnetserv.lua")
local server=socket.connect("71.238.153.166",25476)
if server then
	tcpnet={}
	hook.newsocket(server)
	hook.new("select",function()
		local s=server:receive()
		if s then
			local dat=unserialize(s)
			if dat[1]=="message" then
				hook.queue("tcpnet_message",dat.port,dat.data)
			end
		end
	end)
	function tcpnet.send(port,data)
		server:send(serialize({"send",port=port,data=data}).."\n")
	end
	function tcpnet.open(port)
		server:send(serialize({"open",ports={[port]=true}}).."\n")
	end
	function tcpnet.close(port)
		server:send(serialize({"open",ports={[port]=false}}).."\n")
	end
end]]