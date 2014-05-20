--[[local tcpnet=socket.connect("71.238.153.166",25476)
if tcpnet then
	local file=io.open("tcpnetpassword.txt","r")
	local port=file:read("*a"):gsub("[\r\n]","")
	file:close()
	hook.newsocket(tcpnet)
	tcpnet:send('{"open",ports={["'..port..'"]=true}}\n')
	local cchan="#ocbots"
	hook.new("select",function()
		local s=tcpnet:receive()
		if s then
			local dat=unserialize(s)
			if dat.port==port then
				if dat.data:match("^%.join ") then
					cchan=dat.data:match("^%S+ (.+)")
				else
					send("PRIVMSG "..cchan.." :"..dat.data)
				end
			end
		end
	end)
	local special="\194\167"
	hook.new("msg",function(user,chan,txt,act)
		if chan==cchan then
			tcpnet:send(serialize({
				"send",
				port=port,
				data="\194\1677"..(act and ("* "..user.nick.." ") or ("<"..user.nick.."> ")).."\194\167f"..txt
			}).."\n")
		end
	end)
end]]
if tcpnet then
	local file=io.open("tcpnetpassword.txt","r")
	local pass=file:read("*a"):gsub("[\r\n]","")
	file:close()
	tcpnet.open(pass)
	hook.new("tcpnet_message",function(port,dat)
		if port==pass then
			if dat[4]:match("^/me ?%S*.-$") then
				irc.say("#ocbots",mc2irc("*"..dat[3]..dat[4]:match("^/me(.+)")))
			elseif dat[4]:match("^[^/]") then
				irc.say("#ocbots",mc2irc("<"..dat[3].."> "..dat[4]))
			end
		end
	end)
	hook.new("msg",function(user,chan,txt,act)
		if chan=="#ocbots" then
			tcpnet.send(pass,irc2mc("<"..user.nick.."> "..txt))
		end
	end)
end