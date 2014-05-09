local sv=assert(socket.bind("*",80))
sv:settimeout(0)
hook.newsocket(sv)
local cli={}

local function close(cl)
	cl:close()
	cli[cl]=nil
	hook.remsocket(cl)
end

function urlencode(txt)
	return txt:gsub("\r?\n","\r\n"):gsub("[^%w ]",function(t) return string.format("%%%02X",t:byte()) end):gsub(" ","+")
end

function urldecode(txt)
	return txt:gsub("+"," "):gsub("%%(%x%x)",function(t) return string.char(tonumber("0x"..t)) end)
end

function htmlencode(txt)
	return txt:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub("\"","&quot;"):gsub("'","&apos;"):gsub("\r?\n","<br>")
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
	["png"]="image/png",
	["txt"]="text/plain",
}

local function form(cl,res)
	local cldat=cli[cl]
	local headers=res.headers or {}
	local code=code or "200 Found"
	headers["Server"]="Less fail lua webserver"
	headers["Content-Length"]=headers["Content-Length"] or #(res.data or "")
	headers["Content-Type"]=headers["Content-Type"] or res.type or "text/html"
	headers["Connection"]=(headers["Connection"] or "Keep-Alive"):lower()
	local o="HTTP/1.1 "..code
	for k,v in pairs(headers) do
		o=o.."\r\n"..k..": "..v
	end
	async.new(function()
		async.socket(cl).send(o.."\r\n\r\n"..res.data)
		if headers["Connection"]=="keep-alive" then
			for k,v in pairs(cldat) do
				if k~=ip then
					cldat[k]=nil
				end
			end
			cldat.headers={}
		else
			close(cl)
		end
	end)
end

local base="www"
local function req(cl)
	local cldat=cli[cl]
	local url=cldat.url
	cldat.urldata=parseurl(url:match(".-%?(.+)") or "")
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
					local o=""
					for k,v in pairs(fs.list(bse)) do
						o=o.."<a href=\""..fs.combine(url,v):gsub("^/","").."\">"..htmlencode(v).."</a><br>"
					end
					res.data=o
				end
			end
			if not res.data then
				local bse=fs.combine(base,url):gsub("/$","")
				local ext=url:match(".+%.(.-)$") or ""
				res.type=ctype[ext]
				local data=fs.read(bse)
				if ext=="lua" then
					local func,err=loadstring(data,"="..url)
					if not func then
						res.data=err:gsub("\n","<br>")
						res.code="500 Internal Server Error"
						res.type="text/raw"
					else
						local o=""
						local e=setmetatable({
							print=function(...)
								o=o..table.concat({...}," ").."\r\n"
							end,
							write=function(...)
								o=o..table.concat({...}," ")
							end,
							postdata=cldat.postdata,
							urldata=cldat.urldata,
							cl=cldat,
						},{__index=_G})
						local err,out=xpcall(setfenv(func,e),debug.traceback)
						if not err then
							res.data=out
							res.code="500 Internal Server Error"
							res.type="text/raw"
						else
							res.data=o
							res.code=e.code or "200 Found"
							res.type="text/html"
						end
					end
				else
					res.data=data
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
		cli[cl]={headers={},ip=cl:getpeername()}
		print("got client "..cli[cl].ip.." "..hook.queue("command_find",nil,nil,"ip "..cli[cl].ip))
		cl=sv:accept()
	end
	for cl,cldat in pairs(cli) do
		local s,e=cl:receive(0)
		if not s and e=="closed" then
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
					elseif cldat.method=="GET" then
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

hook.new("init",function()
	local alias={}
	local funcs={}
	local unlisted={}
	for k,v in pairs(hook.hooks) do
		local cmd=k:match("^command_(.*)")
		if cmd then
			local meta=hook.meta[k]
			if meta then
				alias[v[1]]=alias[v[1]] or {}
				table.insert(alias[v[1]],"."..cmd)
				funcs[v[1]]=meta
			else
				table.insert(unlisted,"."..cmd)
			end
		end
	end
	local groups={}
	for k,v in pairs(alias) do
		local meta=funcs[k]
		groups[meta.group]=groups[meta.group] or {}
		v.desc=meta.desc
		table.insert(groups[meta.group],v)
	end
	local file=io.open("www/help.html","w")
	for k,v in pairs(groups) do
		file:write("<h2>"..k.."</h2>")
		for n,l in pairs(v) do
			file:write(table.concat(l," ").." : "..l.desc.."<br>")
		end
	end
	file:write("<br>Unlisted (probably broken): "..table.concat(unlisted," "))
	file:close()
end)
