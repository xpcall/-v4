--[===[

32 bit registers:
	rw 0x00-FA    # general purpose
	r  0xFB    uo # ALU out
	r  0xFC    ui # ALU carry in
	r  0xFD    uc # ALU carry out
	rw 0xFE    ip # instruction number
	w  0xFF    ht # halt

instruction formats:
	i    # 0xII000000
	iA   # 0xIIAA0000
	iAA  # 0xIIAAAA00
	iAB  # 0xIIAABB00
	iAAA # 0xIIAAAAAA
	iAAB # 0xIIAAAABB
	iABB # 0xIIAABBBB
	iABC # 0xIIAABBCC

32 bit instructions:
	0x00 iA   inw # wait until I[A] changes
	0x01 iAB  inr # R[A]=I[B]
	0x02 iAB  ins # I[A]=R[B]
	0x03 iAB  rsr # R[A]=R[B]
	0x04 iABB rsl # R[A]=B
	0x05 iABB rsu # R[A]=(R[A]&0xFFFF)|(B<<16)
	0x06 iAB  rrm # R[R[A]]=R[B]
	0x07 iAB  rsm # R[A]=R[R[B]]
	0x08 iABC acl # uo,uc=ALU[C] ui=0
	0x09 iABB mrc # R[A]=M[B]
	0x0A iAAB msc # M[A]=R[B]
	0x0B iAB  mrr # R[A]=M[R[B]]
	0x0C iAB  msr # M[R[A]]=R[B]
	
alu:
	0x00 ui+A+B
	0x01 ui-A-B
	0x02 ui+A*B
	0x03 ui?A:B
	0x04 A&B
	0x05 A|B
	0x06 A^B
	0x07 A>>B
	0x08 A<<B
	0x09 A==B
	0x0A !A
	0x0B A>B
]===]
local instructions={
	["A"]="B",
	["AA"]="H",
	["AB"]="BB",
	["AAB"]="HB",
	["ABB"]="BH",
	["ABC"]="BBB",
}

function cpu()
	local m=ffi.new("int[65536]")
	local r=ffi.new("int[256]")
	local p=""
	local i=ffi.new("int[256]")
	local ip=0xFE
	local ins
	local function i(t)
		return string.unpack(">"..instructions[t])
	end
	local function nextInstruction()
		ins=p:sub((r[ip]*4)+2,(r[ip]+1)*4)
		local nins=p:byte(1)
		if nins==0x00 then
			local A=i("A")
		elseif nins==0x01 then
			local A,B=i("AB")
			r[A]=i[B]
		elseif nins==0x02 then
			local A,B=i("AB")
			i[A]=r[B]
		elseif nins==0x03 then
			local A,B=i("AB")
			r[A]=r[B]
		elseif nins==0x04 then
			local A,B=i("AB")
			r[A]=r[B]
		end
	end
end

function asmbytecode(txt)
	local function readShort(txt)
		return (txt:byte(1)*256)+txt:byte(2)
	end
	local function readMed(txt)
		return (txt:byte(1)*65536)+(txt:byte(2)*256)+txt:byte(3)
	end
	local fmts={
		i="",
		iA="B",
		iAA="S",
		iAB="BB",
		iAAA="M",
		iAAB="SB",
		iABB="BS",
		iABC="BBB",
	}
	local ins={
		[0x00]={"inw","iA"},
		[0x01]={"inr","iAB"},
		[0x02]={"ins","iAB"},
		[0x03]={"rsr","iAB"},
		[0x04]={"rsl","iABB"},
		[0x05]={"rsu","iABB"},
		[0x06]={"rrm","iAB"},
		[0x07]={"rsm","iAB"},
		[0x08]={"acl","iABC"},
		[0x09]={"mrc","iABB"},
		[0x0A]={"msc","iAAB"},
		[0x0B]={"mrr","iAB"},
		[0x0C]={"msr","iAB"},
	}
	local o=""
	while #txt>0 do
		local cns=txt:byte(1)
		local d=ins[cns]
		assert(d,"Invalid instruction "..cns)
		local p={}
		local cb=2
		for c in fmts[d[2]]:gmatch(".") do
			if c=="B" then
				table.insert(p,txt:byte(cb))
				cb=cb+1
			elseif c=="S" then
				table.insert(p,readShort(txt:sub(cb)))
				cb=cb+2
			elseif c=="M" then
				table.insert(p,readMed(txt:sub(cb)))
				cb=cb+3
			end
		end
		o=o..d[1].." "..table.concat(p," ").."\n"
		txt=txt:sub(5)
	end
	return o
end

function asmbinary(txt)
	local function writeShort(n)
		return string.char(math.floor(n/256),n%256)
	end
	local function writeMed()
		return string.char(math.floor(n/65536),math.floor(n/256),n%256)
	end
	local fmts={
		i="",
		iA="B",
		iAA="S",
		iAB="BB",
		iAAA="M",
		iAAB="SB",
		iABB="BS",
		iABC="BBB",
	}
	local ins={
		inw={0x00,"iA"},
		inr={0x01,"iAB"},
		ins={0x02,"iAB"},
		rsr={0x03,"iAB"},
		rsl={0x04,"iABB"},
		rsu={0x05,"iABB"},
		rrm={0x06,"iAB"},
		rsm={0x07,"iAB"},
		acl={0x08,"iABC"},
		mrc={0x09,"iABB"},
		msc={0x0A,"iAAB"},
		mrr={0x0B,"iAB"},
		msr={0x0C,"iAB"},
	}
	local o=""
	for i in txt:gmatch("[^\n]+") do
		local cns,p=i:match("^(%l+) (.-)$")
		local pms={}
		for pr in p:gmatch("%S+") do
			table.insert(pms,tonumber(pr))
		end
		local d=ins[cns]
		o=o..string.char(d[1])
		local tz=3
		local pmn=0
		for c in fmts[d[2]]:gmatch(".") do
			pmn=pmn+1
			if c=="B" then
				o=o..string.char(pms[pmn])
				tz=tz-1
			elseif c=="S" then
				o=o..writeShort(pms[pmn])
				tz=tz-2
			elseif c=="M" then
				o=o..writeMed(pms[pmn])
				tz=tz-3
			end
		end
		o=o..("\0"):rep(tz)
	end
	return o
end

function asmcompile(txt,raw)
	local dregs={
		[0xFB]="uo",
		[0xFC]="ui",
		[0xFD]="uc",
		[0xFE]="ip",
		[0xFF]="ht",
	}
	local regs={}
	local jmps={}
	local function findNext(txt,ch)
		local bb={
			["("]=1,
			["["]=2,
		}
		local eb={
			[")"]=1,
			["]"]=2,
		}
		local brs={}
		local n=0
		for char in txt:gmatch(".") do
			if bb[char] then
				table.insert(brs,bb[char])
			elseif eb[char] then
				if #brs==0 then
					break
				end
				if brs[#brs]~=eb[char] then
					error("Syntax error ("..txt.."):"..n..":"..char.." "..serialize(brs))
				end
				table.remove(brs)
			elseif char==ch and #brs==0 then
				break
			end
			n=n+1
		end
		return txt:sub(1,n),txt:sub(n+1)
	end
	local function findMatching(txt,a,b)
		local c=1
		local o=""
		repeat
			local co=txt:match("^[^"..pescape(a..b).."]*")
			o=o..co
			txt=txt:sub(#co+1)
			if txt=="" then
				return false
			end
			if txt:sub(1,1)==a then
				c=c+1
			elseif txt:sub(1,1)==b then
				c=c-1
			end
			o=o..txt:sub(1,1)
			txt=txt:sub(2)
		until c==0
		return o,txt
	end
	local function newReg()
		local nr
		for l1=0x00,0xFA do
			if not regs[l1] then
				nr=l1
				break
			end
		end
		if not nr then
			error("Out of registers")
		end
		return nr
	end
	local function getReg(n)
		for k,v in pairs(regs) do
			if n==v then
				return k
			end
		end
		for k,v in pairs(dregs) do
			if n==v then
				return k
			end
		end
		local nr=newReg()
		regs[nr]=n
		return nr
	end
	local function cl()
		return "line "..debug.traceback():match("^.-\n.-\n%s*.-(%d+).-\n")
	end
	local function cleanup(v)
		if v.temp then
			regs[v.value]=nil
		end
	end
	local function conv(k,v)
		if type(k)=="string" then
			if v.type==k then
				return v
			end
			if k~="register" then
				error("Cannot create "..k)
			end
			k={type=k,value=newReg(),temp=true}
			regs[k.value]=true
		end
		tpe=k.type
		local code=(k.code or "")..(v.code or "")
		if tpe=="register" then
			if v.type=="constant" then
				code=code.."rsl "..k.value.." "..(v.value%0x10000).."\n"
				if v.value>0xFFFF then
					code=code.."rsu "..k.value.." "..(v.value/0x10000).."\n"
				end
				k.code=code
				return k
			elseif v.type=="register" then
				if v.notemp then
					code=(k.code or "")..v.notemp.."rsm "..k.value.." "..v.notempv.."\n"
				elseif k.notemp then
					cleanup(k)
					code=k.notemp..(v.code or "").."rrm "..k.notempv.." "..v.value.."\n"
				else
					code=code.."rsr "..k.value.." "..v.value.."\n"
				end
				cleanup(v)
				k.code=code
				return k
			elseif v.type=="interrupt" then
				code=code.."inr "..k.value.." "..v.value.."\n"
				k.code=code
				return k
			elseif v.type=="memory" then
				code=code.."mrc "..k.value.." "..v.value.."\n"
				k.code=code
				return k
			end
		elseif k.type=="interrupt" then
			local n=conv("register",v)
			code=code..n.code.."ins "..k.value.." "..n.value.."\n"
			cleanup(n)
		elseif k.type=="memory" then
			local n=conv("register",v)
			code=code..n.code.."msc "..k.value.." "..n.value.."\n"
			cleanup(n)
		end
		error("Cannot convert "..val.type.." to "..tpe)
	end
	local parseExp
	function parseExp(txt)
		txt=txt:match("^%s*(.-)%s*$")
		while txt:match("^%(.-%)$") do
			txt=txt:match("^%(%s*(.-)%s*%)$")
		end
		local jmp,etxt=txt:match("^<%s*(%l+)%s*>%s*(.-)$")
		if jmp then
			table.insert()
		end
		local fp,etxt=findNext(txt,"=")
		if etxt and etxt:sub(1,1)=="=" then
			local kr=parseExp(fp)
			local v=etxt:sub(2)
			local vr=parseExp(v)
			o=conv(kr,vr)
			if o then
				return o
			end
			error("no such instruction "..g.."["..kr.type.."]="..vr.type)
		end
		local g,k=txt:match("^(%u+)%[%s*(.-)%s*%]$")
		if g then
			local kr=parseExp(k)
			if g=="R" then
				if kr.type=="constant" then
					o={type="register",value=kr.value}
				elseif kr.type=="register" then
					if kr.temp then
						kr.code=(kr.code or "").."rsm "..kr.value.." "..kr.value.."\n"
						return kr
					else
						local o={
							type="register",
							temp=true,
							value=newReg()
						}
						regs[o.value]=true
						o.notemp=kr.code or ""
						o.notempv=kr.value
						o.code=(kr.code or "").."rsm "..o.value.." "..kr.value.."\n"
						return o
					end
				end
			elseif g=="I" then
				if kr.type=="constant" then
					o={type="interrupt",value=kr.value}
				end
			end
			if kr.temp then
				reg[kr.value]=nil
			end
			if o then
				return o
			end
			error("no such value "..g.."["..kr.type.."]")
		end
		local rg=txt:match("^(%l+)$")
		if rg then
			return {type="register",value=getReg(rg)}
		end
		local num=txt:match("^(%d+)$")
		if num then
			return {type="constant",value=tonumber(num)}
		end
		local num=txt:match("^0x(%x+)$")
		if num then
			return {type="constant",value=tonumber(num,16)}
		end
		local func,args=txt:match("^(%u+)%(%s*(.-)%s*%)$")
		if func then
			local code=""
			local oargs={}
			while #args>0 do
				local carg
				carg,args=findNext(args,",")
				args=args:sub(2)
				table.insert(oargs,parseExp(carg))
			end
			if func=="ALU" then
				assert(#oargs==3,"Invalid arguments")
				local a=conv("register",oargs[1])
				local b=conv("register",oargs[2])
				local c=conv("constant",oargs[3])
				code=code..(a.code or "")..(b.code or "").."acl "..a.value.." "..b.value.." "..c.value.."\n"
				cleanup(a)
				cleanup(b)
				return {type="register",value=0xFB,code=code}
			elseif func=="I" then
				assert(#oargs==1,"Invalid arguments")
				local a=conv("constant",oargs[1])
				code=code.."inw "..a.value.."\n"
				return {type="interrupt",value=a.value,code=code}
			elseif func=="C" then
				assert(#oargs==1,"Invalid arguments")
				assert(oargs[1].type=="register","Argument must be register")
				assert((oargs[1].code or "")=="","Argument must be constant register")
				return {type="constant",value=oargs[1].value,code=code}
			end
			error("No such function "..func)
		end
		error("Syntax error "..serialize(txt))
	end
	local o=""
	while #txt>1 do
		local statement,otxt=txt:match("^%s*(.-)%s*;%s*(.*)")
		txt=otxt
		assert(statement,"Syntax error")
		local st=parseExp(statement)
		assert(st.code,"Null statement")
		o=o..st.code
	end
	if raw then
		return asmbinary(o)
	end
	return o,regs
end

