crypt={}
function crypt.xor(a,b)
	b=b:rep(math.ceil(#a/#b)):sub(1,#a)
	local o=""
	for l1=1,#a do
		o=o..string.char(bit.bxor(a:sub(l1,l1):byte(),b:sub(l1,l1):byte()))
	end
	return o
end
function crypt.rot13(txt)
	return txt:gsub("%l",function(c)
		return string.char(((c:byte()-84)%26)+97)
	end):gsub("%u",function(c)
		return string.char(((c:byte()-52)%26)+65)
	end)
end
function crypt.rot47(txt)
	txt=txt:gsub(".",function(c) if c:byte()<127 and c:byte()>32 then return string.char((((c:byte()-33)+47)%94)+33) end end)
	return txt
end
hook.new("commanyd_rot13",function(user,chan,txt)
	return crypt.rot13(txt)
end,{
	desc="most secure encryption ever made",
	group="fun",
})
hook.new("command_rot47",function(user,chan,txt)
	return crypt.rot47(txt)
end,{
	desc="second most secure encryption ever made",
	group="fun",
})
function crypt.space(txt)
	return tobase(txt,nil,"01234567")
		:gsub("0","\226\128\139")
		:gsub("1","\226\128\138")
		:gsub("2","\226\128\137")
		:gsub("3","\226\128\136")
		:gsub("4","\194\160")
		:gsub("5","\226\128\128")
		:gsub("6","\226\128\175")
		:gsub("7","\226\129\159")
end
function crypt.unspace(txt)
	return tobase(txt
		:gsub("\226\128\139","0")
		:gsub("\226\128\138","1")
		:gsub("\226\128\137","2")
		:gsub("\226\128\136","3")
		:gsub("\194\160","4")
		:gsub("\226\128\128","5")
		:gsub("\226\128\175","6")
		:gsub("\226\129\159","7")
	,"01234567")
end
function crypt.color(txt,cl)
	cl=tobase(cl,nil,"0123456789ABCDEF")
	return txt:gsub("%S",function(char)
		if cl~="" then
			local o="\3"..tobase(cl:sub(1,1),"0123456789ABCDEF","0123456789",2)..char
			cl=cl:sub(2)
			return o..(#cl==0 and "\15" or "")
		end
	end)
end
function crypt.decolor(txt)
	local o=""
	for cl in txt:gmatch("\3(%d%d)") do
		o=o..string.format("%X",tonumber(cl))
	end
	return tobase(o,"0123456789ABCDEF")
end