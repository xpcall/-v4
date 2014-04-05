local _,eris=pcall(require,"eris")
if not _ then
	eris=nil
end
local sapis={
	math=math,
	string=string,
	bit32=bit32,
	table=table,
	coroutine=coroutine,
}
local sbox
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
	print=print,
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
		write=io.write,
		output=io.output,
	},
}
sbox._G=sbox
for k,v in pairs(sapis) do
	sbox[k]={}
	for n,l in pairs(v) do
		sbox[k][n]=l
	end
end
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
local o={coroutine.resume(func)}
for l1=2,#o do
	print(tostring(o[l1]))
end
