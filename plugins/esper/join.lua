hook.new("raw",function(txt)
	txt:gsub("^:"..cnick.." MODE "..cnick.." :%+i",function()
		send("CAP REQ account-notify")
		send("NS IDENTIFY "..file["pass/nspassword-"..network..".txt"]:match("%S+"))
		async.new(function()
			async.wait(1)
			send("JOIN #oc")
			send("JOIN #V")
			send("JOIN #ocgames")
			send("JOIN #OpenPrograms")
			send("JOIN #pixel")
		end)
	end)
end)
if crash then
	async.new(function()
		async.wait(1)
		send("PRIVMSG #V :crash "..(#crash>200 and paste(crash) or crash):gsub("[\r]\n\t*"," "))
	end)
end
hook.new("ban",function(nick,chan,user)
	for k,v in pairs(admin.find(user)) do
		if admin.perms[v].account=="ping" then
			send("MODE "..chan.." -b "..user)
			break
		end
	end
end)
hook.new("kick",function(chan,nick,fnick)
	if admin.perms[nick].account=="ping" then
		send("INVITE "..nick.." "..chan)
	end
end)