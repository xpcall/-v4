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
sbox={
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
	debug.sethook(func)
	debug.sethook(func,function()
		error("Time limit exeeded.",0)
	end,"",1)
	error("Time limit exeeded.",0)
end,"",10000)
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
print((out..(o or "nil")):gsub("^[\r\n]+",""):gsub("[\r\n]+$",""):gsub("[\r\n]+"," | ")
	:gsub("[%z\2\4\5\6\7\8\9\10\11\12\13\14\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]","")
:sub(1,446))