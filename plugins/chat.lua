tcpnet=socket.connect("71.238.153.166",25476)
if tcpnet then
	hook.newsocket(tcpnet)
	tcpnet:send('{"open",ports={IRC=true}}\n')
	local cchan="#ocbots"
	hook.new("select",function()
		local s=tcpnet:receive()
		if s then
			local dat=unserialize(s)
			if dat.port=="IRC" then
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
				port="IRC",
				data="\194\1677"..(act and ("* "..user.nick.." ") or ("<"..user.nick.."> ")).."\194\167f"..txt
			}).."\n")
		end
	end)
end