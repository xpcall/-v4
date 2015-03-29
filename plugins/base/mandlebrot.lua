function mandlebrot()
	local im=img.new(1000,1000)
	local pallete=ffi.new("unsigned char [256][3]")
	local depth=255
	for l1=0,depth-1 do
		pallete[l1][0]=math.min(math.max(math.floor(l1/depth*1024),0),255)
		pallete[l1][1]=math.min(math.max(math.floor((l1-depth/3)/depth*1024),0),255)
		pallete[l1][2]=math.min(math.max(math.floor((l1-depth/3*2)/depth*1024),0),255)
	end
	pallete[depth][0]=0
	pallete[depth][1]=0
	pallete[depth][2]=0
	local gpu=opencl.initGpu()
	local bfp=opencl.newBuffer(gpu,pallete)
	local data=ffi.new("unsigned char[1000][1000][3]")
	local bfd=opencl.newBuffer(gpu,data)
	local code=opencl.compile(gpu,file["plugins/base/mandlebrot.cl"])
	code.threads=255
	opencl.exec(code,bfd,bfp)
	out=bfd:read()
	for x=0,1000-1 do
		for y=0,1000-1 do
			im.image[0][y][x]=out[x][y][0]
			im.image[1][y][x]=out[x][y][1]
			im.image[2][y][x]=out[x][y][2]
		end
	end
	return im.paste()
end