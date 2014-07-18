hook.new("join",function(user,chan)
	if chan=="#ocbots" and (user=="GlitchBot" or user=="ThouBot") then
		send("MODE #ocbots +o "..user)
	end
end)

--[==[hook.new("op",function(user,chan,suser)
	if suser=="EpicnessTwo" then
		send("MODE "..chan.." -o EpicnessTwo")
	end
end)

hook.new("nick",function(onick,cnick)
	cnick=cnick:lower()
	if (admin.perms[cnick] or {}).account~="ping" and (cnick=="ping" or cnick=="pong" or cnick=="v^" or cnick=="version") then
		send("PRIVMSG NickServ :ghost "..cnick)
	end
end)

	hook.new("msg",function(user,chan,txt,act)
	if chan=="#ocbots" and txt:match(":%-?[%)%>3%]]") then
		respond(user,(act and "* "..user.nick.." " or "<"..user.nick.."> ")..txt:gsub(":%-?[%)%>3%]]","in bed"))
	end
end)]==]

