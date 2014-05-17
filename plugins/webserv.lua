local function parsedate(txt)
	local day,month,year,time=txt:match("^%S+%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+:%S+)")
	if not day then
		day,month,year,time=txt:match("^%S+%s+(%S-)%-(%S-)%-(%S-)%s+(%S+:%S+)")
		if year then
			year=1900+tonumber(year)
		end
	end
	if not day then
		month,day,time,year=txt:match("^%S+%s+(%S+)%s+(%S+)%s+(%S+:%S+)%s+(%S+)")
	end
	if not day then
		return nil,txt
	end
	local hour,minute,second=time:match("(%d+):(%d+):(%d+)")
	if not hour then
		return nil,txt
	end
	local months={
		"jan","feb","mar","apr",
		"may","jun","jul","aug",
		"sep","oct","nov","dec",
	}
	for k,v in pairs(months) do
		months[v]=k
	end
	month=tostring(months[month:lower()])
	return ("0"):rep(4-#year)..year..("0"):rep(2-#month)..month..("0"):rep(2-#day)..day..("0"):rep(2-#hour)..hour..("0"):rep(2-#minute)..minute..("0"):rep(2-#second)..second
end

local function cmpdate(a,b)
	for l1=1,14 do
		local ca=tonumber(a:sub(l1,l1))
		local cb=tonumber(b:sub(l1,l1))
		if ca>cb then
			return -1
		elseif ca<cb then
			return 1
		end
	end
	return 0
end

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
	["jpg"]="image/jpeg",
	["jpeg"]="image/jpeg",
	["txt"]="text/plain",
}

local function form(cl,res)
	local cldat=cli[cl]
	local headers=res.headers or {}
	local code=res.code or "200 Found"
	headers["ETag"]=cldat.headers["ETag"]
	headers["Server"]="Less fail lua webserver"
	headers["Content-Length"]=headers["Content-Length"] or #(res.data or "")
	if headers["Content-Length"]==0 or cldat.method=="HEAD" then
		headers["Content-Length"]=nil
	end
	headers["Content-Type"]=headers["Content-Type"] or res.type or "text/html"
	headers["Connection"]=(headers["Connection"] or "Keep-Alive"):lower()
	local o="HTTP/1.1 "..code
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
		if res and headers["Connection"]=="keep-alive" then
			for k,v in pairs(cldat) do
				if k~="ip" then
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
local scripts={}
local function req(cl)
	local cldat=cli[cl]
	local url=cldat.url
	cldat.urldata=parseurl(url:match(".-%?(.+)") or "")
	if cldat.post then
		cldat.postdata=parseurl(cldat.post)
	end
	url=fs.resolve(url:match("(.-)%?.+") or url)
	local res=hook.queue("page_"..url,cldat)
	print("\""..url.."\"")
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
				if ext=="lua" then
					local func,err
					if scripts[bse] and scripts[bse].modified==fs.modified(bse) then
						func=scripts[bse].func
					else
						local data=fs.read(bse)
						func,err=loadstring(data,"="..url)
					end
					if not func then
						res.data=htmlencode(err)
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
							res=res,
						},{__index=_G})
						local err,out=xpcall(setfenv(func,e),debug.traceback)
						if type(out)=="function" then
							scripts[bse]={modified=parsedate(fs.modified(bse)),func=out}
							err,out=xpcall(setfenv(out,e),debug.traceback)
						end
						if not err then
							res.data=htmlencode(out)
							res.code="500 Internal Server Error"
							res.type="text/raw"
						else
							res.data=o
							res.code=e.code or "200 Found"
							res.type=res.type or "text/html"
						end
					end
				else
					res.headers={["Last-Modified"]=fs.modified(bse)}
					local parsed=parsedate(cldat.headers["If-Modified-Since"] or "")
					if parsed and cmpdate(parsed,parsedate(res.headers["Last-Modified"]))<1 then
						res.code="304 Not Modified"
					else
						res.data=fs.read(bse)
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