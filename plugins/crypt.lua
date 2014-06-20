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
function crypt.tohex(txt)
	return ({txt:gsub(".",function(c) return string.format("%02x",c:byte()) end)})[1]
end
function crypt.fromhex(txt)
	return ({txt:gsub("%X",""):gsub("%x%x?",function(c) return string.char(tonumber("0x"..c)) end)})[1]
end
hook.new("command_rot13",function(user,chan,txt)
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
crypt.hash={}
local u={}
for k,v in pairs(crypto.list("digests")) do
	local h=crypto.digest(v,"testfoo")
	if u[h] then
		hook.new("command_"..v,u[h],{
			desc=v.." hash",
			group="hashes",
		})
	else
		local func=function(user,chan,txt)
			return crypto.digest(v,txt)
		end
		hook.new({"command_"..v},func,{
			desc=v.." hash",
			group="hashes",
		})
		u[h]=func
	end
	crypt.hash[v]=function(txt,nohex)
		return crypto.digest(v,txt,nohex)
	end
end
crypt.encrypt={}
for k,v in pairs(crypto.list("ciphers")) do
	crypt.encrypt[v]=function(pass)
		return crypto.encrypt.new(v,pass)
	end
end
crypt.decrypt={}
for k,v in pairs(crypto.list("ciphers")) do
	crypt.decrypt[v]=function(pass)
		return crypto.decrypt.new(v,pass)
	end
end
hook.new({"command_hash","command_digest"},function(user,chan,txt)
	local err,res=pcall(crypto.digest,txt:match("^(%S+) ?(.*)$"))
	return res
end)

function crypt.salt(len)
	return crypto.rand.bytes(len)
end

function chars2num(txt)
	return (txt:byte(1)*16777216)+(txt:byte(2)*65536)+(txt:byte(3)*256)+(txt:byte(4))
end

function limit(num)
	return bit.band(num) 
end

local function num2chars(num,l)
	local out=""
	for l1=1,l or 4 do
		out=string.char(math.floor(num/(256^(l1-1)))%256)..out
	end
	return out
end

local function num2hex(num)
	return string.format("%08x",num)
end

do
	local bxor=bit.bxor
	local ror=bit.ror
	local rshift=bit.rshift
	local band=bit.band
	local bnot=bit.bnot
	
	local k={[0]=
		0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
		0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
		0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
		0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
		0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
		0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
		0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
		0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
	}
	function sha256(txt)
		local ha={[0]=
			0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
			0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19,
		}
		local len=#txt
		txt=txt.."\128"..("\0"):rep(64-((len+9)%64))..num2chars(8*len,8)
		print("herp: "..#txt)
		local w={}
		for chunkind=1,#txt,64 do
			local rawchunk=txt:sub(chunkind,chunkind+63)
			local chunk={}
			for i=1,64,4 do
				chunk[math.floor(i/4)]=chars2num(rawchunk:sub(i))
			end
			print(serialize(chunk))
			for i=0,15 do
				w[i]=chunk[i]
			end
			for i=16,63 do
				local s0=bxor(ror(w[i-15],7),ror(w[i-15],18),rshift(w[i-15],3))
				local s1=bxor(ror(w[i-2],17),ror(w[i-2],19),rshift(w[i-2],10))
				w[i]=w[i-16]+s0+w[i-7]+s1
			end
			print("darp: "..w[0]..","..w[16])
			local a,b,c,d,e,f,g,h=ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]
			for i=0,63 do
				local S1=bxor(ror(e,6),ror(e,11),ror(e,25))
				local ch=bxor(band(e,f),band(bnot(e),g))
				local temp1=limit(limit(h+S1)+limit(ch+k[i]+w[i]))
				local S0=bxor(ror(a,2),ror(a,13),ror(a,22))
				local maj=bxor(band(a,b),band(a,c),band(b,c))
				local temp2=S0+maj
				a,b,c,d,e,f,g,h=limit(temp1+temp2),a,b,c,limit(d+temp1),e,f,g
			end
			ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]=limit(ha[0]+a),limit(ha[1]+b),limit(ha[2]+c),limit(ha[3]+d),limit(ha[4]+e),limit(ha[5]+f),limit(ha[6]+g),limit(ha[7]+h)
			print("derp: "..ha[0])
		end
		return num2chars(ha[0])..num2chars(ha[1])..num2chars(ha[2])..num2chars(ha[3])..num2chars(ha[4])..num2chars(ha[5])..num2chars(ha[6])..num2chars(ha[7])
	end
end


reqplugin("bit64.lua")

local function chars2num64(txt)
	return {
		(txt:byte(1)*16777216)+(txt:byte(2)*65536)+(txt:byte(3)*256)+(txt:byte(4)),
		(txt:byte(5)*16777216)+(txt:byte(6)*65536)+(txt:byte(7)*256)+(txt:byte(8))
	}
end

local function num2chars64(num)
	if type(num)=="number" then
		return string.char((num/16777216)%256,(num/65536)%256,(num/256)%256,num%256)
	else
		return string.char(
			(num[1]/16777216)%256,(num[1]/65536)%256,(num[1]/256)%256,num[1]%256,
			(num[2]/16777216)%256,(num[2]/65536)%256,(num[2]/256)%256,num[2]%256
		)
	end
end

local function num2hex64(num)
	return string.format("%08x",num[1])..string.format("%08x",num[2])
end

local sha_512k={[0]=
	{0x428a2f98,0xd728ae22},{0x71374491,0x23ef65cd},{0xb5c0fbcf,0xec4d3b2f},{0xe9b5dba5,0x8189dbbc},{0x3956c25b,0xf348b538},
	{0x59f111f1,0xb605d019},{0x923f82a4,0xaf194f9b},{0xab1c5ed5,0xda6d8118},{0xd807aa98,0xa3030242},{0x12835b01,0x45706fbe},
	{0x243185be,0x4ee4b28c},{0x550c7dc3,0xd5ffb4e2},{0x72be5d74,0xf27b896f},{0x80deb1fe,0x3b1696b1},{0x9bdc06a7,0x25c71235},
	{0xc19bf174,0xcf692694},{0xe49b69c1,0x9ef14ad2},{0xefbe4786,0x384f25e3},{0x0fc19dc6,0x8b8cd5b5},{0x240ca1cc,0x77ac9c65},
	{0x2de92c6f,0x592b0275},{0x4a7484aa,0x6ea6e483},{0x5cb0a9dc,0xbd41fbd4},{0x76f988da,0x831153b5},{0x983e5152,0xee66dfab},
	{0xa831c66d,0x2db43210},{0xb00327c8,0x98fb213f},{0xbf597fc7,0xbeef0ee4},{0xc6e00bf3,0x3da88fc2},{0xd5a79147,0x930aa725},
	{0x06ca6351,0xe003826f},{0x14292967,0x0a0e6e70},{0x27b70a85,0x46d22ffc},{0x2e1b2138,0x5c26c926},{0x4d2c6dfc,0x5ac42aed},
	{0x53380d13,0x9d95b3df},{0x650a7354,0x8baf63de},{0x766a0abb,0x3c77b2a8},{0x81c2c92e,0x47edaee6},{0x92722c85,0x1482353b},
	{0xa2bfe8a1,0x4cf10364},{0xa81a664b,0xbc423001},{0xc24b8b70,0xd0f89791},{0xc76c51a3,0x0654be30},{0xd192e819,0xd6ef5218},
	{0xd6990624,0x5565a910},{0xf40e3585,0x5771202a},{0x106aa070,0x32bbd1b8},{0x19a4c116,0xb8d2d0c8},{0x1e376c08,0x5141ab53},
	{0x2748774c,0xdf8eeb99},{0x34b0bcb5,0xe19b48a8},{0x391c0cb3,0xc5c95a63},{0x4ed8aa4a,0xe3418acb},{0x5b9cca4f,0x7763e373},
	{0x682e6ff3,0xd6b2b8a3},{0x748f82ee,0x5defb2fc},{0x78a5636f,0x43172f60},{0x84c87814,0xa1f0ab72},{0x8cc70208,0x1a6439ec},
	{0x90befffa,0x23631e28},{0xa4506ceb,0xde82bde9},{0xbef9a3f7,0xb2c67915},{0xc67178f2,0xe372532b},{0xca273ece,0xea26619c},
	{0xd186b8c7,0x21c0c207},{0xeada7dd6,0xcde0eb1e},{0xf57d4f7f,0xee6ed178},{0x06f067aa,0x72176fba},{0x0a637dc5,0xa2c898a6},
	{0x113f9804,0xbef90dae},{0x1b710b35,0x131c471b},{0x28db77f5,0x23047d84},{0x32caab7b,0x40c72493},{0x3c9ebe0a,0x15c9bebc},
	{0x431d67c4,0x9c100d4c},{0x4cc5d4be,0xcb3e42b6},{0x597f299c,0xfc657e2a},{0x5fcb6fab,0x3ad6faec},{0x6c44198c,0x4a475817}
}
do
	local bxor=bit64.bxor
	local ror=bit64.ror
	local rshift=bit64.rshift
	local rol=bit64.rol
	local band=bit64.band
	local bnot=bit64.bnot
	local add=bit64.add
	function sha512(txt,nohex)
		local ha={[0]=
			{0x6a09e667,0xf3bcc908},{0xbb67ae85,0x84caa73b},{0x3c6ef372,0xfe94f82b},{0xa54ff53a,0x5f1d36f1},
			{0x510e527f,0xade682d1},{0x9b05688c,0x2b3e6c1f},{0x1f83d9ab,0xfb41bd6b},{0x5be0cd19,0x137e2179}
		}
		local len=#txt
		txt=txt.."\128"..("\0"):rep(132-((len+9)%128))..num2chars64(8*len)
		local w={}
		for chunkind=1,#txt,128 do
			local rawchunk=txt:sub(chunkind,chunkind+127)
			for i=1,128,8 do
				w[math.floor(i/8)]=chars2num64(rawchunk:sub(i))
			end
			for i=16,79 do
				w[i]=add(w[i-16],bxor(ror(w[i-15],1),ror(w[i-15],8),rshift(w[i-15],7)),w[i-7],bxor(ror(w[i-2],19),ror(w[i-2],61),rshift(w[i-2],6)))
			end
			local a,b,c,d,e,f,g,h=ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]
			for i=0,79 do
				local temp1=add(h,bxor(ror(e,14),ror(e,18),ror(e,41)),bxor(band(e,f),band(bnot(e),g)),sha_512k[i],w[i])
				a,b,c,d,e,f,g,h=add(temp1,add(bxor(ror(a,28),ror(a,34),ror(a,39)),bxor(band(a,b),band(a,c),band(b,c)))),a,b,c,add(d,temp1),e,f,g
			end
			ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]=add(ha[0],a),add(ha[1],b),add(ha[2],c),add(ha[3],d),add(ha[4],e),add(ha[5],f),add(ha[6],g),add(ha[7],h)
		end
		local cnv=nohex and num2chars64 or num2hex64
		return
			cnv(ha[0])..cnv(ha[1])..cnv(ha[2])..cnv(ha[3])..
			cnv(ha[4])..cnv(ha[5])..cnv(ha[6])..cnv(ha[7])
	end
end

local crc32dat={
	0x00000000,0x77073096,0xee0e612c,0x990951ba,0x076dc419,0x706af48f,0xe963a535,0x9e6495a3,
	0x0edb8832,0x79dcb8a4,0xe0d5e91e,0x97d2d988,0x09b64c2b,0x7eb17cbd,0xe7b82d07,0x90bf1d91,
	0x1db71064,0x6ab020f2,0xf3b97148,0x84be41de,0x1adad47d,0x6ddde4eb,0xf4d4b551,0x83d385c7,
	0x136c9856,0x646ba8c0,0xfd62f97a,0x8a65c9ec,0x14015c4f,0x63066cd9,0xfa0f3d63,0x8d080df5,
	0x3b6e20c8,0x4c69105e,0xd56041e4,0xa2677172,0x3c03e4d1,0x4b04d447,0xd20d85fd,0xa50ab56b,
	0x35b5a8fa,0x42b2986c,0xdbbbc9d6,0xacbcf940,0x32d86ce3,0x45df5c75,0xdcd60dcf,0xabd13d59,
	0x26d930ac,0x51de003a,0xc8d75180,0xbfd06116,0x21b4f4b5,0x56b3c423,0xcfba9599,0xb8bda50f,
	0x2802b89e,0x5f058808,0xc60cd9b2,0xb10be924,0x2f6f7c87,0x58684c11,0xc1611dab,0xb6662d3d,
	0x76dc4190,0x01db7106,0x98d220bc,0xefd5102a,0x71b18589,0x06b6b51f,0x9fbfe4a5,0xe8b8d433,
	0x7807c9a2,0x0f00f934,0x9609a88e,0xe10e9818,0x7f6a0dbb,0x086d3d2d,0x91646c97,0xe6635c01,
	0x6b6b51f4,0x1c6c6162,0x856530d8,0xf262004e,0x6c0695ed,0x1b01a57b,0x8208f4c1,0xf50fc457,
	0x65b0d9c6,0x12b7e950,0x8bbeb8ea,0xfcb9887c,0x62dd1ddf,0x15da2d49,0x8cd37cf3,0xfbd44c65,
	0x4db26158,0x3ab551ce,0xa3bc0074,0xd4bb30e2,0x4adfa541,0x3dd895d7,0xa4d1c46d,0xd3d6f4fb,
	0x4369e96a,0x346ed9fc,0xad678846,0xda60b8d0,0x44042d73,0x33031de5,0xaa0a4c5f,0xdd0d7cc9,
	0x5005713c,0x270241aa,0xbe0b1010,0xc90c2086,0x5768b525,0x206f85b3,0xb966d409,0xce61e49f,
	0x5edef90e,0x29d9c998,0xb0d09822,0xc7d7a8b4,0x59b33d17,0x2eb40d81,0xb7bd5c3b,0xc0ba6cad,
	0xedb88320,0x9abfb3b6,0x03b6e20c,0x74b1d29a,0xead54739,0x9dd277af,0x04db2615,0x73dc1683,
	0xe3630b12,0x94643b84,0x0d6d6a3e,0x7a6a5aa8,0xe40ecf0b,0x9309ff9d,0x0a00ae27,0x7d079eb1,
	0xf00f9344,0x8708a3d2,0x1e01f268,0x6906c2fe,0xf762575d,0x806567cb,0x196c3671,0x6e6b06e7,
	0xfed41b76,0x89d32be0,0x10da7a5a,0x67dd4acc,0xf9b9df6f,0x8ebeeff9,0x17b7be43,0x60b08ed5,
	0xd6d6a3e8,0xa1d1937e,0x38d8c2c4,0x4fdff252,0xd1bb67f1,0xa6bc5767,0x3fb506dd,0x48b2364b,
	0xd80d2bda,0xaf0a1b4c,0x36034af6,0x41047a60,0xdf60efc3,0xa867df55,0x316e8eef,0x4669be79,
	0xcb61b38c,0xbc66831a,0x256fd2a0,0x5268e236,0xcc0c7795,0xbb0b4703,0x220216b9,0x5505262f,
	0xc5ba3bbe,0xb2bd0b28,0x2bb45a92,0x5cb36a04,0xc2d7ffa7,0xb5d0cf31,0x2cd99e8b,0x5bdeae1d,
	0x9b64c2b0,0xec63f226,0x756aa39c,0x026d930a,0x9c0906a9,0xeb0e363f,0x72076785,0x05005713,
	0x95bf4a82,0xe2b87a14,0x7bb12bae,0x0cb61b38,0x92d28e9b,0xe5d5be0d,0x7cdcefb7,0x0bdbdf21,
	0x86d3d2d4,0xf1d4e242,0x68ddb3f8,0x1fda836e,0x81be16cd,0xf6b9265b,0x6fb077e1,0x18b74777,
	0x88085ae6,0xff0f6a70,0x66063bca,0x11010b5c,0x8f659eff,0xf862ae69,0x616bffd3,0x166ccf45,
	0xa00ae278,0xd70dd2ee,0x4e048354,0x3903b3c2,0xa7672661,0xd06016f7,0x4969474d,0x3e6e77db,
	0xaed16a4a,0xd9d65adc,0x40df0b66,0x37d83bf0,0xa9bcae53,0xdebb9ec5,0x47b2cf7f,0x30b5ffe9,
	0xbdbdf21c,0xcabac28a,0x53b39330,0x24b4a3a6,0xbad03605,0xcdd70693,0x54de5729,0x23d967bf,
	0xb3667a2e,0xc4614ab8,0x5d681b02,0x2a6f2b94,0xb40bbe37,0xc30c8ea1,0x5a05df1b,0x2d02ef8d
}

function crc32(txt)
	local crc=bit.bnot(0)
	for l1=1,#txt do
		crc=bit.bxor(bit.rshift(crc,8),crc32dat[bit.bxor(bit.band(crc,0xFF),txt:byte(l1,l1))+1])
	end
	return bit.bnot(crc)
end

function javahash(str)
	local hash=0
	for i=1,#str do
		hash=hash+(str:byte(i)*31^(#str-i))
	end
	return hash
end

function strdist(s,t)
	local m=#s
	local n=#t
	local d={}
	for x=0,m do
		d[x]={}
		for y=0,n do
			d[x][y]=0
		end
	end
	for i=1,m do
		d[i][0]=i
    end
	for j=1,n do
		d[0][j]=j
	end
	for j=1,n do
		for i=1,m do
			if s:sub(i,i)==t:sub(j,j) then
				d[i][j]=d[i-1][j-1]
			else
				d[i][j]=math.min(
					d[i-1][j]+1,
					d[i][j-1]+1,
					d[i-1][j-1]+1
				)
			end
		end
	end
	return d[m][n]
end

function dstword(txt)
	local mp={}
	local c=97
	txt=txt:gsub(".",function(ch)
		if not mp[ch] then
			mp[ch]=string.char(c)
			c=c+1
		end
		return mp[ch]
	end):gsub("^abc?d?e?f?g?h?i?j?k?l?m?n?o?p?q?r?s?t?u?v?w?x?y?z?",function(t)
		return tostring(#t)
	end)
	return txt
end

dstdb=sql.new("dstdb").new("wordlist","word","encoded")

--[[local file=io.open("/home/nadine/Downloads/derp/Two_Word_Full.txt")
for line in file:lines() do
	line=line:gsub("%A","")
	if line==line:lower() then
		dstdb.insert({word=line,encoded=dstword(line)})
	end
end]]

local bxor=bit64.bxor
local ror=bit64.ror
local rshift=bit64.rshift
local rol=bit64.rol
local band=bit64.band
local bnot=bit64.bnot
local add=bit64.add

function watcrypt(key,dec)
	local ha={[0]=
		{0x6a09e667,0xf3bcc908},{0xbb67ae85,0x84caa73b},{0x3c6ef372,0xfe94f82b},{0xa54ff53a,0x5f1d36f1},
		{0x510e527f,0xade682d1},{0x9b05688c,0x2b3e6c1f},{0x1f83d9ab,0xfb41bd6b},{0x5be0cd19,0x137e2179}
	}
	local function cpt(txt)
		txt=txt..("\0"):rep(128-#txt)
		local w={}
		for i=1,128,8 do
			w[math.floor(i/8)]=chars2num64(txt:sub(i))
		end
		for i=16,79 do
			w[i]=add(w[i-16],bxor(ror(w[i-15],1),ror(w[i-15],8),rshift(w[i-15],7)),w[i-7],bxor(ror(w[i-2],19),ror(w[i-2],61),rshift(w[i-2],6)))
		end
		local a,b,c,d,e,f,g,h=ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]
		for i=0,79 do
			local temp1=add(h,bxor(ror(e,14),ror(e,18),ror(e,41)),bxor(band(e,f),band(bnot(e),g)),sha_512k[i],w[i])
			a,b,c,d,e,f,g,h=add(temp1,add(bxor(ror(a,28),ror(a,34),ror(a,39)),bxor(band(a,b),band(a,c),band(b,c)))),a,b,c,add(d,temp1),e,f,g
		end
		ha[0],ha[1],ha[2],ha[3],ha[4],ha[5],ha[6],ha[7]=add(ha[0],a),add(ha[1],b),add(ha[2],c),add(ha[3],d),add(ha[4],e),add(ha[5],f),add(ha[6],g),add(ha[7],h)
	end
	cpt(key)
	return function(txt)
		local out=""
		for l1=1,#txt,128 do
			local chunk=txt:sub(l1,l1+127)
			chunk=chunk..("\0"):rep(128-#chunk)
			local data=crypt.xor(chunk,
				num2chars64(ha[0])..num2chars64(ha[1])..num2chars64(ha[2])..num2chars64(ha[3])..
				num2chars64(ha[4])..num2chars64(ha[5])..num2chars64(ha[6])..num2chars64(ha[7])
			)
			out=out..data
			cpt(dec and data or chunk)
		end
		return out
	end
end
