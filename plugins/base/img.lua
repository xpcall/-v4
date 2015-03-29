img={}
local function tocolor(val)
	if type(val)=="number" then
		return cd.EncodeColor(val/65536,(val/256)%256,val%256)
	elseif type(val)=="table" then
		local c=cd.EncodeColor(unpack(val))
		if val[4] then
			c=cd.EncodeAlpha(c,val[4]) 
		end
		return c
	end
	return val
end
function img.new(w,h)
	local image
	if not h then
		image=w
	else
		image=im.ImageCreate(w,h,im.RGB,im.BYTE)
	end
	local canvas=image:cdCreateCanvas()
	--canvas:InvertYAxis(0)
	canvas:Origin(1,1)
	local out
	out={
		image=image,
		canvas=canvas,
		width=function()
			return image:Width()
		end,
		height=function()
			return image:Height()
		end,
		shader=function(func)
			local w,h=image:Width(),image:Height()
			for y=0,h-1 do
				for x=0,w-1 do
					local c={func(x,y,image[0][y][x],image[1][y][x],image[2][y][x])}
					if c[1] and c[2] and c[3] then
						image[0][y][x]=math.floor(c[1]%256)
						image[1][y][x]=math.floor(c[2]%256)
						image[2][y][x]=math.floor(c[3]%256)
					end
				end
			end
		end,
		text=function(x,y,txt,font,size,sstyle,color)
			font=font or "Times"
			sstyle=sstyle or "plain"
			local style=0
			for word in sstyle:gmatch("%S+") do
				style=bit.bor(style,cd[word:upper()])
			end
			color=tocolor(color or 0)
			size=size or 12
			canvas:Foreground(color)
			canvas:Font(font,style,size)
			canvas:Text(x,y,txt)
		end,
		clear=function(color)
			canvas:Background(tocolor(color or 0xFFFFFF))
			canvas:Clear()
		end,
		save=function(name,format)
			image:Save(name or out.name,(format or out.format or (name or out.name):match("^.*%.(.*)")):upper())
		end,
		line=function(x1,y1,x2,y2,color)
			canvas:Foreground(tocolor(color or 0xFFFFFF))
			canvas:Line(x1,y1,x2,y2)
		end,
		paste=function()
			local o=""
			for l1=1,5 do
				o=o..string.char((math.random(0x41,0x59)+(math.random(0,1)*0x20)))
			end
			out.save("www/img/"..o..".png")
			return "http://ptoast.tk/img/"..o..".png"
		end,
	}
	return out
end

function img.load(name)
	local out=img.new(im.FileImageLoad(name))
	out.name=name
	out.format=name:match("^.*%.(.*)")
	return out
end

function img.combine(r,g,b)
	return (((math.floor(r%256)*256)+math.floor(g%256))*256)+math.floor(b%256)
end

function img.explode(c)
	return math.floor(c/65536)%256,math.floor(c/256)%256,math.floor(c)%256
end

--[[hook.new("command_encodeimg",function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	local imgin=im.FileImageLoad("www/kitty.png")
	local imgout=im.ImageCreate(imgin:Width(),imgin:Height(),im.RGB,im.BYTE)
	txt=hook.queue("command_encbf",nil,nil,txt).."+-"
	for y=0,imgin:Height()-1 do
		for x=0,imgin:Width()-1 do
			local dat={
				imgin[0][y][x],
				imgin[1][y][x],
				imgin[2][y][x],
			}
			if txt~="" then
				local c=({
					["+"]={0,0,0},
					["-"]={0,0,1},
					[">"]={0,1,0},
					["<"]={0,1,1},
					["."]={1,0,0},
					[","]={1,0,1},
					["["]={1,1,0},
					["]"]={1,1,1},
				})[txt:sub(1,1)]
				imgout[0][y][x]=(math.floor(dat[1]/2)*2)+c[1]
				imgout[1][y][x]=(math.floor(dat[2]/2)*2)+c[2]
				imgout[2][y][x]=(math.floor(dat[3]/2)*2)+c[3]
				txt=txt:sub(2)
			else
				imgout[0][y][x]=dat[1]
				imgout[1][y][x]=dat[2]
				imgout[2][y][x]=dat[3]
			end
		end
	end
	local n=math.random(10000,99999)
	imgout:Save("www/paste/"..n..".png","PNG")
	return "http://71.238.153.166/paste/"..n..".png"
end)
hook.new("command_decodeimg",function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	local imgin=im.FileImageLoad("www/paste/"..txt)
	local cnv={[0]={[0]={[0]="+","-"},{[0]=">","<"}},{[0]={[0]=".",","},{[0]="[","]"}}}
	local o=""
	for y=0,imgin:Height()-1 do
		for x=0,imgin:Width()-1 do
			o=o..cnv[imgin[0][y][x]%2][imgin[1][y][x]%2][imgin[2][y][x]%2]
			if o:match("%+%-$") then
				break
			end
		end
		if o:match("%+%-$") then
			break
		end
	end
	return brainfuck(o)()
end)]]
