crypt={}
function crypt.xor(a,b)
	b=b:rep(math.ceil(#a/#b)):sub(1,#a)
	local o=""
	for l1=1,#a do
		o=o..string.char(bit.bxor(a:sub(l1,l1):byte(),b:sub(l1,l1):byte()))
	end
	return o
end