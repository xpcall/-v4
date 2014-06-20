local sv=socket.bind("*",25476)
if sv then
	hook.newsocket(sv)
	local clients={}
	local htclients={}
	local last=socket.gettime()

	local function send(port,data,cl)
		for k,v in pairs(clients) do
			if v.open[port] and k~=cl then
				v:send(serialize({"message",port=dat.port,data=dat.data}))
			end
		end
		for k,v in pairs(htclients) do
			if v.open[dat.port] and k~=cl then
				local msg=serialize({"message",port=dat.port,data=dat.data,uid=k})
				table.insert(v.queue,1,msg)
				if hook.hooks["ht_msg"..k] then
					hook.queue("ht_msg"..k,msg)
					table.remove(v.queue,1)
				end
			end
		end
	end

	hook.new("select",function()
		local dt=socket.gettime()-last
		last=socket.gettime()
		local cl=sv:accept()
		if cl then
			cl=async.socket(cl)
			async.new(function()
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
		end
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
							
						elseif dat[1]=="open" and type(dat.ports)=="table" then
							for k,v in pairs(dat.ports) do
								cldat.open[k]=v~=false
							end
						end
					end
				end
			end
		end
		-- bit of garbage collection
		for uid,dat in tpairs(htclients) do
			if dat.tme then
				dat.tme=dat.tme+dt
				-- kill if it does not reconnect within 10 seconds of a timeout
				if dat.tme>10 then
					htclients[uid]=nil
				end
			end
		end
	end)

	local function tserialize(tbl)
		return serialize(tbl):sub(2,-2)
	end

	math.randomseed(socket.gettime()*1000)
	hook.new("page_tcpnet/uid",function(cl)
		local o=""
		for l1=1,24 do
			o=o..string.char(math.random(65,90))
		end
		return {type="text/plain",data=serialize({"uid",uid=o})}
	end)

	local function check(data,args)
		local func=loadstring("return {"..data.."}")
		for k,v in pairs(args) do
			if not type((data or {})[k]):match("^["..v.."]") then
				return nil,(data or {})[k]==nil and serialize({"error",data="missing "..k}) or serialize({"error",data="invalid type "..k})
			end
		end
	end

	hook.new("page_tcpnet/send",function(cl)
		local data,out=check(cl.post or cl.url:match("%?(.+)"),{uid="s",port="ns",data="ts"})
		if out then
			return {type="text/plain",data=out}
		end
		htclients[data.uid]=htclients[data.uid] or {queue={},open={}}
		send(data.port,data.data,data.uid)
	end)

	hook.new("page_tcpnet/open",function(cl)
		local data,out=check(cl.post or cl.url:match("%?(.+)"),{uid="s",ports="t"})
		if out then
			return {type="text/plain",data=out}
		end
		htclients[data.uid]=htclients[data.uid] or {queue={},open={}}
		for k,v in pairs(data.ports) do
			htclients[data.uid].open[k]=v or false
		end
	end)

	hook.new("page_tcpnet/receive",function(cl)
		local data,out=check(cl.post or cl.url:match("%?(.+)"),{uid="s"})
		if out then
			return {type="text/plain",data=out}
		end
		htclients[data.uid]=htclients[data.uid] or {queue={},open={}}
		local msg=async.pull(hook.timer(30),"ht_msg"..data.uid)
		return msg and {type="text/plain",data=msg} or {type="text/plain",data=serialize({"timeout",uid=data.uid})}
	end)
end
