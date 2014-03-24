local sv=socket.bind("*",7666)
sv:settimeout(0)
hook.newsocket(sv)
local client
hook.new("select",function()
	if not client then
		client=sv:accept()
		if client then
			client:settimeout(0)
			hook.newsocket(sv)
		end
	end
	if client then
		local s,n=client:receive(0)
		if not s and n=="closed" then
			hook.remsocket(client)
			client=nil
		end
	end
end)
hook.new("msg",function(user,chan,txt)
	if client and chan=="#oc" then
		client:send("<"..user.nick.."> "..txt.."\n")
	end
end)