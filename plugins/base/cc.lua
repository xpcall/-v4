cc={}

cc.defaultincludes={
	"/usr/local/include",
	"./include",
}

cc.defaultlibs={
	"/usr/local/lib",
	"./lib",
}

cc.defaultlinks={
	"luajit",
	"m",
	"dl",
}

function cc.compile(file,prefs)
	print("[cc] building "..file)
	prefs=prefs or {}
	
	prefs.include=prefs.include or {}
	for k,v in pairs(cc.defaultincludes) do
		prefs.include[v]=prefs.include[v] or prefs.include[v]==nil
	end
	
	prefs.link=prefs.link or {}
	for k,v in pairs(cc.defaultlinks) do
		prefs.link[v]=prefs.link[v] or prefs.link[v]==nil
	end
	
	prefs.lib=prefs.lib or {}
	for k,v in pairs(cc.defaultlibs) do
		prefs.lib[v]=prefs.lib[v] or prefs.lib[v]==nil
	end
	
	if not prefs.ofile then
		prefs.ofile=file:gsub("%.c$",".so")
	end	
	local oc="clang "..file.." -o "..prefs.ofile.." -shared -Wall -Werror -fPIC "
	
	for k,v in pairs(prefs.include) do
		if v then
			oc=oc.."-I"..k.." "
		end
	end
	
	for k,v in pairs(prefs.lib) do
		if v then
			oc=oc.."-L"..k.." "
		end
	end
	
	for k,v in pairs(prefs.link) do
		if v then
			oc=oc.."-l"..k.." "
		end
	end
	
	oc=oc.."2>&1"
	
	local fl=assert(io.popen(oc,"r"))
	local o=assert(fl:read("*a"))
	assert(o=="",oc.."\n"..o)
end

function cc.load(file,prefs)
	prefs=prefs or {}
	cc.compile(file,prefs)
	return ffi.load(prefs.ofile)
end
