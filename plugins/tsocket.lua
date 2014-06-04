-- thread hax, uses a modified luasocket

local sel=lanes.linda()
function socket.select(recv,sendt,timeout)
	local crecv={}
	local sk={}
	for k,v in pairs(recv) do
		crecv[k]=v:getfd()
		sk[crecv[k]]=v
	end
	local csendt={}
	for k,v in pairs(sendt) do
		csendt[k]=v:getfd()
		sk[csendt[k]]=v
	end
	local dat=assert(lanes.gen("*",function(recv,sendt,timeout)
		local socket=require("socket")
		-- remake sockets
		local crecv={}
		for k,v in pairs(recv) do
			crecv[k]=socket.client(v)
		end
		local csendt={}
		for k,v in pairs(sendt) do
			csendt[k]=socket.client(v)
		end
		local orecv,osendt,err=socket.select(crecv,csendt,timeout)
		if not orecv then
			return nil,nil,err
		end
		local out={{},{},err}
		-- put them back into number form
		for k,v in ipairs(orecv) do
			table.insert(out[1],v:getfd())
			v:setfd(-1) -- set socket to invalid so it wont close on GC
		end
		for k,v in ipairs(osendt) do
			table.insert(out[2],v:getfd())
			v:setfd(-1)
		end
		sel:send("out",out)
	end))(crecv,csendt,timeout)
	local k,out=sel:receive("out")
	for k,v in tpairs(out[1]) do
		out[1][k]=sk[v]
		out[1][sk[v]]=k
	end
	for k,v in tpairs(out[2]) do
		out[2][k]=sk[v]
		out[2][sk[v]]=k
	end
	return out[1],out[2],out[3]
end