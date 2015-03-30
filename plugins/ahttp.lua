ahttp={}
local cb={}
ahttp.callback=cb
local lport=network=="freenode" and 1339 or 1341
local cbp={}
local function prc(cid,url,post)
	local ptr=ffi.new("char*[1]")
	local thread=thread.new(function(cid,url,post,lport,ptr)
		local ffi=require("ffi")
		ptr=ffi.cast("char**",loadstring("return "..(ptr:match("0x%x+")).."ULL")())
		dofile("db.lua")
		local res,err,head,code
		if url:match("^https://") then
			local https=require("ssl.https")
			res,err,head,code=https.request(url,post)
		else
			local http=require("socket.http")
			res,err,head,code=http.request(url,post)
		end
		local out=serialize({res,err,head,code})
		local nout=ffi.new("char[?]",#out)
		ffi.copy(nout,out)
		ptr[0]=nout
		local sv=assert(socket.connect("localhost",lport))
		assert(sv:send(cid.."\n"))
	end,cid,url,post,lport,tostring(ptr))
	return ptr
end

--[===[local function prc(cid,url,post)
	cbd[cid]={url,post}
	local file=io.open("asynctemp.lua","w")
	file:write([[
		local url=]]..serialize(url)..[[
		local cid=]]..serialize(cid)..[[
		local post=]]..serialize(post)..[[
		local socket=require("socket")
		local function serialize(value, pretty)
			local kw = {
				["and"]=true,["break"]=true, ["do"]=true, ["else"]=true,
				["elseif"]=true, ["end"]=true, ["false"]=true, ["for"]=true,
				["function"]=true, ["goto"]=true, ["if"]=true, ["in"]=true,
				["local"]=true, ["nil"]=true, ["not"]=true, ["or"]=true,
				["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true,
				["until"]=true, ["while"]=true
			}
			local id = "^[%a_][%w_]*$"
			local ts = {}
			local function s(v, l)
				local t = type(v)
				if t == "nil" then
					return "nil"
				elseif t == "boolean" then
					return v and "true" or "false"
				elseif t == "number" then
					if v ~= v then
						return "0/0"
					elseif v == math.huge then
						return "math.huge"
					elseif v == -math.huge then
						return "-math.huge"
					else
						return tostring(v)
					end
				elseif t == "string" then
					return string.format("%q", v):gsub("\\\n","\\n"):gsub("%z","\\z")
				elseif t == "table" and pretty and getmetatable(v) and getmetatable(v).__tostring then
					return tostring(v)
				elseif t == "table" then
					if ts[v] then
						return "recursive"
					end
					ts[v] = true
					local i, r = 1, nil
					local f
					for k, v in pairs(v) do
						if r then
							r = r .. "," .. (pretty and ("\n" .. string.rep(" ", l)) or "")
						else
							r = "{"
						end
						local tk = type(k)
						if tk == "number" and k == i then
							i = i + 1
							r = r .. s(v, l + 1)
						else
							if tk == "string" and not kw[k] and string.match(k, id) then
								r = r .. k
							else
								r = r .. "[" .. s(k, l + 1) .. "]"
							end
							r = r .. "=" .. s(v, l + 1)
						end
					end
					ts[v] = nil -- allow writing same table more than once
					return (r or "{") .. "}"
				elseif t == "function" then
					return "func"
				elseif t == "userdata" then
					return "userdata"
				else
					if pretty then
						return tostring(t)
					else
						error("unsupported type: " .. t)
					end
				end
			end
			local result = s(value, 1)
			local limit = type(pretty) == "number" and pretty or 10
			if pretty then
				local truncate = 0
				while limit > 0 and truncate do
					truncate = string.find(result, "\n", truncate + 1, true)
					limit = limit - 1
				end
				if truncate then
					return result:sub(1, truncate) .. "..."
				end
			end
			return result
		end
		print("ahttp requesting")
		local res,err,head,code
		if url:match("^https://") then
			local https=require("ssl.https")
			res,err,head,code=https.request(url,post)
		else
			local http=require("socket.http")
			res,err,head,code=http.request(url,post)
		end
		local sv=assert(socket.connect("localhost",]]..lport..[[))
		sv:send(cid.."\n")
		assert(sv:send(serialize({res,err,head,code}):gsub("\n","").."\n"))
		print("ahttp sent")
	]])
	file:close()
	print("ahttp running")
	io.popen("luajit asynctemp.lua")
end]===]

server.listen(lport,function(cl)
	local cid=tonumber(cl.receive())
	cl.close()
	if not cb[cid] then
		error("invalid index "..tostring(cid))
	end
	local t,e=unserialize(ffi.string(cbp[cid][0]),true)
	if not t then
		error("Serialization error "..e)
	end
	cb[cid](unpack(t))
end)

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
	cbp[cid]=prc(cid,url,post)
	cb[cid]=async.current
	local res={coroutine.yield()}
	cb[cid]=nil
	cbp[cid]=nil
	return unpack(res)
end

setmetatable(http,{__call=function(s,url,data)
	data=data or {}
	if type(url)=="table" then
		data=url
	else
		data.url=url
	end
	if type(data)=="string" then
		data.post=data
	end
	data.method=data.method or (data.post and "POST") or (data.put and "PUT") or "GET"
	data.headers=data.headers or {}
	if data.auth then
		data.headers.Authorization="Basic "..tob64(data.auth)
	end
	if data.post or data.put then
		data.source=ltn12.source.string(data.post or data.put)
		data.headers["Content-Length"]=#(data.post or data.put)
	end
	local t={}
	data.sink=ltn12.sink.table(t)
	local b,c,h=(url:match("^https://") and https or http).request(data)
	return {result=b,data=table.concat(t),code=c,headers=h,url=data.url}
end})