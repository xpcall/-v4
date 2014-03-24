local socket=require("socket")
local sv=socket.connect("localhost",1337)
local https=require("ssl.https")
local http=require("socket.http")
local lfs=require("lfs")
local bit=require("bit")
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
		(user.chan=="^v" and "NOTICE " or "PRIVMSG ")..
		(user.chan=="^v" and user.nick or user.chan)..
		" :"..txt
		:gsub("^[\r\n]+",""):gsub("[\r\n]+$",""):gsub("[\r\n]+"," | ")
		:gsub("[%z\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]","")
		:sub(1,446)
	)
end
dofile("hook.lua")
dofile("db.lua")

hook.new("raw",function(txt)
	txt:gsub("^:^v MODE ^v :%+i",function()
		send("JOIN #oc")
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
},{__index=_G})
plenv._G=plenv
hook.new("msg",function(user,chan,txt)
	txt=txt:gsub("%s+$","")
	if txt:sub(1,1)=="." then
		print(user.nick.." used "..txt)
		local cb=function(dat)
			if dat then
				print("responding with "..tostring(dat))
				respond(user,user.nick..", "..tostring(dat))
			end
		end
		hook.callback=cb
		hook.queue("command",user,chan,txt:sub(2))
		local cmd,param=txt:match("^%.(%S+) ?(.*)")
		if cmd then
			hook.callback=cb
			hook.queue("command_"..cmd,user,chan,param)
		end
	end
end)

for fn in lfs.dir("plugins") do
	if fn:sub(-4,-1)==".lua" then
		setfenv(assert(loadfile("plugins/"..fn)),plenv)()
	end
end

send("WHO #oc %hna")
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
	hook.queue("select",socket.select(hook.sel,nil,math.min(10,hook.interval or 10)))
end