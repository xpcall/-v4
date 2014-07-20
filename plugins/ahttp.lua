ahttp={}
local cb={}
ahttp.callback=cb
local lport=network=="freenode" and 1339 or 1341
server.listen(lport,function(cl)
	local dat=cl.receive()
	cl.close()
	print("recv '"..dat.."'")
	local t=assert(unserialize(dat),dat)
	if cb[t[1]] then
		cb[t[1]](unpack(t,2))
	end
end)
local cb=ahttp.callback
ahttp={}
function ahttp.get(url,post)
	local cid
	for l1=1,20 do
		if not cb[l1] then
			cid=l1
			break
		end
	end
	if not cid then
		error("http request overflow")
	end
	local file=io.open("asynctemp.lua","w")
	file:write([[
		local url=]]..serialize(url)..[[
		local cid=]]..serialize(cid)..[[
		local post=]]..serialize(post)..[[
		local socket=require("socket")
		dofile("db.lua")
		local res,err
		if url:match("^https://") then
			local https=require("ssl.https")
			res,err=https.request(url,post)
		else
			local http=require("socket.http")
			res,err=http.request(url,post)
		end
		local sv=assert(socket.connect("localhost",]]..lport..[[))
		sv:send(serialize({cid,res,err}))
		sv:close()
	]])
	file:close()
	io.popen("luajit asynctemp.lua")
	cb[cid]=async.current
	return coroutine.yield()
end