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
					return string.format("%q", v):gsub("\\\n","\\n")
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
		local res,err
		if url:match("^https://") then
			local https=require("ssl.https")
			res,err=https.request(url,post)
		else
			local http=require("socket.http")
			res,err=http.request(url,post)
		end
		local sv=assert(socket.connect("localhost",]]..lport..[[))
		sv:send(serialize({cid,res,err}).."\n")
		
	]])
	file:close()
	io.popen("luajit asynctemp.lua")
	cb[cid]=async.current
	return coroutine.yield()
end