function decodeBits(n,s)
	if type(n)=="string" then
		s=s or (#n*8)
		local bits={}
		for l1=1,math.min(s,#n) do
			local c=n:byte(l1,l1)
			for l2=0,7 do
				table.insert(bits,math.floor(c/(2^(7-l2)))%2)
			end
		end
		for l1=#bits+1,s do
			table.insert(bits,0)
		end
		return bits
	else
		local bits={}
		while n>0 and #bits<s do
			table.insert(bits,1,n%2)
			n=math.floor(n/2)
		end
		for l1=#bits+1,s do
			table.insert(bits,1,0)
		end
		return bits
	end
end

function encodeBits(bits,s)
	if s then
		local o=""
		for l1=1,#bits,8 do
			o=o..string.char(
				bits[l1+7]+
				bits[l1+6]*2+
				bits[l1+5]*4+
				bits[l1+4]*8+
				bits[l1+3]*16+
				bits[l1+2]*32+
				bits[l1+1]*64+
				bits[l1]*128
			)
		end
		return o
	else
		local o=0
		for l1=1,#bits do
			o=o+bits[l1]*(2^(#bits-l1))
		end
		return o
	end
end

function encodeDouble(f)
	if f==math.huge then
		return "\127\240\0\0\0\0\0\0"
	elseif f==-math.huge then
		return "\255\240\0\0\0\0\0\0"
	elseif f~=f then
		return "\255\248\0\0\0\0\0\0"
	elseif f==0 then
		if math.huge/f==math.huge then
			return "\0\0\0\0\0\0\0\0"
		else
			return "\127\0\0\0\0\0\0\0"
		end
	end
	local bits=64
	local expbits=11
	local shift=0
	local significandbits=52
	local sign=f<0 and 1 or 0
	local fnorm=f<0 and -f or f
	while fnorm>=2 do
		fnorm=fnorm/2
		shift=shift+1
	end
	while fnorm<1 do
		fnorm=fnorm*2
		shift=shift-1
	end
	fnorm=fnorm-1
	local significand=math.floor(fnorm*((2^significandbits)+0.5))
	local exp=shift+((2^(expbits-1))-1)
	return encodeBits(table.cat({sign},decodeBits(exp,expbits),decodeBits(significand,significandbits)),true)
end

function decodeDouble(txt)
	if txt=="\127\240\0\0\0\0\0\0" then
		return math.huge
	elseif txt=="\255\240\0\0\0\0\0\0" then
		return -math.huge
	elseif txt=="\255\248\0\0\0\0\0\0" then
		return 0/0
	elseif txt=="\0\0\0\0\0\0\0\0" then
		return 0
	elseif txt=="\127\0\0\0\0\0\0\0" then
		return -0
	end
	local data=decodeBits(txt)
	local bits=64
	local expbits=11
	local significandbits=52
	local result=encodeBits(table.sub(data,-significandbits,-1))
	result=(result/(2^significandbits))+1
	local bias=(2^(expbits-1))-1;
	shift=encodeBits(table.sub(data,2,bits-(significandbits)))-bias
	for l1=1,shift do
		result=result*2
	end
	for l1=-1,shift,-1 do
		result=result/2
	end
	return result*(data[1]==0 and 1 or -1)
end
