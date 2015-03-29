ffi.cdef[[
void* memcpy(void*,void*,int);
]]
local dupper=(2^15)-1
local dlower=-2^15
local hz=48000

synth={}

local function alloc(len)
	return ffi.new("short[?]",len)
end

local function lim(n)
	return math.max(dlower,math.min(dupper,n))
end

local new

local function alu(opa,opb,a,b)
	local len
	local o
	if type(b)=="number" then
		len=a.len
		o=alloc(len)
		setfenv(loadstring([[
			local o,len,ad,bd=...
			for l1=0,len-1 do
				o[l1]=lim(]]..opa..[[)
			end
		]]),{lim=lim,dupper=dupper,math=math})(o,len,a.data,b)
	else
		len=math.max(a.len,b.len)
		o=alloc(len)
		local s=math.min(a.len,b.len)
		setfenv(loadstring([[
			local o,len,ad,bd=...
			for l1=0,len-1 do
				o[l1]=lim(]]..opb..[[)
			end
		]]),{lim=lim,dupper=dupper,math=math})(o,s,a.data,b.data)
		--[[if a.len~=b.len then
			if a.len>b.len then
				for l1=s,len-1 do
					o[l1]=a.data[l1]
				end
			else
				for l1=s,len-1 do
					o[l1]=b.data[l1]
				end
			end
		end]]
	end
	return new(len,o)
end

local mt={
	__add=function(a,b)
		return alu("ad[l1]+(bd*dupper)","ad[l1]+bd[l1]",a,b)
	end,
	__sub=function(a,b)
		return alu("ad[l1]-(bd*dupper)","ad[l1]-bd[l1]",a,b)
	end,
	__mul=function(a,b)
		return alu("ad[l1]*bd","ad[l1]*(bd[l1]/dupper)",a,b)
	end,
	__div=function(a,b)
		return alu("ad[l1]/bd","ad[l1]/(bd[l1]/dupper)",a,b)
	end,
	__mod=function(a,b)
		return alu("ad[l1]%(bd*dupper)","ad[l1]%bd[l1]",a,b)
	end,
	__unm=function(a)
		local len=a.len
		local o=new(len)
		local d=a.data
		for l1=0,len-1 do
			o[l1]=lim(-d[l1])
		end
		return o
	end,
	__concat=function(a,b)
		local len=a.len+b.len
		local o=new(len)
		C.memcpy(o.data,a.data,a.len*2)
		C.memcpy(o.data+a.len,b.data,b.len*2)
		for l1=0,(a.len-1) do
			assert(o[l1]==a[l1])
		end
		for l1=0,(b.len-1) do
			assert(o[l1+a.len]==b[l1])
		end
		return o
	end,
}

function new(len,data)
	if not data then
		data=alloc(len)
	end
	return setmetatable({
		data=data,
		len=len,
	},mt)
end

function synth.rep(t,n)
	local len=math.floor(t.len*n)
	local o=alloc(len)
	for l1=1,n do
		ffi.C.memcpy(o+((l1-1)*t.len),t.data,t.len*2)
	end
	return new(len,o)
end

local freq=200
local volume=10
local length=1

function synth.noise(n,f)
	f=f or hz
	local len=n*hz
	local o=alloc(len)
	local c
	local s
	local cc=0
	for l1=1,len-1 do
		cc=cc+1
		if cc>=hz/f or not s then
			s=math.random(dlower,dupper)
			cc=0
		end
		o[l1]=s
	end
	return new(len,o)
end

function synth.squareNoise(n,f)
	f=f or hz
	local len=n*hz
	local o=alloc(len)
	local c
	local s
	local cc=0
	for l1=1,len-1 do
		cc=cc+1
		if cc>=hz/f or not s then
			s=math.random(0,1)*dupper
			cc=0
		end
		o[l1]=s
	end
	return new(len,o)
end

function synth.space(n,nm)
	local len=n*hz
	local o=alloc(len)
	for l1=0,len-1 do
		o[l1]=nm or 0
	end
	return new(len,o)
end

function synth.square(t)
	t=t or {}
	t.freq=t.freq or freq
	t.efreq=t.efreq or t.freq
	t.volume=(t.volume or volume)/100
	t.length=(t.length or length)*hz
	local o=alloc(t.length)
	local s=false
	local cc=0
	if t.freq==t.efreq then
		for l1=0,t.length-1 do
			cc=cc+1
			if cc>=(hz*2)/t.freq then
				s=not s
				cc=0
			end
			o[l1]=lim((s and dupper or dlower)*t.volume)
		end
	else
		for l1=0,t.length-1 do
			cc=cc+1
			if cc>=((t.freq+((l1/(t.length-1))*(t.efreq-t.freq)))*2)/t.freq then
				s=not s
				cc=0
			end
			o[l1]=lim((s and dupper or dlower)*t.volume)
		end
	end
	return new(t.length,o)
end

function synth.sine(t)
	t=t or {}
	t.freq=t.freq or freq
	t.efreq=t.efreq or t.freq
	t.volume=(t.volume or volume)/100
	t.length=(t.length or length)*hz
	local o=alloc(t.length)
	if t.freq==t.efreq then
		for l1=0,t.length-1 do
			o[l1]=lim(dupper*t.volume*math.sin((l1*(t.freq/hz))*math.pi))
		end
	else
		for l1=0,t.length-1 do
			o[l1]=lim(dupper*t.volume*math.sin((l1*(((t.freq+((l1/(t.length-1))*(t.efreq-t.freq))))/hz))*math.pi))
		end
	end
	return new(t.length,o)
end

function synth.sawtooth(t)
	t=t or {}
	t.freq=t.freq or freq
	t.efreq=t.efreq or t.freq
	t.volume=(t.volume or volume)/100
	t.length=(t.length or length)*hz
	local o=alloc(t.length)
	if t.freq==t.efreq then
		for l1=0,t.length-1 do
			o[l1]=lim(dupper*t.volume*((((l1*((t.freq*2)/hz))%2)-1)-0.5))
		end
	else
		for l1=0,t.length-1 do
			o[l1]=lim(dupper*t.volume*((((l1*(((t.freq+((l1/(t.length-1))*(t.efreq-t.freq)))*2)/hz))%2)-1)-0.5))
		end
	end
	return new(t.length,o)
end

function synth.triangle(t)
	t=t or {}
	t.freq=t.freq or freq
	t.efreq=t.efreq or t.freq
	t.volume=(t.volume or volume)/100
	t.length=(t.length or length)*hz
	local o=alloc(t.length)
	if t.freq==t.efreq then
		for l1=0,t.length-1 do
			o[l1]=lim(dupper*t.volume*(math.abs(((l1*((t.freq*2)/hz))%2)-1)-0.5))
		end
	else
		for l1=0,t.length-1 do
			o[l1]=lim(dupper*t.volume*(math.abs(((l1*(((t.freq+((l1/(t.length-1))*(t.efreq-t.freq)))*2)/hz))%2)-1)-0.5))
		end
	end
	return new(t.length,o)
end

function synth.fadeIn(t,start)
	local len=t.len
	start=(start or (len/hz))*hz
	local o=alloc(len)
	for l1=1,len-1 do
		o[l1]=t.data[l1]/math.max(start/(l1+1),1)
	end
	return new(len,o)
end

function synth.fadeOut(t,start)
	local len=t.len
	start=(start or (len/hz))*hz
	local o=alloc(len)
	for l1=0,len-1 do
		o[l1]=t.data[l1]*(1-(l1+1)/start)
	end
	return new(len,o)
end

function synth.min(a,b)
	return alu(nil,a,b,"math.min(ad[l1],bd[l1])")
end

function synth.max(a,b)
	return alu(nil,a,b,"math.max(ad[l1],bd[l1])")
end

function synth.smooth(t,r)
	local len=t.len
	local o=alloc(len)
	local d=t.data
	r=1/(r/hz)
	o[0]=d[0]
	for l1=1,len-1 do
		o[l1]=(d[l1]*(1-r))+(o[l1-1]*r)
	end
	return new(len,o)
end

function synth.paste(out)
	local o=""
	for l1=1,5 do
		o=o..string.char((math.random(0x41,0x59)+(math.random(0,1)*0x20)))
	end
	local f=io.open("synthout","w")
	local function a(n)
		assert(n>=0,n)
		assert(n<=255,n)
		return n
	end
	for l1=0,out.len-1 do
		local n=out.data[l1]-dlower
		f:write(string.char(a(math.floor(n/256)),a(n%256)))
	end
	f:close()
	os.execute("avconv -ar "..hz.." -f u16be -i synthout www/synth/"..o..".mp3")
	--os.execute("ffmpeg\\bin\\ffplay -i out -ar "..hz.." -f u8")
	return "http://68.36.225.16/synth/"..o..".mp3"
end
