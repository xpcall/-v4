function tobits(c)
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

db={}
local _tob64={
	[0]="A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"0","1","2","3","4","5","6","7","8","9","+","/"
}
function tob64(stxt)
	local txt=tostring(stxt)
	if not txt then
		error("string expected, got "..type(stxt),2)
	end
	local d,o,d1,d2,d3={string.byte(txt,1,#txt)},""
	for l1=1,#txt-2,3 do
		d1,d2,d3=d[l1],d[l1+1],d[l1+2]
		o=o.._tob64[math.floor(d1/4)].._tob64[((d1%4)*16)+math.floor(d2/16)].._tob64[((d2%16)*4)+math.floor(d3/64)].._tob64[d3%64]
	end
	local m=#txt%3
	if m==1 then
		o=o.._tob64[math.floor(d[#txt]/4)].._tob64[((d[#txt]%4)*16)].."=="
	elseif m==2 then
		o=o.._tob64[math.floor(d[#txt-1]/4)].._tob64[((d[#txt-1]%4)*16)+math.floor(d[#txt]/16)].._tob64[(d[#txt]%16)*4].."="
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
function unb64(stxt)
	local txt=tostring(stxt)
	if not txt then
		error("string expected, got "..type(stxt),2)
	end
	txt=txt:gsub("[^%a%d/%+]","")
	local m=#txt%4
	if m==1 then
		error("invalid b64",2)
	end
	local o,d1,d2=""
	for l1=1,#txt-3,4 do
		d1,d2=_unb64[txt:sub(l1+1,l1+1)],_unb64[txt:sub(l1+2,l1+2)]
		o=o..string.char((_unb64[txt:sub(l1,l1)]*4)+math.floor(d1/16),((d1%16)*16)+math.floor(d2/4),((d2%4)*64)+_unb64[txt:sub(l1+3,l1+3)])
	end
	if m==2 then
		o=o..string.char((_unb64[txt:sub(-2,-2)]*4)+math.floor(_unb64[txt:sub(-1,-1)]/16))
	elseif m==3 then
		d1=_unb64[txt:sub(-2,-2)]
		o=o..string.char((_unb64[txt:sub(-3,-3)]*4)+math.floor(d1/16),((d1%16)*16)+math.floor(_unb64[txt:sub(-1,-1)]/4))
	end
	return o
end
function serialize(dat,options)
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
end
function split(T,func) -- splits a table
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
end
function unserialize(s) -- converts a string back into its original form
	if type(s)~="string" then
		error("String exepcted. got "..type(s),2)
	end
	local func,e=loadstring("return "..s,"unserialize")
	if not func then
		error("Invalid string.",2)
	end
	return setfenv(func,{f=function(s) return loadstring(unb64(s)) end})()
end
local function mindex(tbl,dat)
	local c=tbl
	for l1=1,#dat do
		c=c[dat[l1]]
	end
	return c
end
function db.new(name,default)
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
end
local opairs=pairs
local iserial=false
function pairs(tbl)
	local m=getmetatable(tbl)
	if m and m.__pairs then
		return m.__pairs(tbl)
	end
	return opairs(tbl)
end
local oipairs=ipairs
function ipairs(tbl)
	local m=getmetatable(tbl)
	if m and m.__ipairs then
		return m.__ipairs(tbl)
	end
	return oipairs(tbl)
end
