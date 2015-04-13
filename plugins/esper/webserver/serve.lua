local config=webserver.config

function webserver.defHeaders(h)
	h=h or {}
	h.server=h.server or config.customServerHeader or ("PTServ "..webserver.version)
	h.connection=h.connection or "keep-alive"
	return h
end
local defHeaders=webserver.defHeaders

head_codes={
	[200]="OK",
	[302]="Found",
	[304]="Not Modified",
	[400]="Bad Request",
	[401]="Unauthorized",
	[403]="Forbidden",
	[404]="Not Found",
	[405]="Method not Allowed",
	[411]="Length Required",
}

local mime={
	["html"]="text/html",
	["lua"]="text/html",
	["css"]="text/css",
	["png"]="image/png",
	["bmp"]="image/bmp",
	["gif"]="image/gif",
	["jpg"]="image/jpeg",
	["jpeg"]="image/jpeg",
	["txt"]="text/plain",
	["zip"]="application/octet-stream",
	["gz"]="application/octet-stream",
	["tar"]="application/octet-stream",
	["exe"]="application/octet-stream",
	["jar"]="application/octet-stream",
	["download"]="application/octet-stream",
}

local function encodeChunked(txt)
	local out=""
	while #txt>1024 do
		out=out.."400\r\n"..txt:sub(1,1024).."\r\n"
		txt=txt:sub(1025)
	end
	return out..string.format("%x",#txt)..txt.."\r\n0\r\n\r\n"
end

function webserver.servehead(cl,res)
	print("serving")
	local headers=res.headers
	headers["Content-Type"]=headers["Content-Type"] or mime[res.format] or "text/plain"
	if cl.headers["Connection"]=="close" then
		res.headers["Connection"]="close"
	end
	res.code=tonumber(res.code) or 200
	local out="HTTP/1.1 "..res.code.." "..head_codes[res.code].."\r\n"
	res.data=res.data or ""
	if not headers["Content-Length"] and res.data then
		headers["Content-Length"]=#res.data
	end
	for k,v in pairs(headers) do
		out=out..k..": "..tostring(v).."\r\n"
	end
	cl.send(out.."\r\n")
end

function webserver.serveres(cl,res)
	local out=""
	webserver.servehead(cl,res)
	if cl.method~="head" then
		out=out..(res.headers["Transfer-Encoding"]=="chunked" and encodeChunked(res.data) or res.data)
	end
	cl.onDoneSending=res.headers["connection"]=="close" and cl.close or webserver.receivehead
	cl.send(out)
end

local function err(cl,code,h)
	local res={
		code=code,
		headers=defHeaders(h),
		format="html",
	}
	if code==405 then
		res.headers.allowed="GET, POST, HEAD"
	end
	res.data="<center><h1>Error "..code..": "..assert(head_codes[code],code).."</h1></center>"
	webserver.serveres(cl,res)
end

--local largef={}
local configmodified=fs.modified(webserver.configfile)
function webserver.serve(cl)
	-- reload config
	if configmodified~=fs.modified(webserver.configfile) then
		configmodified=fs.modified(webserver.configfile)
		loadconfig()
	end
	
	local domain=(cl.headers["Host"] or ""):match("^[^:]*")
	local dconfig=config.domains[domain]
	
	if dconfig.proxy then
		local host,port=dconfig.proxy:match("^%[?(.+)%]?:(.-)$")
		print("proxy "..(host or dconfig.proxy)..":"..(port or 80))
		local sv=client.new(socket.connect(host or dconfig.proxy,port or 80),true)
		local h=cl.method:upper().." "..cl.url.." HTTP/1.1\r\n"
		for k,v in pairs(cl.headers) do
			h=h..k..": "..v.."\r\n"
		end
		print(h)
		sv.send(h.."\r\n")
		sv.onReceive=function()
			print("proxy sv receive")
			cl.send(sv.rbuffer)
			sv.rbuffer=""
		end
		cl.onReceive=function()
			print("proxy cl receive")
			sv.send(cl.rbuffer)
			cl.rbuffer=""
		end
		sv.onClose=cl.close
		cl.onClose=sv.close
		return
	end

	if not cl.path then
		return err(cl,400)
	end
	
	print("get "..cl.path)

	cl.rpath=fs.combine(dconfig.dir,cl.path)
	
	if cl.method~="post" and cl.method~="get" and cl.method~="head" then
		return err(cl,405)
	end
	
	local path=cl.rpath
	local ext=path:match("%.(.-)$") or "txt"
	local ores=hook.queue("page",cl) or hook.queue("page_"..fs.resolve(cl.path),cl)
	if ores then
		ores.headers=defHeaders(ores.headers)
		ores.code=ores.code or 200
		ores.format=ores.format or "txt"
		return webserver.serveres(cl,ores)
	end
	local res={
		headers=defHeaders(),
		code=200,
		format=ext,
	}
	if dconfig.redirect then
		return err(cl,302,{["Location"]=dconfig.redirect})
	elseif not fs.exists(path) then
		return err(cl,404)
	elseif ext=="lua" then
		res.format="html"
		return webserver.runlua(fs.read(path),cl,res)
	else
		if fs.isDir(path) then
			local found
			local dirout='<h3><a href="..">..</a><br>'
			for k,v in pairs(fs.list(path)) do
				local p="/"..fs.combine(cl.path,v)
				dirout=dirout..'<a href="'..p..'">'..v..'</a><br>'
				if v:match("^index%..+") then
					path=fs.combine(path,v)
					res.format=path:match("%.(.-)$") or "txt"
					found=true
					break
				end
			end
			if not found then
				res.format="html"
				res.data=dirout
				res.code=200
				return webserver.serveres(cl,res)
			end
		end
		-- todo: better large file support
		--[[if fs.size(path)>16384 then
			if largef[path] then
				table.insert(largef[path],{cl,res})
			else
				largef[path]={{cl,res}}
				hook.new(hook.timer(0.5),function()
				end)
			end
		end]]
		local nm=(cl.headers["If-None-Match"] or ""):match('^"(%x+)"$')
		if nm then
			if fs.modified(path)==tonumber(nm,16) then
				return err(cl,304)
			end
		end
		res.data=fs.read(path)
		res.headers["ETag"]='"'..string.format("%X",fs.modified(path))..'"'
		--res.headers["Cache-Control"]=""
		print("serving "..path)
		webserver.serveres(cl,res)
	end
end

