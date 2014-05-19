local socket=require("socket")
local sv=socket.connect("localhost",1337)
local https=require("ssl.https")
local http=require("socket.http")
local lfs=require("lfs")
local bit=require("bit")
local bc=require("bc")
local lanes=require("lanes")
local json=require("dkjson")
local sqlite=require("lsqlite3")
math.randomseed(socket.gettime())
cnick="^v"
do
	local exists={}
	local isdir={}
	local isfile={}
	local list={}
	local rd={}
	local last={}
	local modified={}
	local function update(tbl,ind)
		local tme=socket.gettime()
		local dt=tme-(last[tbl] or tme)
		last[tbl]=tme
		for k,v in tpairs(tbl) do
			v.time=v.time-dt
			if v.time<=0 then
				tbl[k]=nil
			end
		end
		return (tbl[ind] or {}).value
	end
	local function set(tbl,ind,val)
		tbl[ind]={time=10,value=val}
		return val
	end
	fs={
		exists=function(file)
			return lfs.attributes(file)~=nil
		end,
		isDir=function(file)
			local res=update(isdir,file)
			if res~=nil then
				return res
			end
			local dat=lfs.attributes(file)
			if not dat then
				return nil
			end
			return set(isdir,file,dat.mode=="directory")
		end,
		isFile=function(file)
			local res=update(isfile,file)
			if res~=nil then
				return res
			end
			local dat=lfs.attributes(file)
			if not dat then
				return nil
			end
			return set(isfile,file,dat.mode=="file")
		end,
		split=function(file)
			local t={}
			for dir in file:gmatch("[^/]+") do
				t[#t+1]=dir
			end
			return t
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
			local b,e=file:match("^(/?).-(/?)$")
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
			return b..table.concat(t,"/")..e
		end,
		list=function(dir)
			local res=update(list,dir)
			if res~=nil then
				return res
			end
			dir=dir or ""
			local o={}
			for fn in lfs.dir(dir) do
				if fn~="." and fn~=".." then
					table.insert(o,fn)
				end
			end
			return set(list,dir,o)
		end,
		read=function(file)
			local res=update(rd,file)
			if res~=nil then
				return res
			end
			local data=io.open(file,"rb"):read("*a")
			if (rd[file] or {}).data~=data then
				modified[file]=os.date()
			end
			return set(rd,file,data)
		end,
		modified=function(file)
			local res=modified[file]
			if not res then
				fs.read(file)
			end
			return modified[file]
		end,
		delete=function(file)
			os.remove(file)
		end,
		move=function(file,tofile)
			local fl=io.open(file,"rb")
			local tofl=io.open(file,"wb")
			tofl:write(fl:read("*a"))
			fl:close()
			tofl:close()
			os.remove(file)
		end,
	}
end

function timestamp()
	local date=os.date("!*t")
	return date.month.."/"..date.day.." "..date.hour..":"..("0"):rep(2-#tostring(date.min))..date.min
end
function tpairs(tbl)
	local s={}
	local c=1
	for k,v in pairs(tbl) do
		s[c]=k
		c=c+1
	end
	c=0
	return function()
		c=c+1
		return s[c],tbl[s[c]]
	end
end
function table.mean(...)
	local p={...}
	local n=0
	for l1=1,#p do
		n=n+p[l1]
	end
	return n/#p
end
function string.tmatch(str,...)
	local o={}
	for r in str:gmatch(...) do
		table.insert(o,r)
	end
	return o
end
getmetatable("").tmatch=string.tmatch
file=setmetatable({},{
	__index=function(s,n)
		local file=io.open(n,"r")
		return file and file:read("*a")
	end,
	__newindex=function(s,n,d)
		if not d then
			lfs.delete(n)
		else
			local file=io.open(n,"w")
			file:write(d)
			file:close()
		end
	end,
})
function math.round(num,idp)
	local mult=10^(idp or 0)
	return math.floor(num*mult+0.5)/mult
end
function table.reverse(tbl)
    local size=#tbl
    local o={}
    for k,v in ipairs(tbl) do
		o[size-k]=v
    end
	for k,v in pairs(o) do
		tbl[k+1]=v
	end
	return tbl
end
function pescape(txt)
	local o=txt:gsub("[%.%[%]%(%)%%%*%+%-%?%^%$]","%%%1"):gsub("%z","%%z")
	return o
end
local function send(txt)
	sv:send(txt.."\n")
end
local function respond(user,txt)
	if not txt:match("^\1.+\1$") then
		txt=txt:gsub("\1","")
	end
	send(
		(user.chan==cnick and "NOTICE " or "PRIVMSG ")..
		(user.chan==cnick and user.nick or user.chan)..
		" :"..txt
		:gsub("^[\r\n]+",""):gsub("[\r\n]+$",""):gsub("[\r\n]+"," | ")
		:gsub("[%z\2\4\5\6\7\8\9\10\11\12\13\14\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]","")
		:sub(1,446)
	)
end
dofile("hook.lua")
dofile("db.lua")

hook.new("raw",function(txt)
	txt:gsub("^:"..cnick.." MODE "..cnick.." :%+i",function()
		send("JOIN #oc")
		send("JOIN #ocbots")
		send("JOIN #OpenPrograms")
	end)
	txt:gsub("^PING (.+)",function(pong)
		sv:send("PONG "..pong.."\n")
	end)
end)
local plenv=setmetatable({
	socket=socket,
	sv=sv,
	https=https,
	http=http,
	lfs=lfs,
	send=send,
	respond=respond,
	hook=hook,
	bit=bit,
	sql=sql,
	bc=bc,
	json=json,
	lanes=lanes,
	sqlite=sqlite,
},{__index=_G,__newindex=_G})
plenv._G=plenv

do
	local loaded={}
	function reqplugin(fn)
		if not loaded[fn] then
			setfenv(assert(loadfile("plugins/"..fn)),plenv)()
		end
		loaded[fn]=true
	end
	for fn in lfs.dir("plugins") do
		if fn:sub(-4,-1)==".lua" then
			reqplugin(fn)
		end
	end
end

hook.queue("init")

send("WHOIS "..cnick)
sv:settimeout(0)
hook.newsocket(sv)
while true do
	local s,e=sv:receive()
	if s then
		hook.queue("raw",s)
	else
		if e=="closed" then
			error(e)
		end
	end
	hook.queue("select",socket.select(hook.sel,hook.rsel,math.min(10,hook.interval or 10)))
end