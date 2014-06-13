bit64={}

local tobit=bit.tobit
local tohex=bit.tohex

local band=bit.band
local bor=bit.bor
local bnot=bit.bnot
local bxor=bit.bxor
local lshift=bit.lshift
local rshift=bit.rshift
local ror=bit.bor
local rol=bit.rol

local function to64(...)
	local o={}
	for k,v in pairs({...}) do
		if type(v)=="number" then
			table.insert(o,{0,tonumber(tohex(v),16)})
		elseif type(v)=="string" then
			local hex=v:match("^0x(%x+)$")
			if hex then
				hex=(("0"):rep(math.max(0,16-#hex))..hex):sub(1,16)
				table.insert(o,{tonumber("0x"..hex:sub(1,8)),tonumber("0x"..hex:sub(9))})
			else
				error("invalid number")
			end
		elseif type(v)=="table" then
			table.insert(o,{tonumber(tohex(v[1]),16),tonumber(tohex(v[2]),16)})
		end
	end
	return unpack(o)
end

local function unpackn(t,i)
	local o={}
	for k,v in pairs(t) do
		table.insert(o,v[i])
	end
	return unpack(o)
end

function bit64.band(...)
	local p={to64(...)}
	return to64({band(unpackn(p,1)),band(unpackn(p,2))})
end

function bit64.bor(...)
	local p={to64(...)}
	return to64({bor(unpackn(p,1)),bor(unpackn(p,2))})
end

function bit64.bnot(a)
	a=to64(a)
	return to64({bnot(a[1]),bnot(a[2])})
end

function bit64.bxor(...)
	local p={to64(...)}
	return to64({bxor(unpackn(p,1)),bxor(unpackn(p,2))})
end

function bit64.lshift(a,b)
	a,b=to64(a),to64(b)
	local sh=b[2]%64
	if sh>=32 then
		return to64({lshift(a[2],sh%32),0})
	else
		return to64({bor(lshift(a[1],sh),rshift(a[2],32-sh)),lshift(a[2],sh)})
	end
end

function bit64.rshift(a,b)
	a,b=to64(a),to64(b)
	local sh=b[2]%64
	if sh>=32 then
		return to64({0,rshift(a[1],sh%32)})
	else
		return to64({rshift(a[1],sh),bor(rshift(a[2],sh),lshift(a[1],32-sh))})
	end
end

function bit64.rol(a,b)
	a,b=to64(a),to64(b)
	return bit64.bor(bit64.rshift(a,64-b[2]),bit64.lshift(a,b))
end

function bit64.ror(a,b)
	a,b=to64(a),to64(b)
	return bit64.bor(bit64.lshift(a,64-b[2]),bit64.rshift(a,b))
end

function bit64.add(...)
	local p={to64(...)}
	local c={0,0}
	for k,v in pairs(p) do
		c[2]=c[2]+v[2]
		c=to64({v[1]+c[1]+math.floor(c[2]/0x100000000),c[2]})
	end
	return c
end