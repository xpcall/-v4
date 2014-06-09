-- thread hax, uses a modified luasocket

--[=[local sel=assert(lanes.gen("*",function(recv,sendt,timeout)
	local socket=require("socket")
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
	mainlinda:send("out",out)
end))
function tsocket.receive()
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
	sel(crecv,csendt,timeout)
	while true do
		local k,dat=mainlinda:receive("select","event")
		if k=="select" then
			for k,v in tpairs(dat[1]) do
				dat[1][k]=sk[v]
				dat[1][sk[v]]=k
			end
			for k,v in tpairs(dat[2]) do
				dat[2][k]=sk[v]
				dat[2][sk[v]]=k
			end
			hook.queue("select",unpack(out))
		end
	end
end]=]