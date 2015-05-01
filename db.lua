--[[function tobits(c)
	local o={}
	for l1=1,7 do
		o[8-l1]=c%2
		c=math.floor(c/2)
	end
	return unpack(o)
end
function frombits(t)
	local o=0
	for l1=0,6 do
		o=o+(((assert(t[7-l1],7-l1)>0.3) and 1 or 0)*(2^l1))
	end
	return o
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function failtob64(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function failunb64(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

db={}]]

if bc then
	function bc.abs(a)
		return bc.isneg(a) and -a or a
	end
end

function timestamp()
	local date=os.date("!*t")
	return date.month.."/"..date.day.." "..date.hour..":"..("0"):rep(2-#tostring(date.min))..date.min
end

do
	local function ts(num,mn)
		return ("0"):rep(mn-#tostring(num))..num
	end
	function iso8601(t)
		local d=os.date("!*t",t)
		return ts(d.year,4).."-"..ts(d.month,2).."-"..ts(d.day,2).."T"..ts(d.hour,2)..":"..ts(d.min,2)..":"..ts(d.sec,2).."Z"
	end
	function uniso8601(txt)
		local year,month,day,hour,min,sec=txt:match("^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)Z$")
		return os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec)})
	end
end

--[[function gcd(a,b)
	if b==0 then
		return math.abs(a)
	else
		return gcd(b,a%b)
	end
end]]

function urlencode(txt)
	local o=txt:gsub("\r?\n","\r\n"):gsub("[^%w ]",function(t) return string.format("%%%02X",t:byte()) end):gsub(" ","+")
	return o
end

function urldecode(txt)
	local o=txt:gsub("+"," "):gsub("%%(%x%x)",function(t) return string.char(tonumber("0x"..t)) end)
	return o
end

function htmlencode(txt)
	local o=txt:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub("\"","&quot;"):gsub("'","&apos;"):gsub("\r?\n","<br>"):gsub("\t","&nbsp;&nbsp;&nbsp;&nbsp;"):gsub(" ","&nbsp;")
	return o
end

function parseurl(url)
	local out={}
	for var,dat in url:gmatch("([^&]+)=([^&]+)") do
		out[urldecode(var)]=urldecode(dat)
	end
	return out
end

function tpairs(tbl)
	local s={}
	local c=1
	for k,v in pairs(tbl) do
		s[c]=k
		c=c+1
	end
	c=0
	return function()
		c=c+1
		return s[c],tbl[s[c]]
	end
end

--[[local opairs=pairs
function pairs(t)
	if type(t)=="table" and (getmetatable(t) or {}).__pairs then
		return (getmetatable(t) or {}).__pairs(t)
	end
	return opairs(t)
end]]

function mean(...)
	local p={...}
	local n=0
	for l1=1,#p do
		n=n+p[l1]
	end
	return n/#p
end

function string.tmatch(str,p)
	local o={}
	str:gsub(p,function(r) table.insert(o,r) end)
	return o
end
getmetatable("").tmatch=string.tmatch

file=setmetatable({},{
	__index=function(s,n)
		local file=io.open(n,"r")
		return file and file:read("*a")
	end,
	__newindex=function(s,n,d)
		if not d then
			os.remove(n)
		else
			local file=io.open(n,"w")
			file:write(d)
			file:close()
		end
	end,
})

function math.dist(a,b)
	local s=0
	for i=1,#a do
		if not b then
			s=s+(math.abs(a[i])^2)
		else
			s=s+(math.abs(a[i]-b[i])^2)
		end
	end
	return math.sqrt(s)
end

function math.dist2(x1,y1,x2,y2)
	return math.dist({x1,y1},{x2,y2})
end

function math.dist3(x1,y1,z1,x2,y2,z2)
	return math.dist({x1,y1,z1},{x2,y2,z2})
end

function math.round(num,idp)
	local mult=10^(idp or 0)
	return math.floor(num*mult+0.5)/mult
end

function table.reverse(tbl)
    local size=#tbl
    local o={}
    for k,v in ipairs(tbl) do
		o[size-k]=v
    end
	for k,v in pairs(o) do
		tbl[k+1]=v
	end
	return tbl
end

function table.cat(...)
	local o={}
	for k,v in pairs({...}) do
		for l1=1,#v do
			table.insert(o,v[l1])
		end
	end
	return o
end

function table.copy(t)
	local ot={}
	for k,v in pairs(t) do
		if type(v)=="table" then
			ot[k]=table.copy(v)
		else
			ot[k]=v
		end
	end
	return ot
end

function table.sub(t,i,v)
	if i<0 then
		i=#t+i+1
	end
	v=v or #t
	if v<0 then
		v=#t+v+1
	end
	local o={}
	for l1=i,v do
		table.insert(o,t[l1])
	end
	return o
end

function string.min(...)
	local p={...}
	local n
	local o
	for k,v in pairs(p) do
		if not n or #v<n then
			n=#v
			o=v
		end
	end
	return o
end

function string.max(...)
	local p={...}
	local n
	local o
	for k,v in pairs(p) do
		if not n or #v>n then
			n=#v
			o=v
		end
	end
	return o
end

function pescape(txt)
	local o=txt:gsub("[%.%[%]%(%)%%%*%+%-%?%^%$]","%%%1"):gsub("%z","%%z")
	return o
end

local _tob64={
	[0]="A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"0","1","2","3","4","5","6","7","8","9","+","/"
}
local floor=math.floor
local byte=string.byte
local char=string.char
local sub=string.sub
function tob64(txt)
	local d,o,d1,d2,d3={byte(txt,1,#txt)},""
	for l1=1,#txt-2,3 do
		d1,d2,d3=d[l1],d[l1+1],d[l1+2]
		o=o.._tob64[floor(d1/4)].._tob64[((d1%4)*16)+floor(d2/16)].._tob64[((d2%16)*4)+floor(d3/64)].._tob64[d3%64]
	end
	local m=#txt%3
	if m==1 then
		o=o.._tob64[floor(d[#txt]/4)].._tob64[((d[#txt]%4)*16)].."=="
	elseif m==2 then
		o=o.._tob64[floor(d[#txt-1]/4)].._tob64[((d[#txt-1]%4)*16)+floor(d[#txt]/16)].._tob64[(d[#txt]%16)*4].."="
	end
	return o
end
local _unb64={
	["A"]=0,["B"]=1,["C"]=2,["D"]=3,["E"]=4,["F"]=5,["G"]=6,["H"]=7,["I"]=8,["J"]=9,["K"]=10,["L"]=11,["M"]=12,["N"]=13,
	["O"]=14,["P"]=15,["Q"]=16,["R"]=17,["S"]=18,["T"]=19,["U"]=20,["V"]=21,["W"]=22,["X"]=23,["Y"]=24,["Z"]=25,
	["a"]=26,["b"]=27,["c"]=28,["d"]=29,["e"]=30,["f"]=31,["g"]=32,["h"]=33,["i"]=34,["j"]=35,["k"]=36,["l"]=37,["m"]=38,
	["n"]=39,["o"]=40,["p"]=41,["q"]=42,["r"]=43,["s"]=44,["t"]=45,["u"]=46,["v"]=47,["w"]=48,["x"]=49,["y"]=50,["z"]=51,
	["0"]=52,["1"]=53,["2"]=54,["3"]=55,["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["+"]=62,["/"]=63,
}
function unb64(txt)
	txt=txt:gsub("=+$","")
	local o,d1,d2=""
	local ln=#txt
	local m=ln%4
	for l1=1,ln-3,4 do
		d1,d2=_unb64[sub(txt,l1+1,l1+1)],_unb64[sub(txt,l1+2,l1+2)]
		o=o..char((_unb64[sub(txt,l1,l1)]*4)+floor(d1/16),((d1%16)*16)+floor(d2/4),((d2%4)*64)+_unb64[sub(txt,l1+3,l1+3)])
	end
	if m==2 then
		o=o..char((_unb64[sub(txt,-2,-2)]*4)+floor(_unb64[sub(txt,-1,-1)]/16))
	elseif m==3 then
		d1=_unb64[sub(txt,-2,-2)]
		o=o..char((_unb64[sub(txt,-3,-3)]*4)+floor(d1/16),((d1%16)*16)+floor(_unb64[sub(txt,-1,-1)]/4))
	end
	return o
end
--[[function serialize(dat,options)
	options=options or {}
	local out=""
	local queue={{dat}}
	local cv=0
	local keydat
	local ptbl={}
	while queue[1] do
		local cu=queue[1]
		table.remove(queue,1)
		local typ=type(cu[1])
		local ot
		if typ=="string" then
			ot=string.gsub(string.format("%q",cu[1]),"\\\n","\\n")
		elseif typ=="number" or typ=="boolean" or typ=="nil" then
			ot=tostring(cu[1])
		elseif typ=="table" then
			local empty=true
			ot="{"
			local st=0
			ptbl[#ptbl+1]=cu[1]
			for k,v in pairs(cu[1]) do
				empty=false
				st=st+1
				table.insert(queue,st,{k,"key"})
				st=st+1
				local val=v
				if type(v)=="table" then
					for n,l in pairs(ptbl) do
						if l==v then
							if options.nofalse then
								val="recursive"
							elseif options.noerror then
								return false
							else
								error("Cannot handle recursive tables.",2)
							end
						end
					end
				end
				table.insert(queue,st,{val,"value",nil,st/2})
			end
			if empty then
				ot=ot.."}"
				ptbl[#ptbl]=nil
				typ="emptytable"
			else
				cv=cv+1
				if cu[3] then
					queue[st][3]=cu[3]
					cu[3]=nil
				end
				queue[st][3]=(queue[st][3] or 0)+1
			end
		elseif typ=="function" then
			if options.nofunc then
				ot="function"
			else
				local e,r,er=pcall(string.dump,cu[1])
				if e and r then
					ot="f(\""..tob64(r).."\")"
				else
					if options.nofalse then
						ot="invalid function"
					elseif options.noerror then
						return false
					else
						error(r or er,2)
					end
				end
			end
		else
			ot="userdata"
		end
		if cu[2]=="key" then
			if type(ot)=="string" then
				local nt=ot:sub(2,-2)
				local e,r=loadstring("return {"..nt.."=true}")
				if options.noshortkey or not e then
					ot="["..ot.."]="
				else
					ot=nt.."="
				end
			else
				ot=ot.."="
			end
			keydat={cu[1],ot}
			ot=""
		elseif cu[2]=="value" then
			if keydat[1]~=cu[4] then
				ot=keydat[2]..ot
			end
			if cu[3] then
				ot=ot..("}"):rep(cu[3])
				for l1=1,cu[3] do
					ptbl[#ptbl]=nil
				end	
				cv=cv-cu[3]
				if cv~=0 then
					ot=ot..","
				end
			elseif typ~="table" then
				ot=ot..","
			end
		end
		out=out..ot
	end
	return out
end]]

function serialize(value, pretty)
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
			local o=string.format("%q", v):gsub("\\\n","\\n"):gsub("%z","\\z")
			return o
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
		elseif t == "cdata" then
			return "cd("..serialize(tostring(ffi.typeof(v)):match("^ctype<(.-)>$"))..","..serialize(tob64(ffi.dump(v)))..")"
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

function _serializehtml(t,r)
	r=r or {}
	if r[t] then
		return "<div class=\"value unknown\">"..tostring(t).."</div>"
	end
	--print("serializing "..tostring(t):sub(1,100))
	local tpe=type(t)
	if tpe=="table" then
		local err,res=pcall(function()
			if not next(t) then
				return "<div class=\"value table\"></div>"
			end
			local o=""
			local u={}
			local n=1
			r[t]=true
			while t[n] do
				u[n]=true
				o=o.."<tr><td></td><td>".._serializehtml(t[n],r).."</tr>"
				n=n+1
			end
			local oi={}
			for k,v in pairs(t) do
				if not u[k] then
					table.insert(oi,{k,v})
				end
			end
			table.sort(oi,function(a,b)
				return tostring(a[1])<tostring(b[1])
			end)
			for k,v in ipairs(oi) do
				o=o.."<tr><td>".._serializehtml(v[1],r).."</td><td>=</td><td>".._serializehtml(v[2],r).."</td></tr>"
			end
			r[t]=nil
			return "<table class=\"value table\">"..o.."</table>"
		end)
		return err and res or "<div class=\"value unknown\">"..htmlencode(tostring(t)).."</div>"
	elseif tpe=="nil" then
		return "<div class=\"value nil\">nil</div>"
	elseif tpe=="boolean" then
		return "<div class=\"value bool\">"..htmlencode(tostring(t)).."</div>"
	elseif tpe=="number" then
		if t~=t then
			return "<div class=\"value number\">nan</div>"
		elseif t==math.huge then
			return "<div class=\"value number\">inf</div>"
		elseif t==-math.huge then
			return "<div class=\"value number\">-inf</div>"
		end
		return "<div class=\"value number\">"..htmlencode(tostring(t)).."</div>"
	elseif tpe=="string" then
		if t:match("\n") and '"'..(t:gsub("[\r\n\"'\\]",""))..'"'==string.format("%q",t:gsub("[\r\n\"'\\]","")) and not t:match("[[") and not t:match("]]") then
			return "<div class=\"value longstring\">[["..htmlencode(t:gsub("\r","")).."]]</div>"
		end
		return "<div class=\"value string\">"..htmlencode(serialize(t)).."</div>"
	else
		return "<div class=\"value unknown\">"..htmlencode(tostring(t)).."</div>"
	end
end

function serializehtml(t)
	return [[
		<html>
			<head>
				<style type="text/css">
					body {
						background-color: #191919;
						color: #e0e2e4;
						font-family: "Trebuchet MS", Helvetica, sans-serif;
					}
					.value {
						font-size: 20px;
					}
					.table {
						border-style: solid;
						border-width: 2px;
						border-color: #404040;
						padding: 8px;
						display: inline-block;
						background-color: #1f1f1f;
					}
					.string {
						color: #ec7600;
					}
					.longstring {
						color: #c29f56;
					}
					.number {
						color: #ffcd22;
					}
					.bool {
						color: #93c763;
					}
					.nil {
						color: #93c763;
					}
					.unknown {
						color: #678cb1;
					}
				</style>
			</head>
			<body>
	]].._serializehtml(t)..[[
			</body>
		</html>
	]]
end

function utf8len(s)
	local t=0
	for l1=1,#s do
		local c=s:byte(l1)
		if bit.band(c,0xC0)~=0x80 then
			t=t+1
		end
	end
	return t
end

local box={
	ud="│",
	lr="─",
	ur="└",
	rd="┌",
	ld="┐",
	lu="┘",
	lrd="┬",
	udr="├",
	x="┼",
	lud="┤",
	lur="┴",
	e="[]"
}

--[[local box={
	ud="|",
	lr="-",
	ur="\\",
	rd="/",
	ld="\\",
	lu="/",
	e="[]"
}]]

function txtbl(s,mx)
	mx=mx or 0
	if s=="" and mx>0 then
		s=" "
	end
	local o=s:tmatch("[^\r\n]+")
	for l1=1,#o do
		mx=math.max(mx,utf8len(o[l1]))
	end
	for l1=1,#o do
		o[l1]=o[l1]..(" "):rep(mx-utf8len(o[l1]))
	end
	return o,mx
end

function consoleBox(s)
	local t,l=txtbl(s)
	for l1=1,#t do
		t[l1]=box.ud..t[l1]..box.ud
	end
	table.insert(t,1,box.rd..(box.lr:rep(l))..box.ld)
	table.insert(t,box.ur..(box.lr:rep(l))..box.lu)
	return table.concat(t,"\n")
end

function consoleCat(a,b,al,bl)
	local at,al=txtbl(a,al)
	local bt,bl=txtbl(b,bl)
	if #at==#bt then
		for l1=1,#bt do
			bt[l1]=at[l1]..bt[l1]
		end
		return table.concat(bt,"\n")
	end
	if al==0 then
		return table.concat(bt,"\n")
	elseif bl==0 then
		return table.concat(at,"\n")
	end
	local ml=math.max(#at,#bt)
	for l1=1,math.floor((#bt-#at)/2) do
		table.insert(at,1,(" "):rep(al))
	end
	for l1=#at+1,ml do
		table.insert(at,(" "):rep(al))
	end
	for l1=1,math.floor((#at-#bt)/2) do
		table.insert(bt,1,(" "):rep(bl))
	end
	for l1=#bt+1,ml do
		table.insert(bt,(" "):rep(bl))
	end
	for l1=1,ml do
		at[l1]=at[l1]..bt[l1]
	end
	return table.concat(at,"\n")
end

function consoleTable(t)
	local ncols=0
	local nrows=0
	for k,v in pairs(t) do
		nrows=math.max(nrows,k)
		for n,l in pairs(v) do
			ncols=math.max(ncols,n)
		end
	end
	local wcols={}
	local hrows={}
	for l1=1,nrows do
		for l2=1,ncols do
			local d,mx=txtbl(t[l1][l2] or "")
			wcols[l2]=math.max(wcols[l2] or 0,mx)
			hrows[l1]=math.max(hrows[l1] or 0,#d)
		end
	end
	local sp={}
	for l1=1,ncols do
		table.insert(sp,(box.lr):rep(wcols[l1]))
	end
	local ocols={box.rd..table.concat(sp,box.lrd)..box.ld}
	for l1=1,nrows do
		local orow={}
		for l2=1,ncols do
			table.insert(orow,table.concat(txtbl(t[l1][l2] or "",wcols[l2]),"\n"))
			table.insert(orow,(box.ud.."\n"):rep(hrows[l1]))
		end
		local o=(box.ud.."\n"):rep(hrows[l1])
		for l2=1,#orow do
			o=consoleCat(o,orow[l2])
		end
		table.insert(ocols,o)
		table.insert(ocols,l1==nrows and (box.ur..table.concat(sp,box.lur)..box.lu) or (box.udr..table.concat(sp,box.x)..box.lud))
	end
	return table.concat(ocols,"\n")
end

function _cserialize(t,r)
	r=r or {}
	if r[t] then
		return tostring(t)
	end
	local tpe=type(t)
	if tpe=="table" then
		local err,res=pcall(function()
			local ok={}
			local ov={}
			local u={}
			local n=1
			r[t]=true
			while t[n]~=nil do
				u[n]=true
				table.insert(ok," ")
				table.insert(ov,consoleCat("   ",_cserialize(t[n],r)))
				n=n+1
			end
			local oi={}
			for k,v in pairs(t) do
				if not u[k] then
					table.insert(oi,{k,v})
				end
			end
			if #oi==0 then
				for l1=1,#ov do
					ov[l1]=ov[l1]:sub(4)
				end
			end
			table.sort(oi,function(a,b)
				return tostring(a[1])<tostring(b[1])
			end)
			for k,v in ipairs(oi) do
				table.insert(ok,_cserialize(v[1],r))
				table.insert(ov,consoleCat(" = ",_cserialize(v[2],r)))
			end
			if #ok==0 then
				return box.e
			end
			local _
			local kl=0
			for k,v in pairs(ok) do
				if v~=" " then
					_,kl=txtbl(v,kl)
				end
			end
			if kl==0 then
				return consoleBox(table.concat(ov,"\n"))
			end
			local vl=0
			for k,v in pairs(ov) do
				_,vl=txtbl(v,vl)
			end
			local o=""
			for l1=1,#ok do
				o=o..consoleCat(ok[l1],ov[l1],kl,vl).."\n"
			end
			r[t]=nil
			return consoleBox(o)
		end)
		return err and res or tostring(t)
	elseif tpe=="number" then
		if t~=t then
			return "nan"
		elseif t==math.huge then
			return "inf"
		elseif t==-math.huge then
			return "-inf"
		end
		return tostring(t)
	elseif tpe=="string" then
		local o=string.format("%q",t):gsub("\\\n","\\n"):gsub("%z","\\z")
		return o
	else
		return tostring(t)
	end
end

function cserialize(t)
	return _cserialize(t)
end

--[[function split(T,func) -- splits a table
	if func then
		T=func(T) -- advanced function
	end
	local Out={}
	if type(T)=="table" then
		for k,v in pairs(T) do
			Out[split(k)]=split(v) -- set the values for the new table
		end
	else
		Out=T
	end
	return Out
end]]
function unserialize(s,err) -- converts a string back into its original form
	if type(s)~="string" then
		if err then
			return false,"String exepcted. got "..type(s)
		end
		error("String exepcted. got "..type(s),2)
	end
	local func,e=loadstring("return "..s,"unserialize")
	if not func then
		if err then
			return "Invalid string."
		end
		error("Invalid string.",2)
	end
	return setfenv(func,{
		f=function(s)
			return loadstring(unb64(s))
		end,
		cd=function(tp,data)
			return ffi.udump(tp,unb64(data))
		end,
	})()
end
local function mindex(tbl,dat)
	local c=tbl
	for l1=1,#dat do
		c=c[dat[l1]]
	end
	return c
end
--[[function db.new(name,default)
	local file=io.open("db/"..name,"r")
	local db=default or {}
	if file then
		local err,res=pcall(unserialize,file:read("*a"))
		if type(res)=="table" then
			db=res
		end
		file:close()
	end
	local out={}
	local tmeta={[out]={out,db,{}}}
	setmetatable(tmeta,{__mode="k"})
	local rmeta={}
	setmetatable(rmeta,{__mode="kv"})
	local meta
	meta={
		__index=function(s,n)
			local i=tmeta[s]
			local o=mindex(db,i[3])[n]
			if type(o)=="table" then
				if rmeta[o] then
					return rmeta[o][1]
				end
				local t={}
				print("o "..serialize(i[3])..","..serialize(n))
				if i[3][1]==nil then
					tmeta[t]={o,t,{n}}
				else
					tmeta[t]={o,t,{unpack(i[3]),n}}
				end
				print("n "..serialize(tmeta[t][3]))
				rmeta[o]=tmeta[t]
				return setmetatable(t,meta)
			end
			return o
		end,
		__newindex=function(s,n,d)
			assert(mindex(db,assert(tmeta[s])[3]))[n]=d
			local file=io.open("db/"..name,"w")
			file:write(serialize(db))
			file:close()
		end,
		__pairs=function(s)
			if s==db then
				error("wtf")
			end
			return pairs(mindex(db,tmeta[s][3])),nil
		end,
		__ipairs=function(s)
			return ipairs(mindex(db,tmeta[s][3])),nil
		end,
		__tostring=function(s)
			return tostring(mindex(db,tmeta[s][3]))
		end,
		__len=function(s)
			return #mindex(db,tmeta[s][3])
		end
	}
	setmetatable(out,meta)
	return out,db
end]]

null=setmetatable({},{
	__index=function(s)
		return s
	end,
	__newindex=null,
	__call=function() end,
})
