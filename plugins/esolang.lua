function brainfuck(txt)
	return loadstring(
		"local s,p,o={},0,\"\""..txt
		:gsub("[^%[%]%+%-+.%,<>]","")
		:gsub("%]"," end")
		:gsub("%["," while (s[p] or 0)~=0 do")
		:gsub("[%+%-]+",function(txt)
			return " s[p]=((s[p] or 0)"..txt:sub(1,1)..#txt..")%256"
		end)
		:gsub("[<>]+",function(txt)
			return " p=p"..(txt:sub(1,1)==">" and "+" or "-")..#txt
		end)
		:gsub("%."," o=o..string.char(s[p] or 0)")
		:gsub(","," error(\"Input not supported.\")")
	.." return o","=brainfuck")
end

hook.new({"command_bf","command_brainfuck"},function(user,chan,txt)
	local func,err=brainfuck(txt)
	if not func then
		return err
	end
	local func=coroutine.create(setfenv(func,_G))
	debug.sethook(func,function() error("Time limit exeeded.",0) end,"",100000)
	local err,res=coroutine.resume(func)
	return res or "nil"
end)

hook.new({"command_cf","command_clusterfuck"},function(user,chan,txt)
	local source="local s,px,py,o=setmetatable({},{__index=function(s,n) local a=setmetatable({},{__index=function() return 0 end}) s[n]=a return a end}),0,0,\"\"\n"..txt
		:gsub("[^%[%]%+%-+.%,<>v%^{}]","")
		:gsub("[%]}]","\nend")
		:gsub("%[","\nwhile s[px][py]~=0 do")
		:gsub("%{","\nwhile s[px][py]==0 do")
		:gsub("[%+%-]+",function(txt)
			return "\ns[px][py]=(s[px][py]"..txt:sub(1,1)..#txt..")%256"
		end)
		:gsub("[<>]+",function(txt)
			return "\npx=px"..(txt:sub(1,1)==">" and "+" or "-")..#txt
		end)
		:gsub("[%^v]+",function(txt)
			return "\npy=py"..(txt:sub(1,1)=="v" and "+" or "-")..#txt
		end)
		:gsub("%.","\no=o..string.char(s[px][py])")
		:gsub(",","\nerror(\"Input not supported.\")")
	.." return o"
	print(source)
	local func,err=loadstring(source,"=clusterfuck")
	if not func then
		return err
	end
	local func=coroutine.create(setfenv(func,_G))
	debug.sethook(func,function() error("Time limit exeeded.",0) end,"",100000)
	local err,res=coroutine.resume(func)
	return res or "nil"
end)

hook.new({"command_binfuck","command_binaryfuck"},function(user,chan,txt)
	--[[if #txt%4~=1 
		txt=unb
	end
	local func,err=brainfuck(txt)
	if not func then
		return err
	end
	local func=coroutine.create(setfenv(func,_G))
	debug.sethook(func,function() error("Time limit exeeded.",0) end,"",100000)
	local err,res=coroutine.resume(func)
	return res or "nil"]]
end)

function base(n,c,tf)
	if not c then
		return string.format("%X",n)
	end
	local str=""
	local tbl={}
    repeat
        local d=(n%(#c))+1
        n=math.floor(n/(#c))
		str=string.sub(c,d,d)..str
		table.insert(tbl,1,d)
    until n==0
	if tf then
		return tbl
	end
	return str
end
function unbase(str,nc)
	local c={}
	for l1=1,#nc do
		c[nc:sub(l1,l1)]=l1-1
	end
	local n=0
	str=tostring(str):reverse()
	for strnum=1,#str do
		n=n+(c[str:sub(strnum,strnum)]*((#nc)^(strnum-1)))
	end
	return n
end
function rgsub(str,from,to)
	for k=1,#from do
		str=str:gsub(pescape(from:sub(k,k)),pescape(to:sub(k,k)))
	end
	return str
end
function tobase(str,nc,toc,flen)
	flen=flen or 0
	if not nc then
		nc=""
		for l1=0,255 do
			nc=nc..string.char(l1)
		end
	end
	if not toc then
		toc=""
		for l1=0,255 do
			toc=toc..string.char(l1)
		end
	end
	str=str:gsub("[^"..pescape(nc).."]","")
	local c={}
	for l1=1,#nc do
		c[nc:sub(l1,l1)]=l1-1
	end
	local n={0}
	str=tostring(str):reverse()
	for strnum=1,#str do
		n[1]=n[1]+(c[str:sub(strnum,strnum)]*((#nc)^(strnum-1)))
		local sn=1
		while (n[sn] or 0)>=#toc do
			n[sn+1]=(n[sn+1] or 0)+math.floor(n[sn]/#toc)
			n[sn]=n[sn]%#toc
			sn=sn+1
		end
	end
	local o=""
	for l1=1,#n do
		o=toc:sub(n[l1]+1,n[l1]+1)..o
	end
	return toc:sub(1,1):rep(math.max(0,flen-#o))..o
end

hook.new({"command_encodeag","command_encagony"},function(user,chan,txt)
	return "<[.<]"..(txt.."\r\n\0"):reverse():gsub(".",function(t) return tobase(t,nil,"$}{><@~+-.,()[]*",2) end)
end)

hook.new({"command_ag","command_agony"},function(user,chan,txt)
	txt=txt:gsub("[^%$}{><@~%+%-%.,%(%)%[%]%*]","")
	local bt={
		["$"]=0x0,["}"]=0x1,["{"]=0x2,[">"]=0x3,
		["<"]=0x4,["@"]=0x5,["~"]=0x6,["+"]=0x7,
		["-"]=0x8,["."]=0x9,[","]=0xA,["("]=0xB,
		[")"]=0xC,["["]=0xD,["]"]=0xE,["*"]=0xF,
	}
	local mxval=0
	local mnval=0
	local mem=setmetatable({},{
		__newindex=function(s,n,d)
			mxval=math.max(mxval,n)
			mnval=math.min(mnval,n)
			rawset(s,n,d)
		end,
		__index=function()
			return 0 
		end
	})
	for l1=1,#txt do
		mem[l1-1]=bt[txt:sub(l1,l1)]
	end
	local o=""
	local eip=0
	local ptr=#txt+1
	local function lc(dt,a,b,cmp,tf)
		local mrm=(mem[ptr-1]*16)+mem[ptr]
		if tf then
			mrm=mem[ptr]
		end
		if (mrm==0 and cmp==1) or (mrm~=0 and cmp==0) then
			local cn=0
			local cnt=0
			local ins
			repeat
				cnt=cnt+dt
				ins=mem[eip+cnt]
				if ins==a then
					cn=cn+1
				elseif ins==b then
					cn=cn-1
				end
			until eip==mnval or eip==mxval or cn==-1
			if eip==mnval or eip==mxval then
				return false
			end
			eip=eip+cnt
		end
		return true
	end
	local insnum=0
	while true do
		local ins=mem[eip]
		if ins==0 then
			return o
		elseif ins==1 then
			ptr=ptr+1
		elseif ins==2 then
			ptr=ptr-1
		elseif ins==3 then
			ptr=ptr+2
		elseif ins==4 then
			ptr=ptr-2
		elseif ins==5 then
			mem[ptr]=(mem[ptr]+1)%16
		elseif ins==6 then
			mem[ptr]=(mem[ptr]-1)%16
		elseif ins==7 then
			mem[ptr]=mem[ptr]+1
			mem[ptr-1]=(mem[ptr-1]+math.floor(mem[ptr]/16))%16
			mem[ptr]=mem[ptr]%16
		elseif ins==8 then
			mem[ptr]=mem[ptr]-1
			mem[ptr-1]=(mem[ptr-1]+math.floor(mem[ptr]/16))%16
			mem[ptr]=mem[ptr]%16
		elseif ins==9 then
			o=o..string.char((mem[ptr-1]*16)+mem[ptr])
		elseif ins==10 then
			return "Input not supported."
		elseif ins==11 then
			if not lc(1,0xB,0xC,1,true) then
				return "err\n"..o
			end
		elseif ins==12 then
			if not lc(-1,0xC,0xB,0,true) then
				return "err\n"..o
			end
		elseif ins==13 then
			if not lc(1,0xD,0xE,1) then
				return "err\n"..o
			end
		elseif ins==14 then
			if not lc(-1,0xE,0xD,0) then
				return "err\n"..o
			end
		elseif ins==15 then
			mem[ptr-1],mem[ptr],buff[1],buff[2]=buff[1],buff[2],mem[ptr-1],mem[ptr]
		end
		eip=eip+1
		insnum=insnum+1
		if insnum>9000 then
			return "Time limit exeeded."
		end
	end
end)

local enc={
	[0]=57 ,109,60 ,46 ,84 ,86 ,97 ,99 ,96 ,117,89 ,42 ,77 ,75 ,39 ,88 ,126,120,68 ,
	108,125,82 ,69 ,111,107,78 ,58 ,35 ,63 ,71 ,34 ,105,64 ,53 ,122,93 ,38 ,103,
	113,116,121,102,114,36 ,40 ,119,101,52 ,123,87 ,80 ,41 ,72 ,45 ,90 ,110,44 ,
	91 ,37 ,92 ,51 ,100,76 ,43 ,81 ,59 ,62 ,85 ,33 ,112,74 ,83 ,55 ,50 ,70 ,104,
	79 ,65 ,49 ,67 ,66 ,54 ,118,94 ,61 ,73 ,95 ,48 ,47 ,56 ,124,106,115,98 ,
}
local out={} -- remember output so initializing ram doesnt take years
local function crz(a,b)
	local ot=out[a..","..b]
	if ot then
		return ot
	end
	local cr={[0]={[0]=1,0,0},{[0]=1,0,2},{[0]=2,2,1}}
	local o,bs=0
	for l1=0,9 do
		bs=3^l1
		local sa=math.floor(a/bs)%3
		local sb=math.floor(b/bs)%3
		o=o+(3^l1)*cr[sa][sb]
	end
	out[a..","..b]=o
	return o
end
hook.new({"command_mb","command_malbolge"},function(user,chan,txt)
	local a,c,d,bse,o,ins,mem=0,0,0,3^10,"",0,{}
	for l1=1,#txt do
		mem[l1-1]=string.byte(txt,l1,l1)
	end
	for l1=#mem+1,bse do
		mem[l1]=crz(mem[l1-1],mem[l1-2])
	end
	while true do
		local leip=c
		local op=(mem[c]+c)%94
		if op==4 then
			c=mem[d]
		elseif op==5 then
			o=o..string.char(a%256)
		elseif op==23 then
			return "Input not supported."
		elseif op==39 then
			a=((mem[d]%3)*3^9)+math.floor(mem[d]/3)
			mem[d]=a
		elseif op==40 then
			d=mem[d]
		elseif op==62 then
			a=crz(mem[d],a)
			mem[d]=a
		elseif op==81 then
			return o
		end
		mem[c]=enc[mem[c]%94] or mem[c]
		c=(c+1)%bse
		d=(d+1)%bse
		ins=ins+1
		if ins>9000 then
			return "Time limit exeeded."
		end
	end
end)
hook.new({"command_["},function(user,chan,txt)
	txt=txt:gsub("[^%(%)<>{}%[%]]","")
	local ptr=1
	local stk={}
	local mstk={}
	local ins=0
	while ptr<=#txt do
		local cmd=txt:sub(ptr,ptr)
		if cmd=="(" then
			table.insert(stk,true)
		elseif cmd==")" then
			table.insert(stk,false)
		elseif cmd=="<" then
			table.remove(stk)
		elseif cmd==">" then
			local s1,s2=table.remove(stk),table.remove(stk)
			table.insert(stk,s1)
			table.insert(stk,s2)
		elseif cmd=="{" then
			if stk[#stk] then
				local level=0
				while true do
					ptr=ptr+1
					if txt:sub(ptr,ptr)=="{" then
						level=level+1
					elseif txt:sub(ptr,ptr)=="}" then
						level=level-1
						if level~=-1 then
							break
						end
					end
					if ptr>=#txt or ptr==0 then
						return "Syntax error."
					end
				end
			end
		elseif cmd=="}" then
			if stk[#stk] then
				local level=0
				while true do
					ptr=ptr-1
					if txt:sub(ptr,ptr)=="{" then
						level=level+1
						if level~=-1 then
							break
						end
					elseif txt:sub(ptr,ptr)=="}" then
						level=level-1
					end
					if ptr>=#txt or ptr==0 then
						return "Syntax error."
					end
				end
			end
		elseif cmd=="[" then
			table.insert(mstk,stk)
			stk={}
		elseif cmd=="]" then
			stk={unpack(stk),unpack(table.remove(mstk))}
		end
		ptr=ptr+1
		ins=ins+1
		if ins>9000 then
			return "Time limit exeeded."
		end
	end
	local o=""
	for l1=1,#stk do
		o=o..(stk[l1] and '"' or "'")
	end
	return o
end)

hook.new({"command_ssbpl"},function(user,chan,txt)
	local stack=setmetatable({},{__index=function() return 0 end})
	local function push(num)
		stack[#stack+1]=math.floor(num%65536)
	end
	local function st(num)
		return stack[num+#stack-1]
	end
	local function pop()
		local a=st(1)
		stack[#stack]=nil
		return a
	end
	local sb
	local o=""
	local ip=1
	local op={
		["%*"]=function()
			push(pop()*pop())
		end,
		["/"]=function()
			push(pop()/pop())
		end,
		["%%"]=function()
			push(pop()%pop())
		end,
		["&"]=function()
			push(bit.band(pop(),pop()))
		end,
		["|"]=function()
			push(bit.bor(pop(),pop()))
		end,
		["%^"]=function()
			push(bit.bxor(pop(),pop()))
		end,
		["_"]=function()
			push(bit.bnot(pop(),pop()))
		end,
		["%d+"]=function(num)
			push(tonumber(num))
			sb=#num
		end,
		["'(.)"]=function(c)
			push(string.byte(c))
			sb=2
		end,
		["%."]=function()
			o=o..string.char(pop()%256)
		end,
		[":"]=function()
			pop()
		end,
		["%$"]=function()
			push(st(1))
		end,
	}
	local ins=0
	while #txt>0 do
		sb=1
		for k,v in pairs(op) do
			txt:gsub("^"..k,v)
		end
		txt=txt:sub(sb+1)
		ins=ins+1
		if ins>9000 then
			return "Time limit exeeded."
		end
	end
	return o
end)