local socket=require("socket")
local sv
local scl=socket.bind("*",1337)
local logfile=io.open("log.txt","a")
local function log(txt)
	txt="["..(math.floor(socket.gettime()-1394214999)).."] "..txt
	logfile:write(txt.."\n")
	logfile:flush()
	print(txt)
end
local function connect()
	sv=socket.connect("irc.esper.net",6667)
	while not sv do
		socket.sleep(5)
		sv=socket.connect("irc.esper.net",6667)
	end
	sv:send("NICK ^v\n")
	sv:send("USER pingbot ~ ~ :ping's bot\n")
	sv:settimeout(0)
	print("got server")
end
local function scheck(s)
	local s,e=s:receive(0)
	return e=="closed"
end
local cl=scl:accept()
cl:settimeout(0)
print("got client")
connect()
while true do
	if scheck(cl) then
		cl=scl:accept()
		cl:settimeout(0)
		print("got client")
	end
	if scheck(sv) then
		connect()
	end
	local s,e=cl:receive()
	if s then
		local txt=s:match("^PRIVMSG #oc :(.*)$")
		if txt then
			log("<^v> "..txt)
		end
		print("<"..s)
		sv:send(s.."\n")
	end
	local s,e=sv:receive()
	if s then
		local nick,txt=s:match("^:([^!]+)![^@]+@%S+ PRIVMSG #oc :(.*)$")
		if nick then
			local action=txt:match("^\1ACTION (.-)\1?$")
			if action then
				log("* "..nick.." "..action)
			else
				log("<"..nick.."> "..txt)
			end
		end
		local nick,ident=s:match("^:([^!]+)!([^@]+@%S+) JOIN #oc$")
		if nick then
			log(nick.." ("..ident..") has joined")
		end
		local nick,reason=s:match("^:([^!]+)![^@]+@%S+ PART #oc :(.*)$")
		if nick then
			log(nick.." has left ("..reason..")")
		end
		local nick,reason=s:match("^:([^!]+)![^@]+@%S+ QUIT :(.*)$")
		if nick then
			log(nick.." has quit ("..reason..")")
		end
		local nick,tonick=s:match("^:([^!]+)![^@]+@%S+ NICK :(.*)$")
		if nick then
			log(nick.." is now known as "..tonick)
		end
		print(">"..s)
		cl:send(s.."\n")
		local pong=s:match("^PING(.*)$")
		if pong then
			sv:send("PONG"..pong.."\n")
			print("<PONG"..pong)
		end
	end
	socket.select({sv,cl})
end