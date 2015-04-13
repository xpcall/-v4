nbt={}

local readTag
local tagname={
	[0]="end",
	"byte",
	"short",
	"int",
	"long",
	"float",
	"double",
	"byte array",
	"string",
	"list",
	"compound",
	"int array",
}
local tagid={
	["end"]=0,
	["byte"]=1,
	["short"]=2,
	["int"]=3,
	["long"]=4,
	["float"]=5,
	["double"]=6,
	["byte array"]=7,
	["string"]=8,
	["list"]=9,
	["compound"]=10,
	["int array"]=11,
}
function readTag(txt,id)
	local function readData(fmt)
		local o=string.unpack(fmt,txt)
		txt=txt:sub(string.packsize(fmt)+1)
		return o
	end
	local name
	if not id then
		id=readData(">b")
		if id==0 then
			return txt,{type="end"}
		end
		local nmlen=readData(">H")
		name=txt:sub(1,nmlen)
		txt=txt:sub(nmlen+1)
	end
	local out={type=tagname[id] or "corrupt",name=name}
	if id==1 then
		out.value=readData(">b")
	elseif id==2 then
		out.value=readData(">h")
	elseif id==3 then
		out.value=readData(">i4")
	elseif id==4 then
		out.value=readData(">i8")
	elseif id==5 then
		out.value=readData(">f")
	elseif id==6 then
		out.value=readData(">d")
	elseif id==7 then
		local size=readData(">i4")
		local o={}
		for l1=1,size do
			table.insert(o,readData(">b"))
		end
		out.values=o
	elseif id==8 then
		local len=readData(">h")
		local o=txt:sub(1,len)
		txt=txt:sub(len+1)
		out.value=o
	elseif id==9 then
		local tagid=readData(">b")
		local size=readData(">i4")
		local o={}
		for l1=1,size do
			local ot
			txt,ot=readTag(txt,tagid)
			table.insert(o,ot)
		end
		out.values=o
		out.types=tagname[tagid]
	elseif id==10 then
		local o={}
		while true do
			local ot
			txt,ot=readTag(txt)
			if ot.type=="end" then
				break
			end
			table.insert(o,ot)
		end
		out.values=o
	elseif id==11 then
		local size=readData(">i4")
		local o={}
		for l1=1,size do
			table.insert(o,readData(">i4"))
		end
		out.values=o
	end
	return txt,out
end

local writeTag
function writeTag(v,raw)
	print("writing "..serialize(v))
	local o=""
	if not raw then
		o=o..string.pack(">b",tagid[v.type])
		if v.type~="end" then
			local name=v.name or ""
			o=o..string.pack(">H",#name)..name
		end
	end
	if v.type=="end" then
		return o.."\0"
	elseif v.type=="byte" then
		return o..string.pack(">b",v.value)
	elseif v.type=="short" then
		return o..string.pack(">h",v.value)
	elseif v.type=="int" then
		return o..string.pack(">i4",v.value)
	elseif v.type=="long" then
		return o..string.pack(">i8",v.value)
	elseif v.type=="float" then
		return o..string.pack(">f",v.value)
	elseif v.type=="double" then
		return o..string.pack(">d",v.value)
	elseif v.type=="byte array" then
		o=o..string.pack(">i4",#v.values)
		for l1=1,#v.values do
			o=o..string.pack(">b",v.values[l1])
		end
		return o
	elseif v.type=="string" then
		return o..string.pack(">H",#v.value)..v.value
	elseif v.type=="list" then
		o=o..string.pack(">b",tagid[v.types])
		o=o..string.pack(">i4",#v.values)
		for l1=1,#v.values do
			o=o..writeTag(v.values[l1],true)
		end
		return o
	elseif v.type=="compound" then
		for l1=1,#v.values do
			o=o..writeTag(v.values[l1])
		end
		return o.."\0"
	elseif v.type=="int array" then
		o=o..string.pack(">i4",#v.values)
		for l1=1,#v.values do
			o=o..string.pack(">i4",v.values[l1])
		end
		return o
	end
	return ""
end

function nbt.decoderaw(txt)
	local o
	txt,o=readTag(txt)
	return o
end

function nbt.decode(txt)
	txt=lz.inflate()(txt)
	local o
	txt,o=readTag(txt)
	return o
end

function nbt.encoderaw(t)
	return writeTag(t)
end

function nbt.encode(t)
	local o=lz.deflate()(writeTag(t))
	return o
end
