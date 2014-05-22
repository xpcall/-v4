local config={
	port=25476,
}
local clients={}
server.listen(config.port,function(cl)
	clients[cl.sk]={
		cl=cl,
		close=function(self)
			cl.close()
			clients[cl]=nil
		end,
		send=function(self,dat)
			cl.send(dat.."\n")
		end,
		open={},
	}
	hook.newsocket(cl.sk)
end)
hook.new("select",function()
	for cl,cldat in tpairs(clients) do
		local s,e=cl:receive(0)
		if not s and e=="closed" then
			cldat:close()
		else
			local dat,er=cl:receive()
			if dat then
				err,dat=pcall(unserialize,dat)
				if err and type(dat=="table") then
					if dat[1]=="send" and type(dat.port):match("^[sn]") then
						for k,v in pairs(clients) do
							if v.open[dat.port] and k~=cl then
								v:send(serialize({"message",port=dat.port,data=dat.data}))
							end
						end
					elseif dat[1]=="open" and type(dat.ports)=="table" then
						for k,v in pairs(dat.ports) do
							cldat.open[k]=v~=false
						end
					end
				end
			end
		end
	end
end)

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
end
