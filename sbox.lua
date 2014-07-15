local sapis={
	math=math,
	string=string,
	bit32=bit32,
	table=table,
	coroutine=coroutine,
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
	local result, reason = load("return " .. data,"=unserialize","t",{math={huge=math.huge}})
	if not result then
		return nil, reason
	end
	local ok, output = pcall(result)
	if not ok then
		return nil, output
	end
	return output
end

function numstr(num)
	if num==math.huge then
		return "inf"
	elseif num==-math.huge then
		return "-inf"
	elseif num~=num then
		return "nan"
	end
	local top=math.floor(num)
	local stop=""
	for i=0,100 do
		local c=math.floor(math.floor(top/(10^i))%10)
		for l1=0,9 do
			if tonumber(((c+l1)%10)..stop..".0")==top then
				stop=((c+l1)%10)..stop
				break
			end
		end
		if tonumber(stop..".0")==top then
			break
		end
		stop=c..stop
	end
	local btm=num-top
	local sbtm=""
	for i=1,100 do
		local c=math.floor((btm*(10^i))%10)
		for l1=0,9 do
			if tonumber(stop.."."..sbtm..((c+l1)%10))==num then
				sbtm=sbtm..((c+l1)%10)
				break
			end
		end
		if tonumber(stop.."."..sbtm)==num then
			break
		end
		sbtm=sbtm..c
	end
	return (stop=="" and "0" or stop).."."..(sbtm=="" and "0" or sbtm)
end

local fmtb=setmetatable({},{__mode="v"})

sbox={
	numstr=numstr,
	serialize=serialize,
	unserialize=unserialize,
	_VERSION=_VERSION,
	assert=assert,
	collectgarbage=collectgarbage,
	error=error,
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
	debug={
		traceback=debug.traceback
	}
}
local function no(name)
	for k,v in pairs(_G[name]) do
		sbox[name][k]=sbox[name][k] or "no"
	end
end
no("io")
no("os")
no("debug")
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
		print("Program done.")
		return
	end
end
local res={pcall(func)}
local o
local function maxval(tbl)
	local mx=0
	for k,v in pairs(tbl) do
		if type(k)=="number" then
			mx=math.max(k,mx)
		end
	end
	return mx
end
for l1=2,math.max(2,maxval(res)) do
	o=(o or "")..tostring(res[l1]).."\n"
end
o=(out..(o or "nil")):gsub("^[\r\n]+",""):gsub("[\r\n]+$",""):gsub("[\r\n]+"," | ")
:gsub("[%z\4\5\6\7\8\9\10\11\12\13\14\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]","")
print(o)
print("Program done.")