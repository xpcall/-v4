local sapis={
	math=math,
	string=string,
	bit32=bit32,
	table=table,
}
math.randomseed(os.time())
local sbox
local out
local step=0
--[[
	https://github.com/MightyPirates/OpenComputers/blob/master/src/main/resources/assets/opencomputers/lua/rom/lib/serialization.lua
]]
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
				if pretty then
					return "recursion"
				else
					error("tables with cycles are not supported")
				end
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

function unserialize(data)
	assert(type(data)=="string")
	local result, reason = loadstring("return " .. data, "=data")
	if not result then
		return nil, reason
	end
	local ok, output = pcall(setfenv(result,{math={huge=math.huge}}))
	if not ok then
		return nil, output
	end
	return output
end

sbox={
	serialize=serialize,
	unserialize=unserialize,
	_VERSION=_VERSION,
	assert=assert,
	collectgarbage=collectgarbage,
	error=error,
	getmetatable=getmetatable,
	ipairs=ipairs,
	load=function(ld,source,env)
		return load(ld,source,"t",env or sbox)
	end,
	next=next,
	pairs=pairs,
	pcall=pcall,
	print=function(...)
		for k,v in pairs({...}) do
			out=out..tostring(v).."\n"
		end
	end,
	rawequal=rawequal,
	rawget=rawget,
	rawlen=rawlen,
	rawset=rawset,
	select=select,
	setmetatable=setmetatable,
	tonumber=tonumber,
	tostring=tostring,
	type=type,
	xpcall=xpcall,
	os={
		clock=os.clock,
		date=os.date,
		difftime=os.difftime,
		time=os.time,
	},
	io={
		write=function(...)
			out=out..table.concat({...})
		end,
	},
	coroutine={
		create=function(func)
			local n=coroutine.create(func)
			debug.sethook(n,function()
				step=step+1
				if step>100 then
					debug.sethook(n)
					debug.sethook(n,function()
						error("Time limit exeeded.",0)
					end,"",1)
					error("Time limit exeeded.",0)
				end
			end,"",1000)
		end,
		resume=coroutine.resume,
		running=coroutine.running,
		status=coroutine.status,
		wrap=function(func)
			local n=sbox.coroutine.create(func)
			return function(...) coroutine.resume(n,...) end
		end,
		yield=coroutine.yield,
	},
}
sbox._G=sbox
for k,v in pairs(sapis) do
	sbox[k]={}
	for n,l in pairs(v) do
		sbox[k][n]=l
	end
end
out=""
local file=io.open("sbox.tmp","r")
local txt=file:read("*a")
file:close()
local func,err=load("return "..txt,"=lua","t",sbox)
if not func then
	func,err=load(txt,"=lua","t",sbox)
	if not func then
		print(err)
		return
	end
end
local func=coroutine.create(func)
debug.sethook(func,function()
	step=step+1
	if step>100 then
		debug.sethook(func)
		debug.sethook(func,function()
			error("Time limit exeeded.",0)
		end,"",1)
		error("Time limit exeeded.",0)
	end
end,"",1000)
local function maxval(tbl)
	local mx=0
	for k,v in pairs(tbl) do
		if type(k)=="number" then
			mx=math.max(k,mx)
		end
	end
	return mx
end
local res={coroutine.resume(func)}
local o
for l1=2,maxval(res) do
	o=(o or "")..tostring(res[l1]).."\n"
end
o=(out..(o or "nil")):gsub("^[\r\n]+",""):gsub("[\r\n]+$",""):gsub("[\r\n]+"," | ")
:gsub("[%z\2\4\5\6\7\8\9\10\11\12\13\14\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]","")
print(o)