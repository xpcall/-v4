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
	txt=txt:gsub("%l",function(c)
		return string.char((((c:byte()-97)+13)%26)+97)
	end):gsub("%u",function(c)
		return string.char((((c:byte()-65)+13)%26)+65)
	end)
	return txt
end
hook.new("command_rot13",function(user,chan,txt)
	return crypt.rot13(txt)
end)