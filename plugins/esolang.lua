hook.new({"command_geneso","command_genesolang"},function(user,chan,txt)
	local bits=2^math.random(1,6)
	local o=bits.." bit "
	local mem={"tape","cell","stack","register","variable"}
	local cmem=mem[math.random(1,#mem)]
	o=o..cmem.." "
	if math.random(1,5)==1 then
		local c
		repeat
			c=mem[math.random(1,#mem)]
		until c~=cmem
		o=o.."and "..c.." "
	end
	o=o.."based "
	if math.random(1,10)==1 then
		o=o.."verbose "
	elseif math.random(1,10)==1 then
		o=o.."2D "
	end
	if math.random(1,10)==1 then
		o=o.."self modifying "
	end
	if math.random(1,5)==1 then
		o=o.."brainfuck derivitive "
	end
	return o:sub(1,-2)
end)

function brainfuck(txt)
	return loadstring(
		"local s,p,o={},0,\"\""..txt
		:gsub("(.)(%d+)",function(d,num)
			return d:rep(tonumber(num))
		end)
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

hook.new({"command_ff","command_failfuck"},function(user,chan,txt)
	local func,err=loadstring(
		"local s,p,o={},0,\"\""..txt
		:gsub("[^%[%]%+%-+.%,<>]","")
		:gsub("%]","\nend")
		:gsub(",","\nerror(\"Input not supported.\")")
		:gsub("%[","\nfor l1=1,1000 do if s[p]==0 then break end")
		:gsub("[%+%-]+",function(txt)
			return "\ns[p]=((s[p] or 0)"..txt:sub(1,1)..#txt..")%256"
		end)
		:gsub("[<>]+",function(txt)
			return "\np=p"..(txt:sub(1,1)==">" and "+" or "-")..#txt
		end)
		:gsub("%.","\no=o..string.char(s[p] or 0)")
	.." return o","=brainfuck")
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
do
	local agony={
		[0]="$","}","{",">","<","@","~","+","-",".",",","(",")","[","]","*"
	}
	hook.new({"command_encodeag","command_encagony"},function(user,chan,txt)
		return "<[.<]"..(txt.."\r\n\0"):reverse():gsub(".",function(t)
			t=t:byte() 
			return agony[math.floor(t/16)]..agony[t%16]
		end)
	end)
end

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
	57 ,109,60 ,46 ,84 ,86 ,97 ,99 ,96 ,117,89 ,42 ,77 ,75 ,39 ,88 ,126,120,68 ,
	108,125,82 ,69 ,111,107,78 ,58 ,35 ,63 ,71 ,34 ,105,64 ,53 ,122,93 ,38 ,103,
	113,116,121,102,114,36 ,40 ,119,101,52 ,123,87 ,80 ,41 ,72 ,45 ,90 ,110,44 ,
	91 ,37 ,92 ,51 ,100,76 ,43 ,81 ,59 ,62 ,85 ,33 ,112,74 ,83 ,55 ,50 ,70 ,104,
	79 ,65 ,49 ,67 ,66 ,54 ,118,94 ,61 ,73 ,95 ,48 ,47 ,56 ,124,106,115,98 ,
}
local out={} -- remember output so initializing ram doesnt take years
function crz(a,b)
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
local function unmb(txt)
	local out=""
	local conv={
		["i"]=4,
		["<"]=5,
		["/"]=23,
		["*"]=39,
		["j"]=40,
		["p"]=62,
		["o"]=68,
		["v"]=81,
	}
	for a=0,#txt-1 do
		local i=conv[txt:sub(a+1,a+1)]
		local n=false
		for l1=33,126 do
			if (l1+a)%94==i then
				out=out..string.char(l1)
				n=true
				break
			end
		end
		if not n then
			return "unencodable character: "..txt:sub(a+1,a+1)
		end
	end
	return out
end
hook.new({"command_unmb"},function(user,chan,txt)
	return unmb(txt)
end)
hook.new({"command_rnmb"},function(user,chan,txt)
	local conv={
		[4]="i",
		[5]="<",
		[23]="/",
		[39]="*",
		[40]="j",
		[62]="p",
		[68]="o",
		[81]="v",
	}
	local out=""
	for l1=1,#txt do
		out=out..(conv[(string.byte(txt,l1,l1)+(l1-1))%94] or "0")
	end
	return out
end)
hook.new({"command_genmb"},function(user,chan,txt)
	local c=""
	for char in txt:match(".") do
		local t={1}
		while true do
			if hook.queue("command_mb",user,chan,unmb(c)) then
				
			end
		end
	end
end)
do
	hook.new({"command_genmb"},function(user,chan,txt)
		local a=0
		local c=0
		for char in txt:gmatch(".") do
			local t={1}
			while true do
				local sa=a
				local sc=c
				for l1=1,#t do
					local d=sc
					if t[l1]==1 then
						sa=(((d+39)%3)*3^9)+math.floor((d+39)/3)
					elseif t[l1]==2 then
						sa=crz(d+62,sa)
					end
					sc=sc+1
				end
				local o=""
				for k,v in pairs(t) do
					o=o..(v==1 and "*" or (v==2 and "p" or "o"))
				end
				print(o,sa%256)
				if sa%256==char:byte() then
					c=sc
					a=sa
					return o
				end
				t[1]=t[1]+1
				local n=1
				while t[n]>3 do
					t[n]=1
					t[n+1]=(t[n+1] or 0)+1
					n=n+1
				end
			end
		end
	end)
end
hook.new({"command_mb","command_malbolge"},function(user,chan,txt,dbg)
	if #txt<2 then
		return "Minimum program is 2 chars."
	end
	local a,c,d,bse,o,ins,mem=0,0,0,3^10,"",0,{}
	for l1=1,#txt do
		mem[l1-1]=string.byte(txt,l1,l1)
	end
	for l1=#mem+1,bse do
		mem[l1]=crz(mem[l1-1],mem[l1-2])
	end
	local dbo=""
	local inst=""
	while true do
		local leip=c
		local op=(mem[c]+c)%94
		if dbg then
			dbo=" | a="..a..",c="..c..",d="..d
		end
		if op==4 then
			c=mem[d]
			inst=inst.."i"
		elseif op==5 then
			if dbg then
				o=o..a.." "
			else
				o=o..string.char(a%256)
			end
			inst=inst.."<"
		elseif op==23 then
			a=math.random(0,255)
			--return "Input not supported."..dbo
			inst=inst.."/"
		elseif op==39 then
			a=((mem[d]%3)*3^9)+math.floor(mem[d]/3)
			mem[d]=a
			inst=inst.."*"
		elseif op==40 then
			d=mem[d]
			inst=inst.."j"
		elseif op==62 then
			a=crz(mem[d],a)
			mem[d]=a
			inst=inst.."p"
		elseif op==81 then
			inst=inst.."v"
			return o..dbo
		else
			inst=inst.."o"
		end
		if enc[mem[c]-33] then
			mem[c]=enc[mem[c]-33]
		end
		mem[c]=enc[mem[c]] or mem[c]
		c=(c+1)%bse
		d=(d+1)%bse
		ins=ins+1
		if ins>9000 then
			return "Time limit exeeded."..dbo
		end
	end
end)
hook.new({"command_mbdbg","command_malbolgedbg"},function(user,chan,txt)
	return hook.queue("command_mb",user,chan,txt,true)
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
do
	local conv=dofile("barely_conversion.lua")
	hook.new("command_encbarely",function(user,chan,txt)
		local last=126
		return "]"..txt:gsub(".",function(t)
			t=t:byte()
			local o=conv[last][t].."x"
			last=t
			return o
		end):reverse().."~"
	end)
end
hook.new("command_barely",function(user,chan,txt)
	local stdin=txt:match("~(.*)")
	txt=txt:match("^(.-)~")
	if not txt or txt:match("[^%]%^bfghijklmnopqstx~]") or not stdin then
		return "Unexpected "..((txt or ""):match("[^%]%^bfghijklmnopqstx~]") or "~")
	end
	local ip=#txt
	txt=txt.."~"..stdin
	local cell=setmetatable({},{__index=function() return 0 end})
	local mp=0
	local jmp=0
	local acc=126
	local o=""
	local se
	local insnum=0
	while ip>0 and ip<#txt+1 do
		local ins=se or txt:sub(ip,ip)
		se=nil
		if ins=="]" then
			return o
		elseif ins=="^" then
			if acc==0 then
				se="b"
			end
		elseif ins=="b" then
			ip=ip+jmp
		elseif ins=="g" then
			acc=cell[mp]
			se="i"
		elseif ins=="h" then
			acc=(acc+71)%256
			se="k"
		elseif ins=="i" then
			mp=mp+1
			se="j"
		elseif ins=="j" then
			acc=(acc+1)%256
			se="k"
		elseif ins=="k" then
			jmp=jmp-1
		elseif ins=="m" then
			cell[mp]=acc
			se="o"
		elseif ins=="n" then
			mp=mp-1
			se="o"
		elseif ins=="o" then
			acc=(acc-1)%256
			se="p"
		elseif ins=="p" then
			jmp=jmp+16
		elseif ins=="t" then
			if #stdin==0 then
				return "End of stdin, "..o
			end
			acc=string.byte(stdin,1,1)
			stdin=stdin:sub(2)
		elseif ins=="x" then
			o=o..string.char(acc)
		end
		if not se then
			ip=ip-1
		end
		insnum=insnum+1
		if insnum>9000 then
			return "Time limit exeeded."
		end
	end
	return o
end)

hook.new({"command_sstack"},function(user,chan,txt)
	txt=txt.." "
	local stack={}
	local function push(val)
		table.insert(stack,1,math.floor((type(val)=="boolean" and (val and 1 or 0) or val)%256))
	end
	local function pop(n)
		local v=stack[n or 1]
		table.remove(stack,n or 1)
		return v or 0
	end
	local sb
	local ins={
		["(%d+)"]=function(num)
			sb=#num
			return "push("..num..")"
		end,
		["add"]=function()
			sb=3
			return "push(pop()+pop())"
		end,
		["sub"]=function()
			sb=3
			return "push(pop(2)-pop())"
		end,
		["mul"]=function()
			sb=3
			return "push(pop()*pop())"
		end,
		["div"]=function()
			sb=3
			return "push(pop(2)/pop())"
		end,
		["mod"]=function()
			sb=3
			return "push(pop(2)%pop())"
		end,
		["random"]=function()
			sb=6
			return "push(math.random(0,pop()-1))"
		end,
		["and"]=function()
			sb=3
			return "push(pop()~=0 and pop()~=0)"
		end,
		["or"]=function()
			sb=2
			return "push(pop()~=0 or pop()~=0)"
		end,
		["xor"]=function()
			sb=3
			return "push((pop()==0)~=(pop()==0))"
		end,
		["nand"]=function()
			sb=4
			return "push(not (pop()~=0 and pop()~=0))"
		end,
		["not"]=function()
			sb=3
			return "push(pop()==0)"
		end,
		["output"]=function()
			sb=3
			return "o=o..pop()..\" \""
		end,
		["input"]=function()
			sb=5
			return "error(\"Input not supported.\",0)"
		end,
		["outputascii"]=function()
			sb=11
			return "o=o..string.char(pop())"
		end,
		["inputascii"]=function()
			sb=10
			return "error(\"Input not supported.\",0)"
		end,
		["pop"]=function()
			sb=3
			return "pop()"
		end,
		["swap"]=function()
			sb=4
			return "stack[1],stack[2]=stack[2],stack[1]"
		end,
		["cycle"]=function()
			sb=5
			return "table.insert(stack,pop())"
		end,
		["rcycle"]=function()
			sb=6
			return "push(table.remove(stack))"
		end,
		["dup"]=function()
			sb=3
			return "push(stack[1])"
		end,
		["rev"]=function()
			sb=3
			return "table.reverse(stack)"
		end,
		["if"]=function()
			sb=2
			return "while stack[1]>0 do"
		end,
		["fi"]=function()
			sb=2
			return "end"
		end,
		["quit"]=function()
			sb=4
			return "error(o,0)"
		end,
		["debug"]=function()
			sb=5
			return "o=o..table.concat(stack,\" | \")..\" \""
		end,
		["\"(.-)\""]=function(txt)
			sb=#txt+2
			return "for l1="..#txt..",1,-1 do push((\""..txt.."\"):byte(l1,l1)) end"
		end,
	}
	local out=""
	while #txt>0 do
		sb=1
		for k,v in pairs(ins) do
			local p={txt:match("^"..k.."%s")}
			if p[1] then
				out=out..v(unpack(p)).." "
			end
		end
		txt=txt:sub(sb+1)
	end
	local func,err=loadstring(out.."return o")
	if not func then
		return err
	end
	local func=coroutine.create(setfenv(func,{
		push=push,
		pop=pop,
		stack=stack,
		string=string,
		math=math,
		table=table,
		o="",
	}))
	debug.sethook(func,function() error("Time limit exeeded.",0) end,"",100000)
	local err,res=coroutine.resume(func)
	return res or "nil"
end)

hook.new("command_repnotate",function(user,chan,txt)
	local o=""
	while #txt>0 do
		local n=txt:match("^"..pescape(txt:sub(1,1)).."+")
		if #n>2 then
			o=o..txt:sub(1,1)..#n
		else
			o=o..n
		end
		txt=txt:sub(#n+1)
	end
	return o
end)

hook.new({"command_df","command_deadfish"},function(user,chan,txt)
	local o=""
	local ac=0
	txt:gsub("(.)(%d+)",function(char,cnt)
		return char:rep(tonumber(cnt))
	end):gsub(".",function(ins)
		if ins=="i" then
			ac=ac+1
		elseif ins=="d" then
			ac=ac-1
		elseif ins=="s" then
			ac=ac^2
		elseif ins=="o" then
			o=o..string.char(ac)
		end
		ac=(ac>=256 or ac<=-1) and 0 or ac
	end)
	return o
end)

hook.new({"command_fishstacks"},function(user,chan,txt)
	local o=""
	local ac=0
	txt:gsub("(.)(%d+)",function(char,cnt)
		return char:rep(tonumber(cnt))
	end):gsub(".",function(ins)
		if ins=="i" then
			ac=ac+1
		elseif ins=="d" then
			ac=ac-1
		elseif ins=="s" then
			ac=ac^2
		elseif ins=="p" then
			o=o..string.char(ac)
			ac=0
		end
		ac=(ac>=256 or ac<=-1) and 0 or ac
	end)
	return o:sub(1,-3)
end)

do
	local sqr={[0]={0,0},{0,0}}
	local tsqr={
		[0]="","is","iis","iiis","iiss","iisis","iisiis","iiisdds","iiisds",
		"iiiss","iiisis","iiisiis","iiisiiis","iissddds","iissdds","iissds",
	}
	for l1=2,210 do
		sqr[l1]={math.floor(math.sqrt(l1)+0.5),math.floor(math.sqrt(l1)+0.5)^2}
	end
	for l1=211,255 do
		sqr[l1]={15,225}
	end
	local o={}
	for x=0,255 do
		local prw=sqr[x]
		local sdt=x-prw[2]
		o[string.char(x)]=tsqr[prw[1]]..(sdt>0 and "i" or "d"):rep(math.abs(sdt))
	end
	hook.new({"command_fishencode"},function(user,chan,txt)
		return txt:gsub(".",function(t) return o[t].."p" end).."ppp"
	end)
end

function ntob64(n)
	local o=""
	while n>0 do
		o=_tob64[n%64]..o
		n=math.floor(n/64)
	end
	return o
end
function nunb64(n)
	local o=0
	for l1=#n,1,-1 do
		o=o+((2^(l1-1))*_unb64[n:sub(l1,l1)])
	end
	return o
end
hook.new({"command_rl"},function(user,chan,txt)
	local ip=1
	local reg={b=false,n=0,s=""}
	local stack={b={},n={},s={}}
	local clstack={0}
	local o=""
	local tpe={
		["string"]="s",
		["number"]="n",
		["boolean"]="b",
	}
	local face={
		["n"]=0,
		["e"]=1,
		["s"]=2,
		["w"]=3,
		["u"]=4,
		["d"]=5,
		[0]="n","e","s","w","u","d"
	}
	local inv={
		0,0,0,0,
		0,0,0,0,
		0,0,0,0,
		0,0,0,0,
	}
	local x,y,z,f=0,64,0,0
	local map=setmetatable({},{
		__index=function(s,x) 
			local o=setmetatable({},{
				__index=function(s,y)
					local o=setmetatable({},{
						__index=function(s,z)
							local o=0
							if y==0 then
								o=2
							elseif y<64 then
								o=1
							end
							s[z]=o
							return o
						end
					})
					s[y]=o
					return o
				end
			})
			s[x]=o
			return o
		end
	})
	local ins=0
	local function pop(n)
		if not stack[n] then
			error(ip..","..n)
		end
		local t=stack[n][1]
		table.remove(stack[n],1)
		return t
	end
	local tdir={
		["l"]=-1,
		["f"]=0,
		["r"]=1,
		["b"]=2,
	}
	local coord={
		["n"]={1,0,0},
		["e"]={0,0,1},
		["s"]={-1,0,0},
		["w"]={0,0,-1},
		["u"]={0,1,0},
		["d"]={0,-1,0},
	}
	local function pdir(dir)
		if face[dir] then
			return face[dir]
		end
		return (tdir[dir]+f)%4
	end
	local function parse(p)
		local pr=p:sub(1,1)
		if pr=="#" then
			local ln=_unb64[p:sub(2,2)]
			return nunb64(p:sub(3,2+ln)),2+ln
		elseif pr=="'" then
			local ln=_unb64[p:sub(2,2)]
			return p:sub(3,2+ln),2+ln
		elseif reg[pr]~=nil then
			return reg[pr],1
		elseif pr=="1" then
			return true,1
		elseif pr=="0" then
			return false,1
		elseif tdir[pr] or face[pr] then
			return pdir(pr),1
		end
	end
	local function tgoto(dir,len)
		local d=pdir(dir)
		local dx,dy,dz=unpack(coord[dir])
		while len>0 do
			local nx,ny,nz=x+dx,y+dy,z+dz
			if map[nx][ny][nz]>0 then
				return false
			end
			len=len-1
			x,y,z=nx,ny,nz
		end
		return true
	end
	while ip>0 and ip<#txt do
		local op=txt:sub(ip,ip)
		local p=txt:sub(ip+1)
		if op=="M" then
			local len,st=parse(p:sub(2))
			reg.b=tgoto(p:sub(1,1),len)
			ip=ip+2+st
		elseif op=="F" then
			f=pdir(p:sub(1,1))
			ip=ip+2
		elseif op=="D" then
			local crd,st=parse(p)
			local lx,ly,lz=unpack(coord[face[crd]])
			lx,ly,lz=lx+x,ly+y,lz+z
			if map[lx][ly][lz]>1 then
				reg.b=false
			else
				inv[1]=inv[1]+1
				local n=1
				while inv[n]>64 do
					inv[n]=64
					if n==16 then
						break
					end
					inv[n+1]=inv[n+1]+1
					n=n+1
				end
				map[lx][ly][lz]=0
				reg.b=true
			end
			ip=ip+1+st
		elseif op=="U" then
			ip=ip+1
		elseif op=="P" then
			local crd,st=parse(p)
			local lx,ly,lz=unpack(coord[face[crd]])
			lx,ly,lz=lx+x,ly+y,lz+z
			local sl,st2=parse(p:sub(st+1))
			if inv[sl]>0 then
				if map[lx][ly][lz]>0 then
					reg.b=false
					inv[sl]=inv[sl]-1
				else
					map[lx][ly][lz]=1
					reg.b=true
				end
			end
			ip=ip+1+st+st2
		elseif op=="R" then
			local crd,st=parse(p)
			local sl,st2=parse(p:sub(st+1))
			local cnt,st3=parse(p:sub(st2+st+1))
			if inv[sl]>=cnt then
				inv[sl]=inv[sl]-cnt
				reg.b=true
			else
				reg.b=false
			end
			ip=ip+1+st+st2+st3
		elseif op=="S" then
			local sl,st=parse(p)
			reg.b=false
			ip=ip+1+st
		elseif op=="G" then
			local ax=p:sub(1,1)
			local ep,st=parse(p:sub(2))
			local dt
			if ax=="x" then
				dt=x-ep
			elseif ax=="y" then
				dt=y-ep
			elseif ax=="z" then
				dt=z-ep
			end
			reg.b=tgoto(dt>0 and "n" or "s",math.floor(dt))
			ip=ip+2+st
		elseif op=="C" then
			local crd,st=parse(p)
			local lx,ly,lz=unpack(coord[face[crd]])
			lx,ly,lz=lx+x,ly+y,lz+z
			local sl,st2=parse(p:sub(st+1))
			reg.b=map[lx][ly][lz]==inv[sl]
			ip=ip+1+st+st2
		elseif op=="T" then
			local crd,st=parse(p)
			local lx,ly,lz=unpack(coord[face[crd]])
			lx,ly,lz=lx+x,ly+y,lz+z
			local sl,st2=parse(p:sub(st+1))
			reg.b=map[lx][ly][lz]==inv[sl]
			ip=ip+1+st+st2
		elseif op=="H" then
			table.insert(stack[p:sub(1,1)],1,reg[p:sub(1,1)])
			ip=ip+2
		elseif op=="O" then
			table.remove(stack[p:sub(1,1)],1)
			ip=ip+2
		elseif op=="K" then
			local ln,st=parse(p:sub(2))
			print("K"..p:sub(1,1)..ln)
			reg[p:sub(1,1)]=stack[p:sub(1,1)][ln]
			ip=ip+2+st
		elseif op=="B" then
			local ln,st=parse(p:sub(2))
			for l1=1,st do
				pop(p:sub(1,1))
			end
			ip=ip+2+st
		elseif op==">" then
			reg.b=pop("n")>reg.n
			ip=ip+1
		elseif op=="<" then
			reg.b=pop("n")<reg.n
			ip=ip+1
		elseif op=="+" then
			reg.n=pop("n")+reg.n
			ip=ip+1
		elseif op=="-" then
			reg.n=pop("n")-reg.n
			ip=ip+1
		elseif op=="*" then
			reg.n=pop("n")*reg.n
			ip=ip+1
		elseif op=="/" then
			reg.n=math.floor(pop("n")/reg.n)
			ip=ip+1
		elseif op=="%" then
			reg.n=pop("n")%reg.n
			ip=ip+1
		elseif op=="^" then
			reg.n=pop("n")^reg.n
			ip=ip+1
		elseif op=="!" then
			reg.b=not reg.b
			ip=ip+1
		elseif op=="&" then
			reg.b=pop("b") and reg.b
			ip=ip+1
		elseif op=="|" then
			reg.b=pop("b") or reg.b
			ip=ip+1
		elseif op=="=" then
			reg.b=pop(p:sub(1,1))==reg[p:sub(1,1)]
			ip=ip+2
		elseif op=="J" or op=="I" then
			if op~="I" or reg.b then
				ip=parse(p)
			else
				ip=ip+1
			end
		elseif op=="L" then
			local nip,st=parse(p)
			table.insert(clstack,ip+st+1)
			ip=nip
		elseif op=="N" then
			ip=cltack[1]
			table.remove(clstack,1)
		elseif op=="V" then
			local vl,st=parse(p)
			reg[tpe[type(vl)]]=vl
			ip=ip+1+st
		elseif op=="." then
			o=o..tostring(reg[p:sub(1,1)])
			ip=ip+2
		elseif parse(op..p)~=nil then
			local vl,st=parse(op..p)
			reg[tpe[type(vl)]]=vl
			ip=ip+st
		elseif op==" " then
			ip=ip+1
		else
			return o.."ip:"..ip..":Invalid opcode: "..op
		end
		ins=ins+1
		if ins>9000 then
			return o.."ip:"..ip..":Time limit exeeded."
		end
	end
	return o
end)