socket=require("socket")

local espersv=assert(socket.connect("localhost",1337))
local freesv=socket.connect("localhost",1335)

https=require("ssl.https")
http=require("socket.http")
lfs=require("lfs")
bit=require("bit")
bc=require("bc")
json=require("dkjson")
sqlite=require("lsqlite3")
im=require("imlua")
cd=require("cdlua")
crypto=require("crypto")
posix=require("posix")
lpeg=require("lpeg")
re=require("re")
ffi=require("ffi")
C=ffi.C
require("cdluaim")
math.randomseed(socket.gettime()*1000)

dofile("db.lua")
dofile("hook.lua")
dofile("plugins/async.lua")

local function loaddir(dir,env)
	if env and not env.hook then
		setmetatable(env,{__index=_G})
		env._G=env
		env.r_G=_G
		env.async=false
		setfenv(loadfile("hook.lua"),env)()
		function env.loadstring(txt,bn)
			local func,err=loadstring(txt,bn)
			if not func then
				return func,err
			end
			return setfenv(func,env)
		end
		env.hook.sel=hook.sel
		env.hook.rsel=hook.rsel
		env.hook.newsocket=hook.newsocket
		env.hook.remsocket=hook.remsocket
		env.hook.newrsocket=hook.newrsocket
		env.hook.remrsocket=hook.remrsocket
	elseif not env then
		env=_G
	end
	local loaded={}
	env.reqplugin=function(fn)
		if not loaded[fn] then
			setfenv(assert(loadfile("plugins/"..fn)),env)()
		end
		loaded[fn]=true
	end
	for fn in lfs.dir("plugins/"..dir) do
		if fn:sub(-4,-1)==".lua" then
			env.reqplugin(dir.."/"..fn)
		end
	end
	return env
end

loaddir("base")
networks={
	esper=loaddir("",{cnick="^v",owneracc="ping",sv=espersv,network="esper",cmdprefix="."}),
	freenode=loaddir("",{cnick="^0",owneracc="^v",sv=freesv,network="freenode",cmdprefix="^"}),
}

for k,v in pairs(networks) do
	hook.newsocket(v.sv)
	loaddir(k,v)
	v.hook.queue("init")
	v.send("WHOIS "..v.cnick)
end

local _,err=xpcall(function()
	while true do
		local tme=5
		for netname,net in pairs(networks) do
			net.svbuffer=net.svbuffer or ""
			local s,e,r=net.sv:receive("*a")
			if e=="timeout" then
				net.svbuffer=net.svbuffer..r
				while net.svbuffer:match("[\r\n]") do
					net.hook.queue("raw",net.svbuffer:match("^[^\r\n]+") or "")
					net.svbuffer=net.svbuffer:gsub("^[^\r\n]*[\r\n]+","")
				end
			else
				if e=="closed" then
					error(e)
				end
			end
			tme=math.min(tme,net.hook.interval or 5)
		end
		if networks.esper.exit or networks.freenode.exit then
			break
		end
		local sel={socket.select(hook.sel,hook.rsel,tme)}
		hook.queue("select",unpack(sel))
		for netname,net in pairs(networks) do
			net.hook.queue("select",unpack(sel))
		end
	end
end,debug.traceback)
--sql.cleanup()
if err then
	error(err,0)
end
networks.esper.send("PRIVMSG #V :restarting")