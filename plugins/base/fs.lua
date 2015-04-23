local attr={}
local function getAttr(file,force)
	--if attr[file]==nil or socket.gettime()>=(attr[file] or {blife=0}).blife then
		attr[file]=lfs.attributes(file) or false
		local dat=attr[file]
		if dat then
			dat.blife=socket.gettime()+5
			if dat.mode=="directory" then
				dat.list={}
				for fn in lfs.dir(file) do
					if fn~="." and fn~=".." then
						table.insert(dat.list,fn)
					end
				end
			end
		end
	--end
	return attr[file]
end
local filedata={}
local function getFile(file)
	local attr=getAttr(file)
	if not attr then
		filedata[file]=nil
		return nil
	end
	for k,v in tpairs(filedata) do
		if v[3]>=socket.gettime() then
			filedata[k]=nil
		end
	end
	if not filedata[file] or filedata[file][2]~=attr.modified then
		local fl=assert(io.open(file,"r"))
		filedata[file]={fl:read("*a"),attr.modified}
		fl:close()
	end
	filedata[file][3]=socket.gettime()+5
	return filedata[file][1]
end
fs={
	exists=function(file)
		return getAttr(file) and true
	end,
	isDir=function(file)
		local attr=getAttr(file)
		return attr and attr.mode=="directory"
	end,
	isFile=function(file)
		local attr=getAttr(file)
		return attr and attr.mode=="file"
	end,
	list=function(file)
		local attr=getAttr(file)
		return attr and attr.list
	end,
	split=function(file)
		local t={}
		for dir in file:gmatch("[^/]+") do
			t[#t+1]=dir
		end
		return t
	end,
	modified=function(file)
		local attr=getAttr(file)
		return attr and attr.modification
	end,
	size=function(file)
		local attr=getAttr(file)
		return attr and attr.size
	end,
	combine=function(filea,fileb)
		local o={}
		for k,v in pairs(fs.split(filea)) do
			table.insert(o,v)
		end
		for k,v in pairs(fs.split(fileb)) do
			table.insert(o,v)
		end
		return filea:match("^/?")..table.concat(o,"/")..fileb:match("/?$")
	end,
	resolve=function(file)
		local t=fs.split(file)
		local s=0
		for l1=#t,1,-1 do
			local c=t[l1]
			if c=="." then
				table.remove(t,l1)
			elseif c==".." then
				table.remove(t,l1)
				s=s+1
			elseif s>0 then
				table.remove(t,l1)
				s=s-1
			end
		end
		return table.concat(t,"/")
	end,
	pop=function(file,n)
		return fs.resolve(("../"):rep(n or 1)..file)
	end,
	read=function(file)
		return getFile(file)
	end,
	makeDir=function(dir)
		getAttr(dir,true)
		getAttr(fs.pop(dir),true)
		assert(lfs.mkdir(dir))
	end,
	write=function(file,txt)
		getAttr(file,true)
		getAttr(fs.pop(file),true)
		local h=assert(io.open(file,"w"))
		h:write(txt)
		h:close()
		return true
	end,
	move=function(file,tofile)
		local fl=assert(io.open(file,"rb"))
		local tofl=assert(io.open(tofile,"wb"))
		getAttr(file,true)
		getAttr(fs.pop(file),true)
		getAttr(tofile,true)
		getAttr(fs.pop(tofile),true)
		tofl:write(fl:read("*a"))
		fl:close()
		tofl:close()
		fs.delete(file)
	end,
	delete=function(file)
		if not fs.exists(file) then
			return
		end
		if fs.isDir(file) then
			for k,v in pairs(fs.list(file)) do
				fs.delete(fs.combine(file,v))
			end
		end
		assert(os.remove(file))
	end,
	recurse=function(file,func)
		if fs.isDir(file) then
			for k,v in pairs(fs.list(file)) do
				fs.recurse(fs.combine(file,v),func)
			end
		end
		func(file)
	end,
}