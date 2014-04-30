local sv=assert(socket.bind("*",8080))
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
	return txt:gsub("%%(%x%x)",function(t) return tonumber("0x"..t) end)
end
function parseurl(url)
	local txt=url:match(".-%?(.+)") or ""
	local out={}
	for var,dat in txt:gmatch("([^&]+)=([^&]+)") do
		out[urldecode(var)]=urldecode(dat)
	end
	return out
end
local function req(cl)
	local cldat=cli[cl]
	local res=hook.queue("page",cldat) or {}
	if not res.data then
		res=hook.queue("page_"..cldat.url,cldat) or {}
		if not res.data then
			res={
				data="<center><h1>Error 404 Not found</h1></center>",
				code="404 Not found",
			}
		end
	end
	res.headers=res.headers or {}
	res.headers["Content-Length"]=#res.data
	res.code=res.code or "200 Found"
	res.headers["Content-Type"]=res.type or "text/html"
	local o="HTTP/1.1 "..res.code
	for k,v in pairs(res.headers) do
		o=o.."\r\n"..k..": "..v
	end
	cl:send(o.."\r\n\r\n"..res.data)
	close(cl)
end
hook.new("select",function()
	local cl=sv:accept()
	while cl do
		hook.newsocket(cl)
		cli[cl]={headers={},ip=cl:getpeername()}
		cl=sv:accept()
	end
	for cl,cldat in pairs(cli) do
		local s,e=cl:receive(0)
		if not s and e=="closed" then
			cl:close()
			cli[cl]=nil
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
						close(cl)
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
