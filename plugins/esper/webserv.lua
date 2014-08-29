local sv=socket.bind("*",(config or {}).port or 8080)
if sv then
	print("Listening on port "..((config or {}).port or 8080))
	sv:settimeout(0)
	hook.newsocket(sv)
	local cli={}

	local function close(cl)
		cl:close()
		cli[cl]=nil
		while hook.remsocket(cl) do end
	end

	function urlencode(txt)
		return txt:gsub("\r?\n","\r\n"):gsub("[^%w ]",function(t) return string.format("%%%02X",t:byte()) end):gsub(" ","+")
	end

	function urldecode(txt)
		return txt:gsub("+"," "):gsub("%%(%x%x)",function(t) return string.char(tonumber("0x"..t)) end)
	end

	function htmlencode(txt)
		return txt:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub("\"","&quot;"):gsub("'","&apos;"):gsub("\r?\n","<br>"):gsub("\t","&nbsp;&nbsp;&nbsp;&nbsp;")
	end

	function parseurl(url)
		local out={}
		for var,dat in url:gmatch("([^&]+)=([^&]+)") do
			out[urldecode(var)]=urldecode(dat)
		end
		return out
	end

	local ctype={
		["html"]="text/html",
		["css"]="text/css",
		["ico"]="image/ico",
		["png"]="image/png",
		["jpg"]="image/jpeg",
		["jpeg"]="image/jpeg",
		["txt"]="text/plain",
		["zip"]="application/octet-stream",
		["jar"]="application/octet-stream",
		["oci"]="application/octet-stream",
		["swf"]="application/x-shockwave-flash",
	}

	local function defheaders(res,cldat)
		res.headers=res.headers or {}
		local headers=res.headers
		res.code=res.code or "200 Found"
		headers["Server"]="Less fail lua webserver"
		headers["Content-Length"]=headers["Content-Length"] or #(res.data or "")
		headers["Content-Type"]=headers["Content-Type"] or res.type or "text/html"
		headers["Connection"]=(headers["Connection"] or "Keep-Alive"):lower()
		if headers["Content-Length"]==0 or cldat.method=="HEAD" then
			headers["Content-Length"]=nil
		end
		return headers
	end

	local function enddata(cl,headers)
		local cldat=cli[cl]
		if headers["Connection"]=="keep-alive" then
			for k,v in pairs(cldat) do
				if k~="ip" and k~="sk" then
					cldat[k]=nil
				end
			end
			cldat.headers={}
		else
			close(cl)
		end
	end

	local trs={}
	local function formlarge(cl,res,fl)
		local cldat=assert(cli[cl])
		res.headers=res.headers or {}
		res.headers["Content-Length"]=sizeleft
		res.headers["Transfer-Encoding"]="chunked"
		res.headers["Trailer"]="ETag"
		res.headers["Derp"]="true"
		local headers=defheaders(res,cldat)
		local sizeleft=fs.size(fl)
		local o="HTTP/1.1 "..res.code
		for k,v in pairs(headers) do
			if v~="" then
				o=o.."\r\n"..k..": "..v
			end
		end
		o=o.."\r\n\r\n"
		if cldat.method=="HEAD" then
			async.new(function()
				local res,err=async.socket(cl).send(o)
			end)
			enddata(cl,headers)
			return
		end
		if trs[fl] then
			table.insert(trs[fl],async.socket(cl))
		else
			trs[fl]={async.socket(cl)}
			async.new(function()
				-- this will serve multiple clients at once
				async.wait(0.5) -- todo: configurable
				local clts=trs[fl]
				trs[fl]=nil
				for k,cl in tpairs(clts) do
					cl.send(o)
				end
				local file=io.open(fl,"r")
				local hash=crypto.digest.new("sha1")
				local amt,err,res,data
				while sizeleft>0 do
					amt=math.min(16384,sizeleft) -- todo: configurable
					data=file:read(amt)
					hash:update(data)
					for k,cl in tpairs(clts) do
						err,res=cl.send(string.format("%X",amt).."\r\n"..data.."\r\n")
						if not err then
							clts[k]=nil
						end
					end
					sizeleft=sizeleft-amt
				end
				local digest=hash:final()
				fs.sethash(fl,digest)
				for k,cl in pairs(clts) do
					cl.send("0\r\nETag: "..digest.."\r\n\r\n")
					enddata(cl.sk,headers)
				end
			end,print)
		end
	end

	local function form(cl,res)
		local cldat=cli[cl]
		local headers=defheaders(res,cldat)
		local o="HTTP/1.1 "..res.code
		for k,v in pairs(headers) do
			if v~="" then
				o=o.."\r\n"..k..": "..v
			end
		end
		o=o.."\r\n\r\n"
		if headers["Content-Length"] then
			o=o..res.data
		end
		async.new(function()
			local res,err=async.socket(cl).send(o)
			enddata(cl,headers)
		end,print)
	end

	local base="www"
	local scripts={}
	local function req(cl)
		local cldat=cli[cl]
		local url=cldat.url
		print("request "..cldat.ip.." : "..url)
		cldat.urldata=parseurl(url:match(".-%?(.*)") or "")
		if cldat.post then
			cldat.postdata=parseurl(cldat.post)
		end
		url=fs.resolve(url:match("(.-)%?.+") or url)
		local res=hook.queue("page_"..url,cldat)
		url=fs.split(url)
		local file=url[#url] or ""
		url=table.concat(url,"/")
		local bse=fs.combine(base,url):gsub("/$","")
		if not res then
			res={}
			if not fs.exists(bse) then
				res.data="<center><h1>404 Not found.</h1></center>"
				res.code="404 Not found"
			else
				if fs.isDir(bse) then
					local gt=false
					for k,v in pairs(fs.list(bse)) do
						if v:match("^index%.") then
							url=fs.combine(url,v)
							gt=true
							break
						end
					end
					if not gt then
						local o="<a href=\"/"..fs.resolve(url.."/../").."\">..</a><br>"
						for k,v in pairs(fs.list(bse)) do
							o=o.."<a href=\"/"..fs.combine(url,v):gsub("^/","").."\">"..htmlencode(v).."</a><br>"
						end
						res.data=o
					end
				end
				if not res.data then
					local bse=fs.combine(base,url):gsub("/$","")
					local ext=url:match(".+%.(.-)$") or ""
					res.type=ctype[ext]
					if ext=="lua" then
						local func,err
						if scripts[bse] and scripts[bse].modified==fs.modified(bse) then
							func=scripts[bse].func
						else
							local data=fs.read(bse)
							func,err=loadstring(data,"="..url)
						end
						if not func then
							res.data="<html>"..htmlencode(err).."</html>"
							print(err)
							res.code="500 Internal Server Error"
						else
							res.headers={}
							local o=""
							local e
							e=setmetatable({
								print=function(...)
									o=o..table.concat({...}," ").."\r\n"
								end,
								write=function(...)
									o=o..table.concat({...}," ")
								end,
								loadfile=function(file)
									local func,err=loadfile(file)
									if not func then
										return func,err
									end
									return setfenv(func,e)
								end,
								dofile=function(file)
									local func,err=loadfile(file)
									if not func then
										return func,err
									end
									return setfenv(func,e)()
								end,
								postdata=cldat.postdata,
								urldata=cldat.urldata,
								cl=cldat,
								res=res,
							},{__index=_G})
							e._G=e
							e._G2=_G
							local err,out=xpcall(setfenv(func,e),debug.traceback)
							if type(out)=="function" then
								scripts[bse]={modified=fs.modified(bse),func=out}
								err,out=xpcall(setfenv(out,e),debug.traceback)
							end
							if not err then
								res.data="<html>"..htmlencode(out).."</html>"
								res.code="500 Internal Server Error"
							else
								res.data=o
								res.code=res.code or "200 Found"
								res.type=res.type or "text/html"
							end
						end
					else
						if cldat.headers["If-None-Match"] and cldat.headers["If-None-Match"]==fs.hash(bse) then
							res.code="304 Not Modified"
						else
							if fs.size(bse)>16384 then -- TODO: configurable
								formlarge(cl,res,bse)
								return
							else
								res.data=fs.read(bse)
							end
						end
					end
				end
			end
		end
		form(cl,res)
	end

	hook.new("select",function()
		local cl=sv:accept()
		while cl do
			hook.newsocket(cl)
			cl:settimeout(0)
			cli[cl]={headers={},ip=cl:getpeername(),sk=cl}
			if (config or {logging=true}).logging then
				print("got client "..(cli[cl].ip or "BORK").." "..(hook.queue("command_find",nil,nil,"ip "..cli[cl].ip) or "").." "..(cl:getfd()))
			end
			cl=sv:accept()
		end
		for cl,cldat in pairs(cli) do
			local s,e=cl:receive(0)
			if not s and e=="closed" then
				print("closed "..cldat.ip)
				close(cl)
			else
				local s,e=cl:receive(tonumber(cldat.post and cldat.headers["Content-Length"]))
				if s then
					if cldat.post then
						cldat.post=s
						req(cl)
					elseif s=="" then
						if cldat.method=="POST" then
							cldat.post=""
						elseif cldat.method=="GET" or cldat.method=="HEAD" then
							req(cl)
						else
							form(cl,{
								code="405 Method Not Allowed",
								data="<center><h1>404 Not found.</h1></center>",
								headers={
									["Allow"]="GET, POST, HEAD"
								},
							})
						end
					else
						if not s:match(":") then
							cldat.method=s:match("^(%S+)")
							cldat.url=(s:match("^%S+ (%S+)") or ""):gsub("^/","")
						else
							cldat.headers[s:match("^(.-):")]=s:match("^.-: (.+)")
						end
					end
				end
			end
		end
	end)
end
