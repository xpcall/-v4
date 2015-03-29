--[=[server.listen(1323,function(cl)
	irc.say("#ocbots","open "..cl.ip)
	local run=true
	--[[async.new(function()
		while run do
			cl.send("\255\248\13"..hook.queue("command_drama"))
			async.wait(5)
		end
	end)]]
	while true do
		local txt,err=cl.receive("*a")
		if err=="closed" then
			run=false
			break
		end
		irc.say("#ocbots",crypt.tohex(txt).." | "..serialize(txt))
	end
	irc.say("#ocbots","close "..cl.ip)
end)]=]