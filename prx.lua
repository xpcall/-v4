local svname="irc.esper.net"
local socket=require("socket")
local sv
local scl=socket.bind("*",1337)
local logfile={}
local function log(chan,txt)
	if chan then
		local fn="logs/"..chan..".txt"
		if not logfile[fn] then
			logfile[fn]=io.open(fn,"a")
		end
		logfile[fn]:write("["..(math.floor(socket.gettime()-1394214999)).."] "..txt.."\n")
		logfile[fn]:flush()
	else
		for k,v in pairs(logfile) do
			v:write("["..(math.floor(socket.gettime()-1394214999)).."] "..txt.."\n")
			v:flush()
		end
	end
end
local function connect()
	sv=socket.connect(svname,6667)
	while not sv do
		print("failed")
		socket.sleep(5)
		print("retrying")
		sv=socket.connect(svname,6667)
	end
	assert(sv:send("NICK ^v\n"))
	assert(sv:send("USER ping ~ ~ :ping's bot\n"))
	assert(sv:settimeout(0))
	print("got server")
end
local function scheck(s)
	local s,e=s:receive(0)
	return e and e~="timeout"
end
local cl=scl:accept()
cl:settimeout(0)
print("got client")
connect()
local svbuff=""
while true do
	if scheck(cl) then
		print("lost client")
		cl=scl:accept()
		cl:settimeout(0)
		print("got client")
	end
	if scheck(sv) then
		print("lost server")
		connect()
	end
	local s,e=cl:receive()
	if s then
		local chan,txt=s:match("^PRIVMSG (%S+) :(.*)$")
		if txt then
			log(chan,"<^v> "..txt)
		end
		print("<"..s)
		assert(sv:send(s.."\n"))
	end
	local s,e,r=sv:receive("*a")
	if e=="timeout" then
		svbuff=svbuff..r
		while svbuff:match("[\r\n]") do
			local s=svbuff:match("^[^\r\n]*")
			local nick,chan,txt=s:match("^:([^!]+)![^@]+@%S+ PRIVMSG (%S+) :(.*)$")
			if nick then
				local action=txt:match("^\1ACTION (.-)\1?$")
				if action then
					log(chan,"* "..nick.." "..action)
				else
					log(chan,"<"..nick.."> "..txt)
				end
			end
			local nick,ident,chan=s:match("^:([^!]+)!([^@]+@%S+) JOIN (%S+)$")
			if nick then
				log(chan,nick.." ("..ident..") has joined")
			end
			local nick,chan,reason=s:match("^:([^!]+)![^@]+@%S+ PART (%S+) ?:?(.*)$")
			if nick then
				log(chan,nick.." has left ("..reason..")")
			end
			local nick,reason=s:match("^:([^!]+)![^@]+@%S+ QUIT :(.*)$")
			if nick then
				log(nil,nick.." has quit ("..reason..")")
			end
			local nick,tonick=s:match("^:([^!]+)![^@]+@%S+ NICK :(.*)$")
			if nick then
				log(nil,nick.." is now known as "..tonick)
			end
			print(">"..s)
			cl:settimeout(5)
			cl:send(s.."\n")
			cl:settimeout(0)
			local pong=s:match("^PING (.+)$")
			if pong then
				assert(sv:send("PONG "..pong.."\n"))
				print("<PONG "..pong)
			end
			svbuff=svbuff:gsub("^[^\r\n]+[\r\n]+","")
		end
	end
	socket.select({sv,cl},nil,1)
end