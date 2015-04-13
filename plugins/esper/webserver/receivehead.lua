function webserver.receivehead(cl)
	cl.headers={}
	cl.method=nil
	cl.url=nil
	cl.path=nil
	cl.postraw=nil
	cl.postlen=nil
	cl.post=nil
	cl.get=nil
	cl.getraw=nil
	cl.onReceive=function(line)
		if not cl.url then
			local line=cl.receive()
			if line then
				local method,url=line:match("^(%S+) (.-) HTTP/.%..$")
				if url then
					cl.url=url
					cl.getraw=url:match("%?(.*)") or ""
					cl.get=parsepost(cl.getraw)
					cl.path=fs.resolve(url:match("^[^%?]*"):match("^/?(.-)/?$"))
					cl.method=method:lower()
				end
			end
		end
		if cl.postlen then
			local data=cl.receive(cl.postlen)
			if data then
				cl.postraw=data
				cl.post=parsepost(data)
				cl.onReceive=nil
				return webserver.serve(cl)
			end
		else
			local line=cl.receive()
			while line do
				if line=="" then
					return webserver.serve(cl)
				end
				local header,val=line:match("(%S+): (.+)")
				if header then
					cl.headers[header]=val
				end
				line=cl.receive()
			end
		end
	end
end
