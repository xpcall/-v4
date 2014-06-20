local function round(num)
	return math.floor(num+0.5)
end

local function c24to8(num)
	return round(bit.rshift(num,16)*7/255)*32+round((bit.rshift(num,8)%256)*7/255)*4+round((num%256)*3/255)
end

local function c8to24(c)
	return round(math.floor(c/32)*255/7)*65536+round((math.floor(c/4)%8)*255/7)*256+round((c%4)*255/3)
end

local function encode(data,mode,omode,meta)
	mode=mode or "xy24"
	omode=omode or "oci"
	local inp={}
	local wd
	local hi
	if mode=="oci" then
		if data:sub(1,3)~="OCI" then
			error("invalid OCI data")
		end
		data=data:sub(4)
		local version=data:byte(1,1)
		local meta,width,data=data:match("^.(.-)%z(.)(.+)")
		width=width:byte()
		wd=width
		hi=0
		local x=1
		local y=1
		for l1=1,#data,3 do
			local c=c8to24(data:byte(l1))
			local w=data:byte(l1+1)
			local h=data:byte(l1+2)
			hi=math.max(hi,(h+y)-1)
			-- fill space
			for cy=y,(h+y)-1 do
				inp[cy]=inp[cy] or {}
				for cx=x,(w+x)-1 do
					inp[cy][cx]=c
				end
			end
			-- find next pixel
			if x+w>width then
				x=1
				y=h+y
			else
				x=x+w
			end
		end
	elseif mode=="xy24" then
		wd=#data
		hi=#(data[1] or {})
		for x=1,#data do
			local c=data[x]
			hi=#c
			for y=1,#c do
				inp[y]=inp[y] or {}
				inp[y][x]=data[x][y]
			end
		end
	elseif mode=="yx24" then
		wd=#(data[1] or {})
		hi=#data
		inp=data
	elseif mode=="xy8" then
		wd=#data
		hi=#(data[1] or {})
		for x=1,#data do
			local c=data[x]
			for y=1,#c do
				inp[y]=inp[y] or {}
				inp[y][x]=c8to24(c[y])
			end
		end
	elseif mode=="yx8" then
		wd=#(data[1] or {})
		hi=#data
		for y=1,#data do
			inp[y]={}
			local c=data[y]
			for x=1,#c do
				inp[y][x]=c8to24(c[x])
			end
		end
	elseif tonumber(mode) then
		local w=tonumber(mode)
		if #data%w~=0 then
			error("invalid data")
		end
		for l1=1,#data do
			local x=((l1-1)%w)+1
			local y=math.floor(l1/w)+1
			inp[y]=inp[y] or {}
			inp[y][x]=c8to24(data:byte(l1,l1))
		end
	else
		error("no such mode: "..tostring(mode))
	end
	local out
	local version=0
	if omode=="oci" then
		-- this can be slow on large images
		local ot={}
		local ud=setmetatable({},{__index=function(s,n)
			local o={}
			s[n]=o
			return o
		end})
		-- generate
		for y=1,hi do
			ot[y]={}
			local c=inp[y]
			for x=1,wd do
				local cc=c[x]
				if not ud[y][x] then
					local mx=y+x
					local ct={y,x}
					local pmn=wd
					for cy=y,hi do
						if inp[cy][x]~=cc then
							break
						end
						local m=x
						for cx=x,pmn do
							if inp[cy][cx]~=cc then
								break
							end
							m=cx
						end
						pmn=math.min(pmn,m)
						if m+cy>mx then
							ct={cy,m}
						end
					end
					for sy=y,ct[1] do
						for sx=x,ct[2] do
							ud[sy][sx]=true
						end
					end
					ot[y][x]=ct
				end
			end
		end
		out="OCI"..string.char(version).."\0"..string.char(wd)
		for y=1,hi do
			local c=ot[y]
			for x=1,wd do
				local cc=c[x]
				if cc then
					out=out..string.char(c24to8(inp[y][x]))..string.char((cc[2]-x)+1)..string.char((cc[1]-y)+1)
				end
			end
		end
	elseif omode=="xy24" then
		out={}
		for x=1,wd do
			out[x]={}
			for y=1,hi do
				out[x][y]=inp[y][x]
			end
		end
	elseif omode=="yx24" then
		out=inp
	elseif omode=="xy8" then
		out={}
		for x=1,wd do
			out[x]={}
			for y=1,hi do
				out[x][y]=c24to8(inp[y][x])
			end
		end
	elseif omode=="yx8" then
		out={}
		for y=1,hi do
			out[y]={}
			for x=1,wd do
				out[y][x]=c24to8(inp[y][x])
			end
		end
	elseif omode=="str" then
		out=""
		for y=1,hi do
			for x=1,wd do
				out=out..string.char(c24to8(inp[y][x]))
			end
		end
	end
	return out,wd,hi
end

function encimg(fn)
	local dat={}
	local image=img.load(fn)
	local ht=image.height()
	image.shader(function(x,y,r,g,b)
		y=ht-y
		dat[y]=dat[y] or {}
		dat[y][x]=img.combine(r,g,b)
		return r,g,b
	end)
	local out=encode(dat,"yx24")
	local file=io.open("www/out.oci","w")
	file:write(out)
	file:close()
end
