local function decodeBits(n)
	if type(n)=="string" then
		local bits={}
		for l1=1,#sbits do
			local c=sbits:byte(l1,l1)
			for l2=0,7 do
				table.insert(bits,(c/(2^l2))%2)
			end
		end
		return bits
	else
		
	end
end
function dissectfloat(n)
	local sbits=string.pack(">n")
	return bits[1],encodeBits()
end
