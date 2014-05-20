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