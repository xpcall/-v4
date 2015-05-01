-- binary table serialization
-- 
-- byte type:
--   0x00: false
--   0x01: true
--   0x02: nil
--   0x03: nan
--   0x04: inf
--   0x05: -inf
--   0x06: {}
--   0x07: end
--   0x10:
--     double value
--   0x1n:
--     int(n byte) value
--   0x2n:
--     4bit n value
--   0x30: null-terminated string
--   0x3n:
--     byte[n] string
--   0x4n: binary string
--     int(n byte) length
--     byte[length] string
--   0x50:
--     ... value data
--     end data
--   0x5n:
--     n values data
--   0x60:
--     ... values:
--       key data
--       value data
--     end data
--   0x6n:
--     n values:
--       key data
--       value data
--     end data
--   0x7n: reference
--     int(n byte) index

local _bserialize
local function minBytes(i)
	return math.ceil(math.floor(math.log(i,2)+1)/8)
end
local function checkLen(o,t,r,idx)
	if minBytes(idx)+1<#o then
		r[t]=idx
	end
	return o
end
function _bserialize(t,r,idx)
	if r[t] then
		local n=minBytes(r[t])
		return string.char(0x70+n)..string.pack(">I"..n,r[t])
	end
	local tpe=type(t)
	local idxlen=1+minBytes(idx)
	if tpe=="boolean" then
		return t and "\x01" or "\x00"
	elseif tpe=="nil" then
		return "\x02"
	elseif tpe=="number" then
		if t~=t then
			return "\x04"
		elseif t==math.huge then
			return "\x05"
		elseif t==-math.huge then
			return "\x06"
		elseif t>=0 and math.floor(t)==t then
			if t<16 then
				return string.char(0x20+t)
			end
			local n=minBytes(t)
			return string.char(0x10+n)..string.pack(">I"..n,t)
		end
		return "\x10"..encodeDouble(t)
	elseif tpe=="string" then
		if t=="" then
			return "\x40"
		end
		if #t<16 then
			return checkLen(string.char(0x30+#t)..t,t,r,idx)
		end
		if t:match("%z") then
			local n=minBytes(#t)
			return checkLen(string.char(0x40+n)..string.pack(">I"..n,#t)..t,t,r,idx)
		else
			return checkLen("\x30"..t.."\0",t,r,idx)
		end
	elseif tpe=="table" then
		if not next(t) then
			return "\x07"
		end
		local iarr=true
		local inum=true
		local cnum=0
		local tnum=0
		local tcost=0
		local ck=0
		for k,v in pairs(t) do
			tnum=tnum+1
			if type(k)=="number" and k>0 and math.floor(k)==k and k==k and k~=math.huge then
				ck=ck+1
				if k~=ck then
					iarr=false
				end
				cnum=math.max(cnum,k)
				tcost=tcost+(k<16 and 1 or (1+minBytes(k)))
			else
				inum=false
			end
		end
		local ot,en
		if inum and tcost>=cnum-ck then
			local o=string.char(0x50+(cnum<16 and cnum or 0))
			for l1=1,cnum do
				ot,en=_bserialize(t[l1],r,idx+#o,r,idx+#o)
				o=o..ot
			end
			if cnum>15 then
				en=(en or 0)+1
				o=o.."\x08"
			end
			return o,en
		end
		local o=string.char(0x60+(tnum<16 and tnum or 0))
		for k,v in pairs(t) do
			o=o.._bserialize(k,r,idx+#o)
			ot,en=_bserialize(v,r,idx+#o)
			o=o..ot
		end
		if tnum>15 then
			en=(en or 0)+1
			o=o.."\x08"
		end
		return o,en
	else
		error("unsupported type: "..tpe)
	end
end

function bserialize(t)
	local o,en=_bserialize(t,{},1)
	return o:sub(1,-(en or 0)-1)
end

local _unbserialize
local _end={}
function _unbserialize(t,r,og)
	local function rd(n)
		assert(#t>=n,"unexpected end of string")
		local o=t:sub(1,n)
		t=t:sub(n+1)
		return o
	end
	local idx=(#og-#t)+1
	local bt=rd(1):byte()
	local tpe=math.floor(bt/0x10)
	local n=bt%0x10
	if tpe==0 then
		if n==0 then
			return t,false
		elseif n==1 then
			return t,true
		elseif n==2 then
			return t,nil
		elseif n==3 then
			return t,0/0
		elseif n==4 then
			return t,math.huge
		elseif n==5 then
			return t,-math.huge
		elseif n==6 then
			local o={}
			r[idx]=o
			return t,o
		elseif n==7 then
			return t,_end
		end
	elseif tpe==1 then
		if n==0 then
			local o=decodeDouble(rd(8))
			return t,o
		else
			local o=string.unpack(">I"..n,rd(n))
			return t,o
		end
	elseif tpe==2 then
		return t,n
	elseif tpe==3 then
		if n==0 then
			local o=""
			local c=rd(1)
			while c~="\0" do
				o=o..c
				c=rd(1)
			end
			return t,o
		else
			local o=rd(n)
			return t,o
		end
	elseif tpe==4 then
		if n==0 then
			return t,""
		else
			local o=rd(string.unpack(">I"..n,rd(n)))
			return o
		end
	elseif tpe==5 then
		local o={}
		r[idx]=o
		local v
		if n==0 then
			t,v=_unbserialize(t,r,og)
			while v~=_end and #t>0 do
				table.insert(o,v)
				t,v=_unbserialize(t,r,og)
			end
		else
			for l1=1,n do
				t,v=_unbserialize(t,r,og)
				table.insert(o,v)
			end
		end
		return t,o
	elseif tpe==6 then
		local o={}
		r[idx]=o
		local k,v
		if n==0 then
			t,k=_unbserialize(t,r,og)
			while k~=_end and #t>0 do
				t,v=_unbserialize(t,r,og)
				o[k]=v
				t,k=_unbserialize(t,r,og)
			end
		else
			for l1=1,n do
				t,k=_unbserialize(t,r,og)
				t,v=_unbserialize(t,r,og)
				o[k]=v
			end
		end
		return t,o
	elseif tpe==7 then
		local ref=string.unpack(">I"..n,n)
		if r[ref] then
			return t,r[ref]
		else
			local s,o=_unbserialize(og:sub(ref),r,og)
			return t,o
		end
	else
		error("corrupt id: "..tpe)
	end
end

function unbserialize(t)
	local s,o=_unbserialize(t,{},t)
	return o
end
